//
//  TWLEncoder.h
//  Broadcast Encoder
//
//  Created by Christopher Kalafarski on 3/12/14.
//  Copyright (c) 2014 PRX. All rights reserved.
//

@import Foundation;

/**
 
 TWLEncoder provides an interface for encoding PCM audio data to MPEG Audio
 Layer 2. It relies on the TwoLAME library, and allows for options that affect
 the audio encoding to be set in an abstract way.
 
 A TWLEncoder may be bound to a delegate object. The delegate is invoked for
 certain events during the lifetime of an encoder.
 
 TWLEncoder instances are threadsafe.
 
 A TWLEncoder creates TWLEncoderTask objects which represent the action
 of a file being encoded. TWLEncoderTask objects are always created in
 a suspended state and must be sent the -resume message before they will
 execute.

 A TWLEncoderTask will directly write the encoded MP2 audio data to a 
 temporary file. When completed, the delegate is sent
 encoder:task:didFinishEncodingToURL: and given an opportunity to move
 this file to a permanent location in its sandboxed container, or to
 otherwise read the file. If canceled, any encoded audio data for an
 TWLEncoderTask is lost.
 
 */

@class TWLEncoderTask;
@class TWLEncoderConfiguration;
@protocol TWLEncoderDelegate;

@interface TWLEncoder : NSObject

/*
 * The shared encoded has a basic configuration and uses
 * an operation queue that the class manages internally.
 */
+ (instancetype)sharedEncoder;

/*
 * Customization of TWLEncoder occurs during the creation of a new encoder.
 * If you only need to use the convenience routines with custom
 * configuration options it is not necessary to specify a delegate.
 * If no operation queue is provided, all tasks will be executed in 
 * a default queue that the class manages internally.
 */
+ (instancetype)encoderWithConfiguration:(TWLEncoderConfiguration *)configuration;
+ (instancetype)encoderWithConfiguration:(TWLEncoderConfiguration *)configuration delegate:(id<TWLEncoderDelegate>)delegate operationQueue:(NSOperationQueue *)queue;

@property (readonly, retain) NSOperationQueue *operationQueue;
@property (readonly, weak) id <TWLEncoderDelegate> delegate;
@property (readonly, copy) TWLEncoderConfiguration *configuration;

/*
 * The encoderDescription property is available for the developer to
 * provide a descriptive label for the encoder.
 */
@property (copy) NSString *encoderDescription;

/*
 * TWLEncoderTask objects are always created in a suspended state and
 * must be sent the -resume message before they will execute.
 */

/* Creates a data task to encode the PCM audio data of the given file URL. */
- (TWLEncoderTask *)taskWithURL:(NSURL *)url;

@end

/*
 * TWLEncoderDelegate specifies the methods that a session delegate
 * may respond to.  There are both session specific messages (for
 * example, encoder setup errors) as well as task based messages.
 */

/*
 * Messages related to the encoder as a whole, and to the operation
 * of a task that writes data to a file and notifies the delegate
 * upon completion.
 */

@protocol TWLEncoderDelegate <NSObject>
@optional

/* The last message an encoder receives.  An encoder will only become
 * invalid because of a systemic error or when it has been
 * explicitly invalidated, in which case it will receive an
 * { TWLEncoderErrorDomain, TWLEncoderErrorCancelled } error.
 */
- (void)encoder:(TWLEncoder *)encoder didBecomeInvalidWithError:(NSError *)error;

@required

/* Sent when an encoding task that has completed encoding.  The delegate should
 * copy or move the file at the given location to a new location as it will be
 * removed when the delegate message returns. encoder:task:didCompleteWithError: will
 * still be called.
 */
- (void)encoder:(TWLEncoder *)encoder task:(TWLEncoderTask *)task didFinishEncodingToURL:(NSURL *)location;

/* Sent periodically to notify the delegate of download progress. */
- (void)encoder:(TWLEncoder *)encoder task:(TWLEncoderTask *)task didWriteFrames:(int64_t)framesWritten totalFramesWritten:(int64_t)totalFramesWritten totalFrameExpectedToWrite:(int64_t)totalFramesExpectedToWrite bytesWritten:(int64_t)bytessWritten totalBytesWritten:(int64_t)totalBytesWritten;

@end
