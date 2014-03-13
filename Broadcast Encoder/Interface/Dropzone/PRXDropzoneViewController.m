//
//  PRXDropzoneViewController.m
//  Broadcast Encoder
//
//  Created by Christopher Kalafarski on 3/12/14.
//  Copyright (c) 2014 PRX. All rights reserved.
//

#import "PRXDropzoneViewController.h"
#import "TWLEncoder.h"
#import "TWLEncoderTask.h"

@interface PRXDropzoneViewController ()

@end

@implementation PRXDropzoneViewController

- (void)awakeFromNib {
  [super awakeFromNib];
}

- (void)setView:(NSView *)view {
  [super setView:view];
  
  if ([view isKindOfClass:PRXDropzoneView.class]) {
    PRXDropzoneView *dropzoneView = (PRXDropzoneView *)view;
    dropzoneView.delegate = self;
  }
}

- (PRXDropzoneView *)dropzoneView {
  return (PRXDropzoneView *)self.view;
}

#pragma mark - PRXDropzoneViewDelegate

- (void)performDropzoneDragOperation:(id<NSDraggingInfo>)sender {
  NSPasteboard *pasteboard = [sender draggingPasteboard];
  
  NSArray *acceptableTypes = @[ NSFilenamesPboardType ];
  NSString *availableTypes = [pasteboard availableTypeFromArray:acceptableTypes];
  
  if ([availableTypes isEqualToString:NSFilenamesPboardType]) {
    NSArray *files = [pasteboard propertyListForType:NSFilenamesPboardType];
    
    NSArray *acceptableExtensions = @[ @"wav", @"aiff", @"aif" ];
    
    TWLEncoder *encoder = TWLEncoder.sharedEncoder;
    encoder.delegate = self;
    
    for (NSString *filePath in files) {
      if ([acceptableExtensions containsObject:filePath.pathExtension.lowercaseString]) {
        NSURL *fileURL = [NSURL fileURLWithPath:filePath];
        
        TWLEncoderTask *task = [encoder taskWithURL:fileURL];
        task.delegate = self;
        [task resume];
      }
    }
  }
}

#pragma mark - TWLEncoderDelegate

- (void)encoder:(TWLEncoder *)encoder task:(TWLEncoderTask *)task didCompleteWithError:(NSError *)error {
  NSLog(@"error %@", error);
}

#pragma mark - TWLEncoderTaskDelegate

- (void)encoder:(TWLEncoder *)encoder task:(TWLEncoderTask *)task didWriteFrames:(int64_t)framesWritten totalFramesWritten:(int64_t)totalFramesWritten totalFrameExpectedToWrite:(int64_t)totalFramesExpectedToWrite {
  
  dispatch_async(dispatch_get_main_queue(), ^{
    [[[self dropzoneView] textField] setStringValue:@"Working..."];
  });
  
  NSLog(@"%lli - %lli", framesWritten, totalFramesWritten);
}

- (void)encoder:(TWLEncoder *)encoder task:(TWLEncoderTask *)task didFinishEncodingToURL:(NSURL *)location {
  NSURL *inputDirectory = [task.originalURL URLByDeletingLastPathComponent];
  NSString *inputFileName = [task.originalURL.pathComponents lastObject];
  
  NSString *outputFileName = [NSString stringWithFormat:@"%@.mp2", inputFileName];
  NSURL *outputURL = [inputDirectory URLByAppendingPathComponent:outputFileName];
  
  [NSFileManager.defaultManager copyItemAtURL:location toURL:outputURL error:nil];
  
  dispatch_async(dispatch_get_main_queue(), ^{
    [[[self dropzoneView] textField] setStringValue:@"Done!"];
  });
}

@end
