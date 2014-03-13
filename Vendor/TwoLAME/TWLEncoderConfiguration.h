//
//  TWLEncoderConfiguration.h
//  Broadcast Encoder
//
//  Created by Christopher Kalafarski on 3/12/14.
//  Copyright (c) 2014 PRX. All rights reserved.
//

@import Foundation;

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

/*
 * Configuration options for an TWLEncoder.  When an encoder is
 * created, a copy of the configuration object is made - you cannot
 * modify the configuration of an encoder after it has been created.
 *
 * A public radio configuration can be used to create MP2 audio files
 * consistent with the broadcast systems of most public radio stations
 * in the United States.
 */

@interface TWLEncoderConfiguration : NSObject <NSCopying>

+ (instancetype)publicRadioConfiguration;

/* identifier for the background session configuration */
@property (readonly, copy) NSString *identifier;

/* Tells the encoder audio files will be raw PCM data */
@property BOOL raw;

/* endianness of the audio should be swapped */
@property BOOL byteSwap;

/* left and right channels of stereo audio should be swapped in encoded audio */
@property (nonatomic) BOOL channelSwap;

/* channel mode for output audio (mono, stereo, joint, dual, auto) */
@property (nonatomic) TWLEncoderOutputMode outputMode;

/* bitrate of the resulting MP2 file in kilobits per second */
@property (nonatomic) NSUInteger kilobitrate;

/* indicate that MPEG stream is copyrighted */
@property (nonatomic) BOOL markAsCopyright;

/* set the MPEG Audio Original flag */
@property (nonatomic) BOOL markAsOriginal;

/* enable/disable CRC error protection. */
@property (nonatomic) BOOL protect;

/* the type of pre-emphasis to be applied to the encoded audio */
@property (nonatomic) TWLEncoderEmphasis deemphasis;

@end
