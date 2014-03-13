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
#import "audio_wave.h"
#import "twolame.h"

@interface TWLEncoderTaskOperation () {
  twolame_options *encodeOptions;
  
  short int *pcmaudio;
  unsigned char *mp2buffer;
  
  wave_info_t *wave_info;
  
  FILE *outfile;
  
  int num_samples;
  int mp2fill_size;
  int frames;
  
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
  
  if ((pcmaudio = (short *) calloc(AUDIOBUFSIZE, sizeof(short))) == NULL) {
    NSError *error;
    NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: @"Encoding was unsuccessful.", NSLocalizedFailureReasonErrorKey: @"Could not allocate buffer.", NSLocalizedRecoverySuggestionErrorKey: @"You may be out of memory." };
    error = [NSError errorWithDomain:TWLEncoderErrorDomain code:TWLEncoderErrorCannotAllocateInputBuffer userInfo:userInfo];
    
    [self didFailWithError:error];
    return;
  }
  
  if ((mp2buffer = (unsigned char *) calloc(MP2BUFSIZE, sizeof(unsigned char))) == NULL) {
    NSError *error;
    NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: @"Encoding was unsuccessful.", NSLocalizedFailureReasonErrorKey: @"Could not allocate buffer.", NSLocalizedRecoverySuggestionErrorKey: @"You may be out of memory." };
    error = [NSError errorWithDomain:TWLEncoderErrorDomain code:TWLEncoderErrorCannotAllocateOutputBuffer userInfo:userInfo];
    
    [self didFailWithError:error];
    return;
  }
  
  encodeOptions = twolame_init();
  
  if ((wave_info = wave_init(self.task.path)) == NULL) {
    NSError *error;
    NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: @"Encoding was unsuccessful.", NSLocalizedFailureReasonErrorKey: @"The file was not a recognized format.", NSLocalizedRecoverySuggestionErrorKey: @"Are you sure it was a WAV of AIFF file?" };
    error = [NSError errorWithDomain:TWLEncoderErrorDomain code:TWLEncoderErrorUnsupportedAudio userInfo:userInfo];
    
    [self didFailWithError:error];
    return;
  }
  
  // Use sound file to over-ride preferences for
  // mono/stereo and sampling-frequency
  twolame_set_num_channels(encodeOptions, wave_info->channels);
  if (wave_info->channels == 1) {
    twolame_set_mode(encodeOptions, TWOLAME_MONO);
  } else {
    twolame_set_mode(encodeOptions, TWOLAME_STEREO);
  }
  
  /* Set the input and output sample rate to the same */
  twolame_set_in_samplerate(encodeOptions, wave_info->samplerate);
  twolame_set_out_samplerate(encodeOptions, wave_info->samplerate);
  
  /* Set the bitrate to 192 kbps */
  twolame_set_bitrate(encodeOptions, 192);
  
  /* initialise twolame with this set of options */
  if (twolame_init_params(encodeOptions) != 0) {
    NSError *error;
    NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: @"Encoding was unsuccessful.", NSLocalizedFailureReasonErrorKey: @"Configuring the encoder failed.", NSLocalizedRecoverySuggestionErrorKey: @"Double check the encoder options." };
    error = [NSError errorWithDomain:TWLEncoderErrorDomain code:TWLEncoderErrorBadConfiguration userInfo:userInfo];
    
    [self didFailWithError:error];
    return;
  }
  
  /* Open the output file for the encoded MP2 data */
  if ((outfile = fopen(location.path.UTF8String, "wb")) == 0) {
    NSError *error;
    NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: @"Encoding was unsuccessful.", NSLocalizedFailureReasonErrorKey: @"Could not open output file", NSLocalizedRecoverySuggestionErrorKey: @"This could be an issue with app sandboxing." };
    error = [NSError errorWithDomain:TWLEncoderErrorDomain code:TWLEncoderErrorCannotOpenFile userInfo:userInfo];
    
    [self didFailWithError:error];
    return;
  }
  
  // Read num_samples of audio data *per channel* from the input file
  while ((num_samples = wave_get_samples(wave_info, pcmaudio, AUDIOBUFSIZE)) != 0) {
    
#warning todo handle this
    if (self.isCancelled) {
      [self didGetCanceled];
    }
    
    // Encode the audio!
    mp2fill_size =
    twolame_encode_buffer_interleaved(encodeOptions, pcmaudio, num_samples, mp2buffer,
                                      MP2BUFSIZE);
    
    // Write the MPEG bitstream to the file
    fwrite(mp2buffer, sizeof(unsigned char), mp2fill_size, outfile);
    
    // Display the number of MPEG audio frames we have encoded
    frames += (num_samples / TWOLAME_SAMPLES_PER_FRAME);
    
    [self.task.encoder.delegate encoder:self.task.encoder task:self.task didWriteFrames:(num_samples / TWOLAME_SAMPLES_PER_FRAME) totalFramesWritten:frames];
    
    fflush(stdout);
  }
  
  /* flush any remaining audio. (don't send any new audio data) There should only ever be a max
   of 1 frame on a flush. There may be zero frames if the audio data was an exact multiple of
   1152 */
  mp2fill_size = twolame_encode_flush(encodeOptions, mp2buffer, MP2BUFSIZE);
  fwrite(mp2buffer, sizeof(unsigned char), mp2fill_size, outfile);
  
  
  twolame_close(&encodeOptions);
  free(pcmaudio);
  
  [self didFinish];
  [self.task.encoder didFinishEncodingTask:self.task toURL:location];
}

@end
