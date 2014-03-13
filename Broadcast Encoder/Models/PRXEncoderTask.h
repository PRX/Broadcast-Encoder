//
//  PRXEncoderTask.h
//  Broadcast Encoder
//
//  Created by Christopher Kalafarski on 3/12/14.
//  Copyright (c) 2014 PRX. All rights reserved.
//

@import Foundation;

@protocol PRXEncoderTaskDelegate;

@interface PRXEncoderTask : NSObject

+ (instancetype)defaultEncoder;

@property (nonatomic, strong) id<PRXEncoderTaskDelegate> delegate;

- (void)encodeFileAtPath:(NSString *)path progress:(void (^)(NSString *))resultPath;

@end

@protocol PRXEncoderDelegate <NSObject>



@end
