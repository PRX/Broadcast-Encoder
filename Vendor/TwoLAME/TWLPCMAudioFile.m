//
//  TWLPCMAudioFile.m
//  Broadcast Encoder
//
//  Created by Christopher Kalafarski on 3/17/14.
//  Copyright (c) 2014 PRX. All rights reserved.
//

#import "TWLPCMAudioFile.h"
#import "TWLEncoderError.h"

@interface TWLPCMAudioFile ()

@property (nonatomic, readonly) FILE *rawFile;
@property (nonatomic, readonly) SNDFILE *sndfileFile;

- (int64_t)readRawBuffer:(short *)buffer samples:(int)samples;
- (sf_count_t)readFileBuffer:(short *)buffer samples:(int)samples;

- (int)closeRaw;
- (int)closeFile;

@end

@implementation TWLPCMAudioFile

+ (instancetype)fileWithFileURL:(NSURL *)fileURL sndfileInfo:(SF_INFO *)sndfileInfo raw:(BOOL)isRaw error:(NSError **)error {
  return [[self alloc] initWithFileURL:fileURL sndfileInfo:sndfileInfo raw:isRaw error:error];
}

#pragma mark - Initializers

- (id)initWithFileURL:(NSURL *)fileURL sndfileInfo:(SF_INFO *)sndfileInfo raw:(BOOL)isRaw error:(NSError **)error {
  self = [super init];
  if (self) {
    _fileURL = fileURL;
    _sndfileInfo = sndfileInfo;
    _raw = isRaw;
    
    // Open the file
    if (isRaw) {
      _rawFile = fopen(self.fileURL.fileSystemRepresentation, "rb");
      
      if (_rawFile == NULL) {
        *error = [NSError errorWithDomain:TWLEncoderErrorDomain code:TWLEncoderErrorCannotOpenFile userInfo:nil];
      }
    } else {
      _sndfileFile = sf_open(self.fileURL.fileSystemRepresentation, SFM_READ, self.sndfileInfo);
      
      if (self.sndfileFile == NULL) {
        *error = [NSError errorWithDomain:TWLEncoderErrorDomain code:TWLEncoderErrorUnsupportedAudio userInfo:nil];
      }
    }
  }
  return self;
}

#pragma mark - Reading File

- (int64_t)readBuffer:(short *)buffer samples:(int)samples {
  if (self.isRaw) {
    return [self readRawBuffer:buffer samples:samples];
  } else {
    return [self readFileBuffer:buffer samples:samples];
  }
}

- (int64_t)readRawBuffer:(short *)buffer samples:(int)samples {
  return fread(buffer, 2, samples, self.rawFile);
}

- (sf_count_t)readFileBuffer:(short *)buffer samples:(int)samples {
  return sf_read_short(self.sndfileFile, buffer, samples);
}

#pragma mark - Close File

- (int)close {
  if (self.isRaw) {
    return [self closeRaw];
  } else {
    return [self closeFile];
  }
}

- (int)closeRaw {
  return fclose(self.rawFile);
}

- (int)closeFile {
  return sf_close(self.sndfileFile);
}

@end
