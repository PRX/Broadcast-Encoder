//
//  TWLEncoder_private.h
//  Broadcast Encoder
//
//  Created by Christopher Kalafarski on 3/12/14.
//  Copyright (c) 2014 PRX. All rights reserved.
//

#import "TWLEncoder.h"

@class TWLEncoderConfiguration;

@interface TWLEncoder ()

@property (nonatomic, strong, readonly) TWLEncoderConfiguration *immutableConfiguration;

- (id)initWithConfiguration:(TWLEncoderConfiguration *)configuration;
- (id)initWithConfiguration:(TWLEncoderConfiguration *)configuration delegate:(id<TWLEncoderDelegate>)delegate operationQueue:(NSOperationQueue *)queue;

- (void)encodeTask:(TWLEncoderTask *)task;

- (void)didFinishEncodingTask:(TWLEncoderTask *)task toURL:(NSURL *)location;

@end
