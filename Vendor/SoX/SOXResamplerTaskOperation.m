//
//  SOXResamplerTaskOperation.m
//  Broadcast Encoder
//
//  Created by Christopher Kalafarski on 3/13/14.
//  Copyright (c) 2014 PRX. All rights reserved.
//

#import "SOXResamplerTaskOperation.h"
#import "SOXResamplerTask_private.h"
#import "SOXResampler.h"
#import "sox.h"

@interface SOXResamplerTaskOperation () {
  BOOL _executing;
  BOOL _finished;
}

@property (nonatomic, strong) SOXResamplerTask *task;

- (void)didGetCanceled;

- (void)didStartExecuting;
- (void)didStopExecuting;
- (void)didFinish;

- (void)didFailWithError:(NSError *)error;

- (void)resampleToURL:(NSURL *)location;

@end

@implementation SOXResamplerTaskOperation

+ (instancetype)operationWithTask:(SOXResamplerTask *)task {
  return [[self alloc] initWithTask:task];
}

- (id)initWithTask:(SOXResamplerTask *)task {
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
  
  [self resampleToURL:outputFileURL];
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
  NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: @"Resampling was unsuccessful.", NSLocalizedFailureReasonErrorKey: @"Operation was canceled.", NSLocalizedRecoverySuggestionErrorKey: @"The user cancled the encoding operation." };
  error = [NSError errorWithDomain:SOXResamplerErrorDomain code:SOXResamplerErrorCancelled userInfo:userInfo];
  
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

#pragma mark - Resampling

- (void)resampleToURL:(NSURL *)location {
  
}

@end
