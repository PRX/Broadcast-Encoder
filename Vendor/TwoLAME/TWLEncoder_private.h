//
//  TWLEncoder_private.h
//  Broadcast Encoder
//
//  Created by Christopher Kalafarski on 3/12/14.
//  Copyright (c) 2014 PRX. All rights reserved.
//

#import "TWLEncoder.h"
#import <twolame.h>
#include <sndfile.h>

@class TWLEncoderConfiguration;

@interface TWLEncoder ()

/* This copy of the configuration set during creation
 * is immutable in spirit only. Nothing that has access
 * to it should change its properties, even if it could
 */
@property (readonly, copy) TWLEncoderConfiguration *immutableConfiguration;

/* The encoder will not accept new tasks once it becomes invalid */
@property BOOL isInvalid;

/* Initializers */
- (id)initWithConfiguration:(TWLEncoderConfiguration *)configuration;
- (id)initWithConfiguration:(TWLEncoderConfiguration *)configuration delegate:(id<TWLEncoderDelegate>)delegate operationQueue:(NSOperationQueue *)queue;

- (twolame_options *)encoderOptionsWithSFInfo:(SF_INFO)sfinfo;

/* Operation Queueing */
- (void)encodeTask:(TWLEncoderTask *)task;

/* Delegate Notification */
- (void)didFinishEncodingTask:(TWLEncoderTask *)task toURL:(NSURL *)location;

@end
