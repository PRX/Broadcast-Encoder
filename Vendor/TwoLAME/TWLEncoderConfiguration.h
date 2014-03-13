//
//  TWLEncoderConfiguration.h
//  Broadcast Encoder
//
//  Created by Christopher Kalafarski on 3/12/14.
//  Copyright (c) 2014 PRX. All rights reserved.
//

@import Foundation;

#import "TWLEncoder.h"

@interface TWLEncoderConfiguration : NSObject

+ (instancetype)publicRadioConfiguration;

@property (nonatomic) BOOL byteSwap;
@property (nonatomic) BOOL channelSwap;

@property (nonatomic) TWLEncoderOutputMode outputMode;

@property (nonatomic) NSUInteger bitrate;

@property (nonatomic) BOOL markAsCopyright;
@property (nonatomic) BOOL markAsOriginal;
@property (nonatomic) BOOL protect;
@property (nonatomic) BOOL deemphasis;


@end
