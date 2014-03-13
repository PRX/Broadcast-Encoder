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
#import "TWLEncoderConfiguration.h"
#import <twolame.h>
#import "TWLAudioIn.h"

@interface TWLEncoderTaskOperation () {
  
  int sampleSize;
  int useRaw;
  
  BOOL _executing;
  BOOL _finished;
}

@property (nonatomic, strong) TWLEncoderTask *task;

@property (nonatomic) SF_INFO sndfileInfo;

@property (nonatomic) audioin_t *inputPCMAudio;
@property (nonatomic) short int *inputBuffer;

@property (nonatomic) FILE *outputMP2File;
@property (nonatomic) unsigned char *outputBuffer;

@property (nonatomic) twolame_options *encoderOptions;

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
  
  twolame_set_num_channels(self.encoderOptions, self.sndfileInfo.channels);
  twolame_set_in_samplerate(self.encoderOptions, self.sndfileInfo.samplerate);
  
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
  if ((self.inputBuffer = (short *) calloc(AUDIOBUFSIZE, sizeof(short))) == NULL) {
    
    NSError *error;
    NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: @"Encoding was unsuccessful.", NSLocalizedFailureReasonErrorKey: @"Could not allocate buffer.", NSLocalizedRecoverySuggestionErrorKey: @"You may be out of memory." };
    error = [NSError errorWithDomain:TWLEncoderErrorDomain code:TWLEncoderErrorCannotAllocateInputBuffer userInfo:userInfo];

    [self didFailWithError:error];
    
    return NO;
  }
  
  return YES;
}

- (BOOL)allocateMP2Buffer {
  if ((self.outputBuffer = (unsigned char *) calloc(MP2BUFSIZE, sizeof(unsigned char))) == NULL) {
    
    NSError *error;
    NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: @"Encoding was unsuccessful.", NSLocalizedFailureReasonErrorKey: @"Could not allocate buffer.", NSLocalizedRecoverySuggestionErrorKey: @"You may be out of memory." };
    error = [NSError errorWithDomain:TWLEncoderErrorDomain code:TWLEncoderErrorCannotAllocateOutputBuffer userInfo:userInfo];

    [self didFailWithError:error];
    
    return NO;
  }
  
  return YES;
}

- (BOOL)initializeEncoderOptions {
  self.encoderOptions = twolame_init();
  
  if (self.encoderOptions == NULL) {
    
    NSError *error;
    NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: @"Encoding was unsuccessful.", NSLocalizedFailureReasonErrorKey: @"Could not initialize encoder.", NSLocalizedRecoverySuggestionErrorKey: @"This is an internal error." };
    error = [NSError errorWithDomain:TWLEncoderErrorDomain code:TWLEncoderErrorCannotInitialize userInfo:userInfo];
    
    [self didFailWithError:error];
    
    return NO;
  }
  
  return YES;
}

- (void)setOptionsFromConfiguration {
  TWLEncoderConfiguration *config = self.task.encoder.configuration;
  
  twolame_set_copyright(self.encoderOptions, config.markAsCopyright);
  twolame_set_original(self.encoderOptions, config.markAsOriginal);
  twolame_set_error_protection(self.encoderOptions, config.protect);
  
  twolame_set_bitrate(self.encoderOptions, (int)(config.bitrate / 1024));
  
  switch (config.outputMode) {
    case TWLEncoderOutputModeAuto:
      twolame_set_mode(self.encoderOptions, TWOLAME_AUTO_MODE);
      break;
    case TWLEncoderOutputModeMono:
      twolame_set_mode(self.encoderOptions, TWOLAME_MONO);
      break;
    case TWLEncoderOutputModeStereo:
      twolame_set_mode(self.encoderOptions, TWOLAME_STEREO);
      break;
    case TWLEncoderOutputModeJointStereo:
      twolame_set_mode(self.encoderOptions, TWOLAME_JOINT_STEREO);
      break;
    case TWLEncoderOutputModeDualChannel:
      twolame_set_mode(self.encoderOptions, TWOLAME_DUAL_CHANNEL);
      break;
    default:
      break;
  }
  
  switch (config.deemphasis) {
    case TWLEncoderEmphasisNone:
      twolame_set_emphasis(self.encoderOptions, TWOLAME_EMPHASIS_N);
      break;
    case TWLEncoderEmphasisC:
      twolame_set_emphasis(self.encoderOptions, TWOLAME_EMPHASIS_C);
      break;
    case TWLEncoderEmphasis5:
      twolame_set_emphasis(self.encoderOptions, TWOLAME_EMPHASIS_5);
      break;
    default:
      break;
  }
}

- (void)openInputFile {
  char *inputFileName = self.task.URL.path.UTF8String;
  
  if (useRaw) {
    // use raw input handler
    self.inputPCMAudio = open_audioin_raw(inputFileName, &_sndfileInfo, sampleSize);
  } else {
    // use libsndfile
    self.inputPCMAudio = open_audioin_sndfile(inputFileName, &_sndfileInfo);
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
  
  self.outputMP2File = file;
  
  return YES;
}

- (BOOL)initializeTwoLAME {
  if (twolame_init_params(self.encoderOptions) != 0) {
    
    NSError *error;
    NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: @"Encoding was unsuccessful.", NSLocalizedFailureReasonErrorKey: @"Could not initialize encoder.", NSLocalizedRecoverySuggestionErrorKey: @"Configuring TwoLAME with these options failed." };
    error = [NSError errorWithDomain:TWLEncoderErrorDomain code:TWLEncoderErrorCannotInitialize userInfo:userInfo];
    
    [self didFailWithError:error];
    
    return NO;
  }
  
  return YES;
}

- (BOOL)transcode:(NSURL *)location {
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
    frameCount += (mp2fill_size / frameLength);
    if (twolame_get_verbosity(self.encoderOptions) > 0) {
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
  if (self.inputPCMAudio->error_str(self.inputPCMAudio)) {
    
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
  self.inputPCMAudio->close(self.inputPCMAudio);
  fclose(self.outputMP2File);
  
  // Close the libtwolame encoder
  twolame_close(&_encoderOptions);
  
  // Free up memory
  free(self.inputBuffer);
  free(self.outputBuffer);
}

@end
