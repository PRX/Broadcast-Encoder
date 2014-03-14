//
//  TWLEncoderTaskOperation.m
//  Broadcast Encoder
//
//  Created by Christopher Kalafarski on 3/12/14.
//  Copyright (c) 2014 PRX. All rights reserved.
//

#warning make these configs?
#define MP2BUFSIZE		(16384)
#define AUDIOBUFSIZE	(9216)

#import "TWLEncoderTaskOperation.h"
#import "TWLEncoderError.h"
#import "TWLEncoderTask_private.h"
#import "TWLEncoder_private.h"
#import "TWLEncoderConfiguration.h"
#import <twolame.h>
#import "TWLAudioIn.h"

@interface TWLEncoderTaskOperation () {
  
  int sampleSize;
  
  BOOL _executing;
  BOOL _finished;
}

@property (nonatomic, strong) TWLEncoderTask *task;

@property (nonatomic) SF_INFO sndfileInfo;

@property (nonatomic) audioin_t *inputPCMAudio;
@property (nonatomic) short int *inputBuffer;

@property (nonatomic) FILE *outputMP2File;
@property (nonatomic) unsigned char *outputBuffer;

@property (readonly) twolame_options *encoderOptions;

- (void)didGetCanceled;

- (void)didStartExecuting;
- (void)didStopExecuting;
- (void)didFinish;

- (void)didFailWithError:(NSError *)error;

- (void)encodeToURL:(NSURL *)location;

@end

@implementation TWLEncoderTaskOperation

@synthesize encoderOptions = _encoderOptions;

+ (instancetype)operationWithTask:(TWLEncoderTask *)task {
  return [[self alloc] initWithTask:task];
}

- (id)initWithTask:(TWLEncoderTask *)task {
  self = [super init];
  if (self) {
    self.task = task;
    
#warning TODO goes somewhere else
    sampleSize = 16;
  }
  return self;
}

#pragma mark - Concurrent NSOperation

- (void)start {
  [self didStartExecuting];
  
  if (self.isCancelled) {
    [self didGetCanceled];
    return;
  }
  
  NSString *GID = [[NSProcessInfo processInfo] globallyUniqueString];
  NSString *inputFileName = self.task.URL.path.pathComponents.lastObject;
  NSString *outputFileName = [NSString stringWithFormat:@"%@_%@", GID, inputFileName];

  NSURL *outputFileURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:outputFileName]];

  [self encodeToURL:outputFileURL];
}

- (BOOL)isConcurrent {
  return YES;
}

- (BOOL)isExecuting {
  return _executing;
}

- (BOOL)isFinished {
  return _finished;
}

#pragma mark - State

- (void)didGetCanceled {
  [self didFinish];
  
  NSError *error;
  NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: @"Encoding was unsuccessful.", NSLocalizedFailureReasonErrorKey: @"Operation was canceled.", NSLocalizedRecoverySuggestionErrorKey: @"The user cancled the encoding operation." };
  error = [NSError errorWithDomain:TWLEncoderErrorDomain code:TWLEncoderErrorCancelled userInfo:userInfo];
  
  [self.task didCompleteWithError:error];
}

- (void)didStartExecuting {
  if (_executing != YES) {
    [self willChangeValueForKey:@"isExecuting"];
    _executing = YES;
    [self didChangeValueForKey:@"isExecuting"];
  }
}

- (void)didStopExecuting {
  if (_executing != NO) {
    [self willChangeValueForKey:@"isExecuting"];
    _executing = NO;
    [self didChangeValueForKey:@"isExecuting"];
  }
}

- (void)didFinish {
  if (_finished != YES) {
    [self willChangeValueForKey:@"isFinished"];
    _finished = YES;
    [self didStopExecuting];
    [self didChangeValueForKey:@"isFinished"];
  }
}

- (void)didFailWithError:(NSError *)error {
  [self.task didCompleteWithError:error];
  [self didFinish];
}

#pragma mark - Encoder

- (twolame_options *)encoderOptions {
  if (_encoderOptions == NULL) {
    _encoderOptions = [self.task.encoder encoderOptionsWithSFInfo:self.sndfileInfo];
  }
  
  return _encoderOptions;
}

#pragma mark - Encoding

- (void)encodeToURL:(NSURL *)location {
  if (![self allocatePCMBuffer]) return;
  if (![self allocateMP2Buffer]) return;
  
  [self openInputFile];
  
  if (![self openOutputFile:location]) return;
  
  if (![self transcode:location]) return;
  
  if (![self checkForInputFileError]) return;
  if (![self flushRemainingAudio]) return;
  [self cleanup];
  
  [self didFinish];
  [self.task.encoder didFinishEncodingTask:self.task toURL:location];
}

- (BOOL)allocatePCMBuffer {
  if ((self.inputBuffer = (short *) calloc(AUDIOBUFSIZE, sizeof(short))) == NULL) {
    NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: @"Encoding was unsuccessful.",
                                NSLocalizedFailureReasonErrorKey: @"Could not allocate buffer.",
                                NSLocalizedRecoverySuggestionErrorKey: @"You may be out of memory." };
    
    NSError *error = [NSError errorWithDomain:TWLEncoderErrorDomain
                                         code:TWLEncoderErrorCannotAllocateInputBuffer
                                     userInfo:userInfo];

    [self didFailWithError:error];
    
    return NO;
  }
  
  return YES;
}

- (BOOL)allocateMP2Buffer {
  if ((self.outputBuffer = (unsigned char *) calloc(MP2BUFSIZE, sizeof(unsigned char))) == NULL) {
    NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: @"Encoding was unsuccessful.",
                                NSLocalizedFailureReasonErrorKey: @"Could not allocate buffer.",
                                NSLocalizedRecoverySuggestionErrorKey: @"You may be out of memory." };
    
    NSError *error = [NSError errorWithDomain:TWLEncoderErrorDomain
                                         code:TWLEncoderErrorCannotAllocateOutputBuffer
                                     userInfo:userInfo];

    [self didFailWithError:error];
    
    return NO;
  }
  
  return YES;
}

- (void)openInputFile {
  char *inputFileName = self.task.URL.path.UTF8String;
  
  if (self.task.encoder.immutableConfiguration.raw) {
    self.inputPCMAudio = open_audioin_raw(inputFileName, &_sndfileInfo, sampleSize);
  } else {
    self.inputPCMAudio = open_audioin_sndfile(inputFileName, &_sndfileInfo);
  }
}

- (BOOL)openOutputFile:(NSURL *)location {
  char *outputFileName = location.path.UTF8String;
  
  FILE *file = NULL;
  file = fopen(outputFileName, "wb");
  
  if (file == NULL) {
    NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: @"Encoding was unsuccessful.",
                                NSLocalizedFailureReasonErrorKey: @"Could not open output file.",
                                NSLocalizedRecoverySuggestionErrorKey: @"This may be a app sandboxing issue." };
    
    NSError *error = [NSError errorWithDomain:TWLEncoderErrorDomain
                                         code:TWLEncoderErrorCannotOpenFile
                                     userInfo:userInfo];
    
    [self didFailWithError:error];
    
    return NO;
  }
  
  self.outputMP2File = file;
  
  return YES;
}

- (BOOL)transcode:(NSURL *)location {
  if (self.encoderOptions == NULL) {
    return NO;
  }
  
  unsigned int frameLength = twolame_get_framelength(self.encoderOptions);
  
  unsigned int totalFrames = 0;
  unsigned int frameCount = 0;
  int samples_read = 0;
  int audioReadSize = 0;
  int mp2fill_size = 0;
  unsigned int total_bytes = 0;
  
  if (self.sndfileInfo.frames) {
    totalFrames = (self.sndfileInfo.frames / TWOLAME_SAMPLES_PER_FRAME);
  }
  
//  if (single_frame_mode)
//    audioReadSize = TWOLAME_SAMPLES_PER_FRAME;
//  else
  audioReadSize = AUDIO_BUF_SIZE;
  
  while ((samples_read = self.inputPCMAudio->read(self.inputPCMAudio, self.inputBuffer, audioReadSize)) > 0) {
    int bytes_out = 0;
    
    // Force byte swapping if requested
    BOOL byteswap = self.task.encoder.configuration.byteSwap;
    if (byteswap) {
      int i;
      for (i = 0; i < samples_read; i++) {
        short tmp = self.inputBuffer[i];
        char *src = (char *) &tmp;
        char *dst = (char *) &_inputBuffer[i];
        dst[0] = src[1];
        dst[1] = src[0];
      }
    }
    
    // Calculate the number of samples we have (per channel)
    samples_read /= self.sndfileInfo.channels;
    
    // Do swapping of left and right channels if requested
    BOOL channelSwap = self.task.encoder.configuration.channelSwap;
    if (channelSwap && self.sndfileInfo.channels == 2) {
      int i;
      for (i = 0; i < samples_read; i++) {
        short tmp = self.inputBuffer[(2 * i)];
        self.inputBuffer[(2 * i)] = self.inputBuffer[(2 * i) + 1];
        self.inputBuffer[(2 * i) + 1] = tmp;
      }
    }
    
    // Encode the audio to MP2
    mp2fill_size = twolame_encode_buffer_interleaved(self.encoderOptions, self.inputBuffer, samples_read, self.outputBuffer, MP2_BUF_SIZE);
    
    // Stop if we don't have any bytes (probably don't have enough audio for a full frame of
    // mpeg audio)
    if (mp2fill_size == 0)
      break;
    if (mp2fill_size < 0) {
      fprintf(stderr, "error while encoding audio: %d\n", mp2fill_size);
      exit(ERR_ENCODING);
    }
    // Check that a whole number of frame was written
    // if (mp2fill_size % frame_len != 0) {
    // fprintf(stderr,"error while encoding audio: non-whole number of frames written\n");
    // exit(ERR_ENCODING);
    // }
    
    // Write the encoded audio out
    bytes_out = fwrite(self.outputBuffer, sizeof(unsigned char), mp2fill_size, self.outputMP2File);
    if (bytes_out != mp2fill_size) {
      perror("error while writing to output file");
      exit(ERR_WRITING_OUTPUT);
    }
    total_bytes += bytes_out;
    
    // Only single frame ?
//    if (single_frame_mode)
//      break;
//    
    
    // Display Progress
    unsigned int frames_out = (mp2fill_size / frameLength);
    frameCount += frames_out;
    
    [self.task.encoder.delegate encoder:self.task.encoder task:self.task didWriteFrames:frames_out totalFramesWritten:frameCount totalFrameExpectedToWrite:totalFrames bytesWritten:bytes_out totalBytesWritten:total_bytes];
  }
  
  return YES;
}

- (BOOL)checkForInputFileError {
  if (self.inputPCMAudio->error_str(self.inputPCMAudio)) {
    NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: @"Encoding was unsuccessful.",
                                NSLocalizedFailureReasonErrorKey: @"Could not read input file.",
                                NSLocalizedRecoverySuggestionErrorKey: @"Check permissions and file type." };
    
    NSError *error = [NSError errorWithDomain:TWLEncoderErrorDomain
                                         code:TWLEncoderErrorCannotReadFile
                                     userInfo:userInfo];
    
    [self didFailWithError:error];
    
    return NO;
  }
  
  return YES;
}

- (BOOL)flushRemainingAudio {
  
//  mp2fill_size = twolame_encode_flush(encopts, mp2buffer, MP2_BUF_SIZE);
//  if (mp2fill_size > 0) {
//    int bytes_out = fwrite(mp2buffer, sizeof(unsigned char), mp2fill_size, outputfile);
//    frame_count++;
//    if (bytes_out <= 0) {
//      perror("error while writing to output file");
//      exit(ERR_WRITING_OUTPUT);
//    }
//    total_bytes += bytes_out;
//  }
  
  return YES;
}

- (void)cleanup {
  self.inputPCMAudio->close(self.inputPCMAudio);
  fclose(self.outputMP2File);
  
  // Close the libtwolame encoder
  twolame_close(&_encoderOptions);
  
  // Free up memory
  free(self.inputBuffer);
  free(self.outputBuffer);
}

@end
