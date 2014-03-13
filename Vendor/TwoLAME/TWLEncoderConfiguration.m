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
  config.bitrate = (256 * 1024);
  
//  -t 0 --mode j --bitrate 256 --protect --copyright --original --deemphasis n
  return config;
}

@end
