//
//  SOXResamplerConfiguration.m
//  Broadcast Encoder
//
//  Created by Christopher Kalafarski on 3/13/14.
//  Copyright (c) 2014 PRX. All rights reserved.
//

#import "SOXResamplerConfiguration.h"

@implementation SOXResamplerConfiguration

+ (instancetype)publicRadioConfiguration {
  SOXResamplerConfiguration *config = self.new;
  
  config.targetSampleRate = 44110;
  
  return config;
}

@end
