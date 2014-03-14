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
@property BOOL channelSwap;

/* channel mode for output audio (mono, stereo, joint, dual, auto) */
@property TWLEncoderOutputMode outputMode;

/* bitrate of the resulting MP2 file in kilobits per second */
@property NSUInteger kilobitrate;

/* enable VBR mode, default value is 5.0 */
@property BOOL variableBitrate;

/* Enable VBR mode and set quality level. 
 * The higher the number the better the quality. 
 * Maximum range is -50 to 50 but useful range is -10 to 10
 */
@property NSNumber *variableBitrateLevel;

/* indicate that MPEG stream is copyrighted */
@property BOOL markAsCopyright;

/* set the MPEG Audio Original flag */
@property BOOL markAsOriginal;

/* enable/disable CRC error protection */
@property BOOL protect;

/* turn on padding in output bitstream */
@property BOOL padding;

/* the type of pre-emphasis to be applied to the encoded audio */
@property TWLEncoderEmphasis deemphasis;

/* turn on energy level extensions */
@property BOOL energy;

@end
