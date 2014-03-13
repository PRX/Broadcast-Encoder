//
//  PRXResampler.h
//  Broadcast Encoder
//
//  Created by Christopher Kalafarski on 3/12/14.
//  Copyright (c) 2014 PRX. All rights reserved.
//

@import Foundation;

@interface PRXResampler : NSObject

+ (instancetype)defaultResampler;

- (void)encodeFileAtPath:(NSString *)path complete:(void (^)(NSString *))completeBlock;

@end
