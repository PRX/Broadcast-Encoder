//
//  TWLEncoderTask.m
//  Broadcast Encoder
//
//  Created by Christopher Kalafarski on 3/12/14.
//  Copyright (c) 2014 PRX. All rights reserved.
//

#import "TWLEncoder_private.h"
#import "TWLEncoderTask_private.h"

@implementation TWLEncoderTask

@synthesize encoder = _encoder;
@synthesize URL = _URL;
@synthesize delegate = _delegate;
@synthesize taskIdentifier = _taskIdentifier;

- (id)initWithURL:(NSURL *)url encoder:(TWLEncoder *)encoder delegate:(id<TWLEncoderTaskDelegate>)delegate {
  self = [super init];
  if (self) {
#warning should make sure both args exist
    _URL = url;
    _encoder = encoder;
    _delegate = delegate;
  }
  return self;
}

- (NSUInteger)taskIdentifier {
  if (!_taskIdentifier) {
    _taskIdentifier = arc4random_uniform(999999);
  }
  return _taskIdentifier;
}

- (NSURL *)originalURL {
  return self.URL;
}

- (const char *)path {
  return self.URL.path.UTF8String;
}

- (void)resume {
  [self.encoder encodeTask:self];
}

- (void)cancel {
#warning todo
}

#pragma mark - Delegate Notification

- (void)didCompleteWithError:(NSError *)error {
  if ([self.delegate respondsToSelector:@selector(encoder:task:didCompleteWithError:)]) {
    [self.delegate encoder:self.encoder task:self didCompleteWithError:error];
  }
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
  TWLEncoderTask *copy = TWLEncoderTask.new;
  
#warning todo
  return copy;
}

@end
