//
//  SOXResampler_private.h
//  Broadcast Encoder
//
//  Created by Christopher Kalafarski on 3/13/14.
//  Copyright (c) 2014 PRX. All rights reserved.
//

#import "SOXResampler.h"

@class SOXResamplerConfiguration;

@interface SOXResampler ()

@property (nonatomic, strong, readonly) NSOperationQueue *operationQueue;
@property (nonatomic, strong, readonly) SOXResamplerConfiguration *immutableConfiguration;

- (id)initWithConfiguration:(SOXResamplerConfiguration *)configuration;
- (id)initWithConfiguration:(SOXResamplerConfiguration *)configuration delegate:(id<SOXResamplerDelegate>)delegate operationQueue:(NSOperationQueue *)queue;

- (void)resampleTask:(SOXResamplerTask *)task;

- (void)didFinishResamplingTask:(SOXResamplerTask *)task toURL:(NSURL *)location;

@end
