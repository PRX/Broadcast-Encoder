//
//  TWLEncoderTask_private.h
//  Broadcast Encoder
//
//  Created by Christopher Kalafarski on 3/12/14.
//  Copyright (c) 2014 PRX. All rights reserved.
//

#import "TWLEncoderTask.h"

@class TWLEncoder;

@interface TWLEncoderTask ()

@property (nonatomic, strong, readonly) TWLEncoder *encoder;
@property (nonatomic, strong, readonly) NSURL *URL;

@property (nonatomic, readonly) const char *path;

/* Private Initializers */
- (id)initWithURL:(NSURL *)url encoder:(TWLEncoder *)encoder delegate:(id<TWLEncoderTaskDelegate>)delegate;

/* Delegate Notification */
- (void)didCompleteWithError:(NSError *)error;

@end
