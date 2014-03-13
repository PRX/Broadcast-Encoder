//
//  TWLEncoder.h
//  Broadcast Encoder
//
//  Created by Christopher Kalafarski on 3/12/14.
//  Copyright (c) 2014 PRX. All rights reserved.
//

@import Foundation;

extern NSString * const TWLEncoderErrorDomain;

NS_ENUM(NSInteger, TWLEncoderError) {
  TWLEncoderErrorUnknown = -1,
  TWLEncoderErrorCancelled = -999,
  TWLEncoderErrorUnsupportedAudio = -1000,
  TWLEncoderErrorBadConfiguration = -2000,
  TWLEncoderErrorCannotAllocateInputBuffer = -2001,
  TWLEncoderErrorCannotAllocateOutputBuffer = -2002,
  TWLEncoderErrorCannotOpenFile = -3000
};

@protocol TWLEncoderDelegate;

@class TWLEncoderTask;

@interface TWLEncoder : NSObject

+ (instancetype)sharedEncoder;
+ (instancetype)encoderWithOperationQueue:(NSOperationQueue *)queue;

- (id)initWithOperationQueue:(NSOperationQueue *)queue;

@property (nonatomic, strong) id<TWLEncoderDelegate> delegate;

- (TWLEncoderTask *)taskWithURL:(NSURL *)url;

@end

@protocol TWLEncoderDelegate <NSObject>

@required

- (void)encoder:(TWLEncoder *)encoder task:(TWLEncoderTask *)task didWriteFrames:(int64_t)framesWritten totalFramesWritten:(int64_t)totalFramesWritten;

//- (void)encoder:(TWLEncoder *)encoder task:(TWLEncoderTask *)task didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite;
- (void)encoder:(TWLEncoder *)encoder task:(TWLEncoderTask *)task didFinishEncodingToURL:(NSURL *)location;

@end
