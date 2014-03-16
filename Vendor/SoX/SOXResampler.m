//
//  SOXResampler.m
//  Broadcast Encoder
//
//  Created by Christopher Kalafarski on 3/13/14.
//  Copyright (c) 2014 PRX. All rights reserved.
//

#import "SOXResampler_private.h"
#import "SOXResamplerConfiguration.h"
#import "SOXResamplerTask_private.h"
#import "SOXResamplerTaskOperation.h"
#import "sox.h"

NSString * const SOXResamplerErrorDomain = @"SOXResamplerErrorDomain";

@implementation SOXResampler

@synthesize operationQueue = _operationQueue;

+ (void)load {
  [super load];
  
  assert(sox_init() == SOX_SUCCESS);
#warning Idk where this should happen
//  sox_quit();
}

+ (instancetype)sharedResampler {
  static dispatch_once_t pred;
  static id instance = nil;
  
  dispatch_once(&pred, ^{
    if (!instance) {
      instance = self.new;
    }
  });
  
  return instance;
}

+ (instancetype)resamplerWithConfiguration:(SOXResamplerConfiguration *)configuration {
  return [self resamplerWithConfiguration:configuration delegate:nil operationQueue:nil];
}

+ (instancetype)resamplerWithConfiguration:(SOXResamplerConfiguration *)configuration delegate:(id<SOXResamplerDelegate>)delegate operationQueue:(NSOperationQueue *)queue {
  return [[self alloc] initWithConfiguration:configuration delegate:delegate operationQueue:queue];
}

- (id)initWithConfiguration:(SOXResamplerConfiguration *)configuration {
  return [self initWithConfiguration:configuration delegate:nil operationQueue:nil];
}

- (id)initWithConfiguration:(SOXResamplerConfiguration *)configuration delegate:(id<SOXResamplerDelegate>)delegate operationQueue:(NSOperationQueue *)queue {
  self = [super init];
  if (self) {
    _configuration = configuration;
    _immutableConfiguration = configuration.copy;
    _operationQueue = queue;
    _delegate = delegate;
  }
  return self;
}

- (NSOperationQueue *)operationQueue {
  if (!_operationQueue) {
    _operationQueue = [[NSOperationQueue alloc] init];
    _operationQueue.name = @"SOXResamplerDefaultOperationQueue";
  }
  
  return _operationQueue;
}

- (SOXResamplerTask *)taskWithURL:(NSURL *)url {
  SOXResamplerTask *task = [[SOXResamplerTask alloc] initWithURL:url resampler:self];
  return task;
}

- (void)resampleTask:(SOXResamplerTask *)task {
  SOXResamplerTaskOperation *operation;
  operation = [SOXResamplerTaskOperation operationWithTask:task];
  
  [self.operationQueue addOperation:operation];
}

- (void)didFinishResamplingTask:(SOXResamplerTask *)task toURL:(NSURL *)location {
  [self.delegate resampler:self task:task didFinishResamplingToURL:location];
#warning clean up temp file once delegate returns
}

@end
