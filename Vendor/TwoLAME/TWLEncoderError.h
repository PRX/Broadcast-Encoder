//
//  TWLEncoderError.h
//  Broadcast Encoder
//
//  Created by Christopher Kalafarski on 3/13/14.
//  Copyright (c) 2014 PRX. All rights reserved.
//

@class NSString;

/*
 @discussion Constants used by NSError to differentiate between "domains" of error codes, serving as a discriminator for error codes that originate from different subsystems or sources.
 @constant TWLEncoderErrorDomain Indicates a TwoLAME encoder error.
 */
FOUNDATION_EXPORT NSString * const TWLEncoderErrorDomain;

/*!
 @enum TWLEncoder-related Error Codes
 @abstract Constants used by NSError to indicate errors in the TwoLAME domain
 @discussion Documentation on each constant forthcoming.
 */

typedef NS_ENUM(NSInteger, TWLEncoderError) {
  TWLEncoderErrorUnknown = -1,
  TWLEncoderErrorCancelled = -999,
  TWLEncoderErrorUnsupportedAudio = -1000,
  
  // Encoder errors
  TWLEncoderErrorCannotInitialize = -2000,
  TWLEncoderErrorBadConfiguration = -2001,
  TWLEncoderErrorCannotAllocateInputBuffer = -2002,
  TWLEncoderErrorCannotAllocateOutputBuffer = -2003,
  
  // File I/O errors
  TWLEncoderErrorCannotOpenFile = -3000,
  TWLEncoderErrorCannotReadFile = -3001
};