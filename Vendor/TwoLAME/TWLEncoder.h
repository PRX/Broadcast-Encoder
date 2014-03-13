//
//  TWLEncoder.h
//  Broadcast Encoder
//
//  Created by Christopher Kalafarski on 3/12/14.
//  Copyright (c) 2014 PRX. All rights reserved.
//

@import Foundation;

extern NSString * const TWLEncoderErrorDomain;

typedef NS_ENUM(NSInteger, TWLEncoderError) {
  TWLEncoderErrorUnknown = -1,
  TWLEncoderErrorCancelled = -999,
  TWLEncoderErrorUnsupportedAudio = -1000,
  TWLEncoderErrorCannotInitialize = -1001,
  TWLEncoderErrorBadConfiguration = -2000,
  TWLEncoderErrorCannotAllocateInputBuffer = -2001,
  TWLEncoderErrorCannotAllocateOutputBuffer = -2002,
  TWLEncoderErrorCannotOpenFile = -3000,
  TWLEncoderErrorCannotReadFile = -3001
};

typedef NS_ENUM(NSInteger, TWLEncoderOutputMode) {
  TWLEncoderOutputModeAuto,
  TWLEncoderOutputModeMono,
  TWLEncoderOutputModeStereo,
  TWLEncoderOutputModeJointStereo,
  TWLEncoderOutputModeDualChannel
};

typedef NS_ENUM(NSInteger, TWLEncoderEmphasis) {
  TWLEncoderEmphasisNone,
  TWLEncoderEmphasisC,
  TWLEncoderEmphasis5
};

@protocol TWLEncoderDelegate;
@class TWLEncoderTask, TWLEncoderConfiguration;

@interface TWLEncoder : NSObject

+ (instancetype)encoderWithConfiguration:(TWLEncoderConfiguration *)configuration;
+ (instancetype)encoderWithConfiguration:(TWLEncoderConfiguration *)configuration delegate:(id<TWLEncoderDelegate>)delegate operationQueue:(NSOperationQueue *)queue;
+ (instancetype)sharedEncoder;

@property (nonatomic, strong) id<TWLEncoderDelegate> delegate;
@property (nonatomic, strong, readonly) TWLEncoderConfiguration *configuration;

- (TWLEncoderTask *)taskWithURL:(NSURL *)url;

@end

@protocol TWLEncoderDelegate <NSObject>

@required

- (void)encoder:(TWLEncoder *)encoder task:(TWLEncoderTask *)task didWriteFrames:(int64_t)framesWritten totalFramesWritten:(int64_t)totalFramesWritten totalFrameExpectedToWrite:(int64_t)totalFramesExpectedToWrite bytesWritten:(int64_t)bytessWritten totalBytesWritten:(int64_t)totalBytesWritten;
- (void)encoder:(TWLEncoder *)encoder task:(TWLEncoderTask *)task didFinishEncodingToURL:(NSURL *)location;

@end