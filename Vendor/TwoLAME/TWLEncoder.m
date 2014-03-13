//
//  TWLEncoder.m
//  Broadcast Encoder
//
//  Created by Christopher Kalafarski on 3/12/14.
//  Copyright (c) 2014 PRX. All rights reserved.
//


#import "TWLEncoder_private.h"
#import "TWLEncoderTask_private.h"
#import "TWLEncoderTaskOperation.h"

NSString * const TWLEncoderErrorDomain = @"TWLEncoderErrorDomain";

@implementation TWLEncoder

@synthesize operationQueue = _operationQueue;

+ (instancetype)sharedEncoder {
  static dispatch_once_t pred;
  static id instance = nil;
  
  dispatch_once(&pred, ^{
    if (!instance) {
      instance = self.new;
    }
  });
  
  return instance;
}

+ (instancetype)encoderWithOperationQueue:(NSOperationQueue *)queue {
  return [[TWLEncoder alloc] initWithOperationQueue:queue];
}

- (id)initWithOperationQueue:(NSOperationQueue *)queue {
  self = [super init];
  if (self) {
    _operationQueue = queue;
  }
  return self;
}

- (NSOperationQueue *)operationQueue {
  if (!_operationQueue) {
    _operationQueue = [[NSOperationQueue alloc] init];
    _operationQueue.name = @"TWLEncoderDefaultOperationQueue";
  }
  
  return _operationQueue;
}

- (TWLEncoderTask *)taskWithURL:(NSURL *)url {
  TWLEncoderTask *task = [[TWLEncoderTask alloc] initWithURL:url encoder:self];
  return task;
}

- (void)encodeTask:(TWLEncoderTask *)task {
  TWLEncoderTaskOperation *operation;
  operation = [TWLEncoderTaskOperation operationWithTask:task];
  
  [self.operationQueue addOperation:operation];
}

- (void)didFinishEncodingTask:(TWLEncoderTask *)task toURL:(NSURL *)location {
  [self.delegate encoder:self task:task didFinishEncodingToURL:location];
#warning clean up temp file once delegate returns
}

@end
