//
//  TWLEncoderTask.m
//  Broadcast Encoder
//
//  Created by Christopher Kalafarski on 3/12/14.
//  Copyright (c) 2014 PRX. All rights reserved.
//

#import "TWLEncoder.h"
#import "TWLEncoder_private.h"
#import "TWLEncoderTask_private.h"

@implementation TWLEncoderTask

@synthesize encoder = _encoder;
@synthesize URL = _URL;

- (id)initWithURL:(NSURL *)url encoder:(TWLEncoder *)encoder {
  self = [super init];
  if (self) {
#warning should make sure both args exist
    _URL = url;
    _encoder = encoder;
  }
  return self;
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

- (void)didCompleteWithError:(NSError *)error {
  if ([self.delegate respondsToSelector:@selector(encoder:task:didCompleteWithError:)]) {
    [self.delegate encoder:self.encoder task:self didCompleteWithError:error];
  }
}

@end
