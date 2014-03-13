//
//  TWLEncoderTask.h
//  Broadcast Encoder
//
//  Created by Christopher Kalafarski on 3/12/14.
//  Copyright (c) 2014 PRX. All rights reserved.
//

@import Foundation;

@protocol TWLEncoderTaskDelegate;

@class TWLEncoder;

@interface TWLEncoderTask : NSObject

@property (nonatomic, strong) id<TWLEncoderTaskDelegate> delegate;
@property (nonatomic, strong, readonly) NSURL *originalURL;

@property (nonatomic, readonly) int64_t countOfBytesEncoded;

- (void)resume;

@end

@protocol TWLEncoderTaskDelegate <NSObject>

@optional

- (void)encoder:(TWLEncoder *)encoder task:(TWLEncoderTask *)task didCompleteWithError:(NSError *)error;

@end