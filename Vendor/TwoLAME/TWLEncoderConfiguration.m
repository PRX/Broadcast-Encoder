//
//  TWLEncoderConfiguration.m
//  Broadcast Encoder
//
//  Created by Christopher Kalafarski on 3/12/14.
//  Copyright (c) 2014 PRX. All rights reserved.
//

#import "TWLEncoderConfiguration.h"

@implementation TWLEncoderConfiguration

+ (instancetype)publicRadioConfiguration {
  TWLEncoderConfiguration *config = self.new;
  
  config.markAsCopyright = YES;
  config.markAsOriginal = YES;
  config.protect = YES;
  config.deemphasis = TWLEncoderEmphasisNone;
  
  config.outputMode = TWLEncoderOutputModeJointStereo;
  config.kilobitrate = 256;
  
//  -t 0 --mode j --bitrate 256 --protect --copyright --original --deemphasis n
  return config;
}

- (id)copyWithZone:(NSZone *)zone {
  TWLEncoderConfiguration *copy = self.class.new;
  
  if (copy) {
    copy.raw = self.raw;
    
    copy.byteSwap = self.byteSwap;
    copy.channelSwap = self.channelSwap;
    
    copy.outputMode = self.outputMode;
    
    copy.kilobitrate = self.kilobitrate;
    
    copy.markAsCopyright = self.markAsCopyright;
    copy.markAsOriginal = self.markAsOriginal;
    copy.protect = self.protect;
    copy.deemphasis = self.deemphasis;
  }
  
  return copy;
}

@end
