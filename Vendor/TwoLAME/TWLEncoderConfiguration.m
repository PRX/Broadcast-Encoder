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
    copy.variableBitrate = self.variableBitrate;
    copy.variableBitrateLevel = self.variableBitrateLevel.copy;
    
    copy.markAsCopyright = self.markAsCopyright;
    copy.markAsOriginal = self.markAsOriginal;
    copy.protect = self.protect;
    copy.padding = self.padding;
    copy.deemphasis = self.deemphasis;
    copy.energy = self.energy;
  }
  
  return copy;
}

@end
