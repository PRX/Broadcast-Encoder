//
//  TWLPCMAudioFile.h
//  Broadcast Encoder
//
//  Created by Christopher Kalafarski on 3/17/14.
//  Copyright (c) 2014 PRX. All rights reserved.
//

@import Foundation;

#import <sndfile.h>

@interface TWLPCMAudioFile : NSObject

@property (nonatomic, strong, readonly) NSURL *fileURL;
@property (nonatomic, readonly) SF_INFO *sndfileInfo;
@property (nonatomic, readonly, getter = isRaw) BOOL raw;

+ (instancetype)fileWithFileURL:(NSURL *)fileURL sndfileInfo:(SF_INFO *)sndfileInfo raw:(BOOL)isRaw error:(NSError **)error;

- (id)initWithFileURL:(NSURL *)fileURL sndfileInfo:(SF_INFO *)sndfileInfo raw:(BOOL)isRaw error:(NSError **)error;

- (int64_t)readBuffer:(short *)buffer samples:(int)samples;

- (int)close;

@end
