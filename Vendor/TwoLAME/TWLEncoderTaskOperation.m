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
#import "TWLEncoderTask_private.h"
#import "TWLEncoder_private.h"
#import <twolame.h>
#import "TWLAudioIn.h"

@interface TWLEncoderTaskOperation () {
  SF_INFO sndfileInfo;
  int sampleSize;
  int useRaw;
  
  short int *inputPCMBuffer;
  unsigned char *outputMP2Buffer;
  
  twolame_options *encoderOptions;
  
  audioin_t *inputAudioFile;
  FILE *outputAudioFile;
  
  unsigned int frameLength;
  unsigned int totalFrames;
  unsigned int frameCount;
  
//  twolame_options *encodeOptions;
//  
//  short int *pcmaudio;
//  unsigned char *mp2buffer;
//  
//  wave_info_t *wave_info;
//  
//  FILE *outfile;
//  
//  int num_samples;
//  int mp2fill_size;
//  int frames;
  
  BOOL _executing;
  BOOL _finished;
}

@property (nonatomic, strong) TWLEncoderTask *task;

- (void)didGetCanceled;

- (void)didStartExecuting;
- (void)didStopExecuting;
- (void)didFinish;

- (void)didFailWithError:(NSError *)error;

- (void)encodeToURL:(NSURL *)location;

@end

@implementation TWLEncoderTaskOperation

+ (instancetype)operationWithTask:(TWLEncoderTask *)task {
  return [[TWLEncoderTaskOperation alloc] initWithTask:task];
}

- (id)initWithTask:(TWLEncoderTask *)task {
  self = [super init];
  if (self) {
    self.task = task;
    
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

#pragma mark - Encoding

- (void)encodeToURL:(NSURL *)location {
  if (![self allocatePCMBuffer]) return;
  if (![self allocateMP2Buffer]) return;
  
  if (![self initializeEncoderOptions]) return;
  [self setOptionsFromConfiguration];
  
  [self openInputFile];
  
  twolame_set_num_channels(encoderOptions, sndfileInfo.channels);
  twolame_set_in_samplerate(encoderOptions, sndfileInfo.samplerate);
  
  if (![self openOutputFile:location]) return;
  
  if (![self initializeTwoLAME]) return;
  
  if (![self transcode:location]) return;
  
  if (![self checkForInputFileError]) return;
  if (![self flushRemainingAudio]) return;
  [self cleanup];
  
  [self didFinish];
  [self.task.encoder didFinishEncodingTask:self.task toURL:location];
}

- (BOOL)allocatePCMBuffer {
  if ((inputPCMBuffer = (short *) calloc(AUDIOBUFSIZE, sizeof(short))) == NULL) {
    
    NSError *error;
    NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: @"Encoding was unsuccessful.", NSLocalizedFailureReasonErrorKey: @"Could not allocate buffer.", NSLocalizedRecoverySuggestionErrorKey: @"You may be out of memory." };
    error = [NSError errorWithDomain:TWLEncoderErrorDomain code:TWLEncoderErrorCannotAllocateInputBuffer userInfo:userInfo];

    [self didFailWithError:error];
    
    return NO;
  }
  
  return YES;
}

- (BOOL)allocateMP2Buffer {
  if ((outputMP2Buffer = (unsigned char *) calloc(MP2BUFSIZE, sizeof(unsigned char))) == NULL) {
    
    NSError *error;
    NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: @"Encoding was unsuccessful.", NSLocalizedFailureReasonErrorKey: @"Could not allocate buffer.", NSLocalizedRecoverySuggestionErrorKey: @"You may be out of memory." };
    error = [NSError errorWithDomain:TWLEncoderErrorDomain code:TWLEncoderErrorCannotAllocateOutputBuffer userInfo:userInfo];

    [self didFailWithError:error];
    
    return NO;
  }
  
  return YES;
}

- (BOOL)initializeEncoderOptions {
  encoderOptions = twolame_init();
  
  if (encoderOptions == NULL) {
    
    NSError *error;
    NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: @"Encoding was unsuccessful.", NSLocalizedFailureReasonErrorKey: @"Could not initialize encoder.", NSLocalizedRecoverySuggestionErrorKey: @"This is an internal error." };
    error = [NSError errorWithDomain:TWLEncoderErrorDomain code:TWLEncoderErrorCannotInitialize userInfo:userInfo];
    
    [self didFailWithError:error];
    
    return NO;
  }
  
  return YES;
}

- (void)setOptionsFromConfiguration {
#warning todo
}

- (void)openInputFile {
  char *inputFileName = self.task.URL.path.UTF8String;
  
  if (useRaw) {
    // use raw input handler
    inputAudioFile = open_audioin_raw(inputFileName, &sndfileInfo, sampleSize);
  } else {
    // use libsndfile
    inputAudioFile = open_audioin_sndfile(inputFileName, &sndfileInfo);
  }
}

- (BOOL)openOutputFile:(NSURL *)location {
  char *outputFileName = location.path.UTF8String;
  
  FILE *file = NULL;
  file = fopen(outputFileName, "wb");
  
  if (file == NULL) {
    
    NSError *error;
    NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: @"Encoding was unsuccessful.", NSLocalizedFailureReasonErrorKey: @"Could not open output file.", NSLocalizedRecoverySuggestionErrorKey: @"This may be a app sandboxing issue." };
    error = [NSError errorWithDomain:TWLEncoderErrorDomain code:TWLEncoderErrorCannotOpenFile userInfo:userInfo];
    
    [self didFailWithError:error];
    
    return NO;
  }
  
  outputAudioFile = file;
  
  return YES;
}

- (BOOL)initializeTwoLAME {
  if (twolame_init_params(encoderOptions) != 0) {
    
    NSError *error;
    NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: @"Encoding was unsuccessful.", NSLocalizedFailureReasonErrorKey: @"Could not initialize encoder.", NSLocalizedRecoverySuggestionErrorKey: @"Configuring TwoLAME with these options failed." };
    error = [NSError errorWithDomain:TWLEncoderErrorDomain code:TWLEncoderErrorCannotInitialize userInfo:userInfo];
    
    [self didFailWithError:error];
    
    return NO;
  }
  
  return YES;
}

- (BOOL)transcode:(NSURL *)location {
  frameLength = twolame_get_framelength(encoderOptions);
  
  if (sndfileInfo.frames) {
    totalFrames = sndfileInfo.frames / TWOLAME_SAMPLES_PER_FRAME;
  }
  
  int samples_read = 0;
  int audioReadSize = 0;
  int byteswap = FALSE;
  int mp2fill_size = 0;
  unsigned int total_bytes = 0;
  
  while ((samples_read = inputAudioFile->read(inputAudioFile, inputPCMBuffer, audioReadSize)) > 0) {
    int bytes_out = 0;
    
    // Force byte swapping if requested
    if (byteswap) {
      int i;
      for (i = 0; i < samples_read; i++) {
        short tmp = inputPCMBuffer[i];
        char *src = (char *) &tmp;
        char *dst = (char *) &inputPCMBuffer[i];
        dst[0] = src[1];
        dst[1] = src[0];
      }
    }
    
    // Calculate the number of samples we have (per channel)
    samples_read /= sndfileInfo.channels;
    
    // Do swapping of left and right channels if requested
//    if (channelswap && sndfileInfo.channels == 2) {
//      int i;
//      for (i = 0; i < samples_read; i++) {
//        short tmp = inputPCMBuffer[(2 * i)];
//        inputPCMBuffer[(2 * i)] = inputPCMBuffer[(2 * i) + 1];
//        inputPCMBuffer[(2 * i) + 1] = tmp;
//      }
//    }
    
    // Encode the audio to MP2
    mp2fill_size =
    twolame_encode_buffer_interleaved(encoderOptions, inputPCMBuffer, samples_read, outputMP2Buffer,
                                      MP2_BUF_SIZE);
    
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
    bytes_out = fwrite(outputMP2Buffer, sizeof(unsigned char), mp2fill_size, outputAudioFile);
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
    frameCount += (mp2fill_size / frameLength);
    if (twolame_get_verbosity(encoderOptions) > 0) {
      fprintf(stderr, "\rEncoding frame: %i", frameCount);
      if (totalFrames) {
        fprintf(stderr, "/%i (%i%%)", totalFrames, (frameCount * 100) / totalFrames);
      }
      fflush(stderr);
    }
  }
  
  return YES;
}

- (BOOL)checkForInputFileError {
  if (inputAudioFile->error_str(inputAudioFile)) {
    
    NSError *error;
    NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: @"Encoding was unsuccessful.", NSLocalizedFailureReasonErrorKey: @"Could not read input file.", NSLocalizedRecoverySuggestionErrorKey: @"Check permissions and file type." };
    error = [NSError errorWithDomain:TWLEncoderErrorDomain code:TWLEncoderErrorCannotReadFile userInfo:userInfo];
    
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
  inputAudioFile->close(inputAudioFile);
  fclose(outputAudioFile);
  
  // Close the libtwolame encoder
  twolame_close(&encoderOptions);
  
  // Free up memory
  free(inputPCMBuffer);
  free(outputMP2Buffer);
}

@end
