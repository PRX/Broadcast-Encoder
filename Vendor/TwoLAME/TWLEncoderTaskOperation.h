//
//  TWLEncoderTaskOperation.h
//  Broadcast Encoder
//
//  Created by Christopher Kalafarski on 3/12/14.
//  Copyright (c) 2014 PRX. All rights reserved.
//

@import Foundation;

@class TWLEncoderTask;

@interface TWLEncoderTaskOperation : NSOperation

+ (instancetype)operationWithTask:(TWLEncoderTask *)task;

- (instancetype)initWithTask:(TWLEncoderTask *)task;

@end
