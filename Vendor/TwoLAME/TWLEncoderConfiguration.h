//
//  TWLEncoderConfiguration.h
//  Broadcast Encoder
//
//  Created by Christopher Kalafarski on 3/12/14.
//  Copyright (c) 2014 PRX. All rights reserved.
//

@import Foundation;

#import "TWLEncoder.h"

@interface TWLEncoderConfiguration : NSObject <NSCopying>

+ (instancetype)publicRadioConfiguration;

@property (nonatomic) BOOL raw;

@property (nonatomic) BOOL byteSwap;
@property (nonatomic) BOOL channelSwap;

@property (nonatomic) TWLEncoderOutputMode outputMode;

@property (nonatomic) NSUInteger kilobitrate;

@property (nonatomic) BOOL markAsCopyright;
@property (nonatomic) BOOL markAsOriginal;
@property (nonatomic) BOOL protect;
@property (nonatomic) TWLEncoderEmphasis deemphasis;


@end
