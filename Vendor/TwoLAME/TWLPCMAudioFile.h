//
//  TWLPCMAudioFile.h
//  Broadcast Encoder
//
//  Created by Christopher Kalafarski on 3/17/14.
//  Copyright (c) 2014 PRX. All rights reserved.
//

@import Foundation;

#import <sndfile.h>

/**
 
 A TWLPCMAudioFile represents a file on disk that is intended to be
 encoded with a TwoLAME encoder managed by a TWLEncoder object.
 
 The properties of TWLPCMAudioFile instances are set when the object
 is created, and cannot be changed.
 
 */

@interface TWLPCMAudioFile : NSObject

/* the local URL of the audio file this object represents */
@property (nonatomic, copy, readonly) NSURL *fileURL;

/*  */
@property (nonatomic, readonly) SF_INFO *sndfileInfo;

/* determines if the audio file should be treated as headerless raw PCM data */
@property (nonatomic, readonly, getter = isRaw) BOOL raw;

+ (instancetype)fileWithFileURL:(NSURL *)fileURL sndfileInfo:(SF_INFO *)sndfileInfo raw:(BOOL)isRaw error:(NSError **)error;

- (id)initWithFileURL:(NSURL *)fileURL sndfileInfo:(SF_INFO *)sndfileInfo raw:(BOOL)isRaw error:(NSError **)error;

- (int64_t)readBuffer:(short *)buffer samples:(int)samples;

- (int)close;

@end
