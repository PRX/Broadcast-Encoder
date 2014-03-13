//
//  TWLEncoder_private.h
//  Broadcast Encoder
//
//  Created by Christopher Kalafarski on 3/12/14.
//  Copyright (c) 2014 PRX. All rights reserved.
//

#import "TWLEncoder.h"

@interface TWLEncoder ()

@property (nonatomic, strong, readonly) NSOperationQueue *operationQueue;

- (void)encodeTask:(TWLEncoderTask *)task;

- (void)didFinishEncodingTask:(TWLEncoderTask *)task toURL:(NSURL *)location;

@end
