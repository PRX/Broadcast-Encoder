//
//  TWLEncoderTask.h
//  Broadcast Encoder
//
//  Created by Christopher Kalafarski on 3/12/14.
//  Copyright (c) 2014 PRX. All rights reserved.
//

@import Foundation;

@class TWLEncoder;
@protocol TWLEncoderTaskDelegate;

/*
 * TWLEncoderTask - a cancelable object that refers to the lifetime
 * of encoding a given audio file.
 */
@interface TWLEncoderTask : NSObject <NSCopying>

@property (readonly, weak) id <TWLEncoderTaskDelegate> delegate;

/* an identifier for this task, assigned by and unique to the owning session */
@property (readonly) NSUInteger taskIdentifier;

/* original file URL of the PCM audio to be encoded */
@property (readonly, copy) NSURL *originalURL;

#warning TODO
/* number of bytes already encoded into MP2 */
//@property (readonly) int64_t countOfBytesEncoded;

/* number of frames already encoded into MP2 */
//@property (readonly) int64_t countOfFramesEncoded;

/* number of frames we expect to encode */
//@property (readonly) int64_t countOfFramesExpectedToEncode;

/*
 * The taskDescription property is available for the developer to
 * provide a descriptive label for the task.
 */
@property (copy) NSString *taskDescription;

/* -cancel returns immediately, but marks a task as being canceled.
 * The task will signal -encoder:task:didCompleteWithError: with an
 * error value of { TWLEncoderErrorDomain, TWLEncoderErrorCancelled }.  In some
 * cases, the task may signal other work before it acknowledges the
 * cancelation.  -cancel may be sent to a task that has been suspended.
 */
- (void)cancel;

/*
 * The error, if any, delivered via -encoder:task:didCompleteWithError:
 * This property will be nil in the event that no error occured.
 */
@property (readonly, copy) NSError *error;

/* Called to being the encoding process */
- (void)resume;

@end

@protocol TWLEncoderTaskDelegate <NSObject>

@optional

- (void)encoder:(TWLEncoder *)encoder task:(TWLEncoderTask *)task didCompleteWithError:(NSError *)error;

@end