//
//  PRXResampler.m
//  Broadcast Encoder
//
//  Created by Christopher Kalafarski on 3/12/14.
//  Copyright (c) 2014 PRX. All rights reserved.
//

#import "PRXResampler.h"
#import "sox.h"

@implementation PRXResampler

+ (instancetype)defaultResampler {
  static dispatch_once_t pred;
  static id instance = nil;
  
  dispatch_once(&pred, ^{
    if (!instance) {
      instance = self.new;
    }
  });
  
  return instance;
}

- (void)encodeFileAtPath:(NSString *)path completionHandler:(void (^)(NSString *))resultPath {
  
}

@end
