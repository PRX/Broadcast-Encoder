//
//  TWLEncoderTaskOperation.m
//  Broadcast Encoder
//
//  Created by Christopher Kalafarski on 3/12/14.
//  Copyright (c) 2014 PRX. All rights reserved.
//

#define MP2_BUF_SIZE		(16384)
#define AUDIO_BUF_SIZE		(9210)

#import "TWLEncoderTaskOperation.h"
#import "TWLEncoderError.h"
#import "TWLEncoderTask_private.h"
#import "TWLEncoder_private.h"
#import "TWLEncoderConfiguration.h"
#import <twolame.h>
#import "TWLPCMAudioFile.h"

@interface TWLEncoderTaskOperation () {
  BOOL _executing;
  BOOL _finished;
}

@property (nonatomic, strong) TWLEncoderTask *task;

@property (nonatomic) SF_INFO sndfileInfo;

@property (nonatomic) short int *inputBuffer;
@property (nonatomic) TWLPCMAudioFile *inputFile;

@property (nonatomic) FILE *outputFile;
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

- (instancetype)initWithTask:(TWLEncoderTask *)task {
  self = [super init];
  if (self) {
    self.task = task;
    
    [self didInit];
  }
  return self;
}

- (void)didInit {
  [self allocatePCMBuffer];
  [self allocateMP2Buffer];
}

- (void)allocatePCMBuffer {
  self.inputBuffer = (short *)calloc(AUDIO_BUF_SIZE, sizeof(short));
  
  if (self.inputBuffer == NULL) {
    NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: @"Encoding was unsuccessful.",
                                NSLocalizedFailureReasonErrorKey: @"Could not allocate buffer.",
                                NSLocalizedRecoverySuggestionErrorKey: @"You may be out of memory." };
    
    NSError *error = [NSError errorWithDomain:TWLEncoderErrorDomain
                                         code:TWLEncoderErrorCannotAllocateInputBuffer
                                     userInfo:userInfo];
    
    [self didFailWithError:error];
  }
}

- (void)allocateMP2Buffer {
  self.outputBuffer = (unsigned char *)calloc(MP2_BUF_SIZE, sizeof(unsigned char));
  
  if (self.outputBuffer == NULL) {
    NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: @"Encoding was unsuccessful.",
                                NSLocalizedFailureReasonErrorKey: @"Could not allocate buffer.",
                                NSLocalizedRecoverySuggestionErrorKey: @"You may be out of memory." };
    
    NSError *error = [NSError errorWithDomain:TWLEncoderErrorDomain
                                         code:TWLEncoderErrorCannotAllocateOutputBuffer
                                     userInfo:userInfo];
    
    [self didFailWithError:error];
  }
}

#pragma mark - Concurrent NSOperation

- (void)start {
  [self didStartExecuting];
  
  if (self.isCancelled) {
    [self didGetCanceled];
    return;
  }
  
  if (self.isFinished) {
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

/* didFailWithError: does the following things:
 *  - Reports to the parents taks that there was an error (this notifies the task delegate)
 *  - Marks the operation as `finished`
 *  - Marks the operation as no longer `executing`
 */
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
  if (self.isExecuting) {
    [self openInputFile];
    [self openOutputFile:location];
    
    [self transcode:location];
  }
  
//  if (![self checkForInputFileError]) return;
  [self flushRemainingAudio];
  [self cleanup];
  
  BOOL report = self.isExecuting;
  
  [self didFinish];
  
  if (report) {
    [self.task.encoder didFinishEncodingTask:self.task toURL:location];
  }
}

- (void)openInputFile {
  if (self.isExecuting) {
    BOOL raw = self.task.encoder.immutableConfiguration.raw;
    NSError *error;
    self.inputFile = [TWLPCMAudioFile fileWithFileURL:self.task.URL sndfileInfo:&_sndfileInfo raw:raw error:&error];
    
    if (error) {
      NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: @"Encoding was unsuccessful.",
                                  NSLocalizedFailureReasonErrorKey: @"Could not open input file.",
                                  NSLocalizedRecoverySuggestionErrorKey: @"Make sure the file is a support PCM format." };
      
      NSError *_error = [NSError errorWithDomain:TWLEncoderErrorDomain
                                           code:TWLEncoderErrorUnsupportedAudio
                                       userInfo:userInfo];
      
      [self didFailWithError:_error];
    }
  }
}

- (void)openOutputFile:(NSURL *)location {
  if (self.isExecuting) {
    self.outputFile = NULL;
    self.outputFile = fopen(location.fileSystemRepresentation, "wb");
    
    if (self.outputFile == NULL) {
      NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: @"Encoding was unsuccessful.",
                                  NSLocalizedFailureReasonErrorKey: @"Could not open output file.",
                                  NSLocalizedRecoverySuggestionErrorKey: @"This may be a app sandboxing issue." };
      
      NSError *error = [NSError errorWithDomain:TWLEncoderErrorDomain
                                            code:TWLEncoderErrorCannotOpenFile
                                        userInfo:userInfo];
      
      [self didFailWithError:error];
    }
  }
}

- (void)transcode:(NSURL *)location {
  if (self.isExecuting && self.encoderOptions != NULL) {
    
    unsigned int frameLength = twolame_get_framelength(self.encoderOptions);
    
    unsigned int totalFrames = 0;
    unsigned int frameCount = 0;
    int64_t samples_read = 0;
    int audioReadSize = 0;
    int mp2fill_size = 0;
    unsigned int total_bytes = 0;
    
    if (self.sndfileInfo.frames) {
      totalFrames = (self.sndfileInfo.frames / TWOLAME_SAMPLES_PER_FRAME);
    }
    
    audioReadSize = AUDIO_BUF_SIZE;

    
    while ((samples_read = [self.inputFile readBuffer:self.inputBuffer samples:audioReadSize]) > 0) {
      int64_t bytes_out = 0;
      
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
      mp2fill_size = twolame_encode_buffer_interleaved(self.encoderOptions, self.inputBuffer, (int)samples_read, self.outputBuffer, MP2_BUF_SIZE);

      // Stop if we don't have any bytes (probably don't have enough audio for a full frame of
      // mpeg audio)
      if (mp2fill_size == 0)
        break;
      if (mp2fill_size < 0) {
        
        NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: @"Encoding was unsuccessful.",
                                    NSLocalizedFailureReasonErrorKey: @"Error while encoding audio.",
                                    NSLocalizedRecoverySuggestionErrorKey: @"The input file may be corrupt." };
        
        NSError *error = [NSError errorWithDomain:TWLEncoderErrorDomain
                                             code:TWLEncoderErrorCannotEncodeAudio
                                         userInfo:userInfo];
        
        [self didFailWithError:error];
        return;
      }
      
      // Write the encoded audio out

      
      bytes_out = fwrite(self.outputBuffer, sizeof(unsigned char), mp2fill_size, self.outputFile);
      if (bytes_out != mp2fill_size) {
        NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: @"Encoding was unsuccessful.",
                                    NSLocalizedFailureReasonErrorKey: @"Error while writing encoded audio.",
                                    NSLocalizedRecoverySuggestionErrorKey: @"The input file may be corrupt." };
        
        NSError *error = [NSError errorWithDomain:TWLEncoderErrorDomain
                                             code:TWLEncoderErrorCannotWriteFile
                                         userInfo:userInfo];
        
        [self didFailWithError:error];
        return;
      }
      total_bytes += bytes_out;
      
      unsigned int frames_out = (mp2fill_size / frameLength);
      frameCount += frames_out;

      [self.task.encoder.delegate encoder:self.task.encoder task:self.task didWriteFrames:frames_out totalFramesWritten:frameCount totalFrameExpectedToWrite:totalFrames bytesWritten:bytes_out totalBytesWritten:total_bytes];
    }
  }
}

- (void)flushRemainingAudio {
  if (self.isExecuting) {
    int mp2fill_size = twolame_encode_flush(self.encoderOptions, self.outputBuffer, MP2_BUF_SIZE);
    if (mp2fill_size > 0) {
      int64_t bytes_out = fwrite(self.outputBuffer, sizeof(unsigned char), mp2fill_size, self.outputFile);
      //    frame_count++;
      if (bytes_out <= 0) {
        NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: @"Encoding was unsuccessful.",
                                    NSLocalizedFailureReasonErrorKey: @"Error while writing encoded audio.",
                                    NSLocalizedRecoverySuggestionErrorKey: @"The input file may be corrupt." };
        
        NSError *error = [NSError errorWithDomain:TWLEncoderErrorDomain
                                             code:TWLEncoderErrorCannotWriteFile
                                         userInfo:userInfo];
        
        [self didFailWithError:error];
        return;
      }
      //    total_bytes += bytes_out;
    }
  }
}

- (void)cleanup {
  [self.inputFile close];
  fclose(self.outputFile);
  
  // Close the libtwolame encoder
  twolame_close(&_encoderOptions);
  
  // Free up memory
  free(self.inputBuffer);
  free(self.outputBuffer);
}

@end
