//
//  PRXDropzoneViewController.m
//  Broadcast Encoder
//
//  Created by Christopher Kalafarski on 3/12/14.
//  Copyright (c) 2014 PRX. All rights reserved.
//

#import "PRXDropzoneViewController.h"
#import "TWLEncoder.h"
#import "TWLEncoderConfiguration.h"
#import "TWLEncoderTask.h"
#import "SOXResampler.h"
#import "SOXResamplerConfiguration.h"
#import "SOXResamplerTask.h"

@interface PRXDropzoneViewController ()

@property (nonatomic, strong, readonly) SOXResampler *resampler;
@property (nonatomic, strong, readonly) TWLEncoder *encoder;

@end

@implementation PRXDropzoneViewController

@synthesize resampler = _resampler;
@synthesize encoder = _encoder;

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

#pragma mark - Encoding

- (SOXResampler *)resampler {
  if (!_resampler) {
    SOXResamplerConfiguration *config = SOXResamplerConfiguration.publicRadioConfiguration;
    
    _resampler = [SOXResampler resamplerWithConfiguration:config];
    _resampler.delegate = self;
  }
  
  return _resampler;
}

- (TWLEncoder *)encoder {
  if (!_encoder) {
    TWLEncoderConfiguration *config = TWLEncoderConfiguration.publicRadioConfiguration;
    _encoder = [TWLEncoder encoderWithConfiguration:config delegate:self operationQueue:nil];
  }
  
  return _encoder;
}

- (void)encodeFilesFromPaths:(NSArray *)filePaths {
  NSArray *acceptableExtensions = @[ @"wav", @"aiff", @"aif" ];
  
  for (NSString *filePath in filePaths) {
    if ([acceptableExtensions containsObject:filePath.pathExtension.lowercaseString]) {
      NSURL *fileURL = [NSURL fileURLWithPath:filePath];
      [self resampleAndOrEncodeFileAtURL:fileURL];
    }
  }
}

- (void)resampleAndOrEncodeFileAtURL:(NSURL *)url {
  BOOL needsResampling = NO;
  
  if (needsResampling) {
    [self resampleAndEncodeFileAtURL:url];
  } else {
    [self encodeFileAtURL:url];
  }
}

- (void)resampleAndEncodeFileAtURL:(NSURL *)url {
  SOXResamplerTask *task = [self.resampler taskWithURL:url];
  [task resume];
}

- (void)encodeFileAtURL:(NSURL *)url {
  TWLEncoderTask *task = [self.encoder taskWithURL:url];
  [task resume];
}

#pragma mark - PRXDropzoneViewDelegate

- (void)performDropzoneDragOperation:(id<NSDraggingInfo>)sender {
  NSPasteboard *pasteboard = [sender draggingPasteboard];
  
  NSArray *acceptableTypes = @[ NSFilenamesPboardType ];
  NSString *availableTypes = [pasteboard availableTypeFromArray:acceptableTypes];
  
  if ([availableTypes isEqualToString:NSFilenamesPboardType]) {
    
    
    NSArray *filePaths = [pasteboard propertyListForType:NSFilenamesPboardType];
    [self encodeFilesFromPaths:filePaths];
    
  }
}

#pragma mark - SOXResamplerDelegate

- (void)resampler:(SOXResampler *)resampler task:(SOXResamplerTask *)task didFinishResamplingToURL:(NSURL *)location {
  [self encodeFileAtURL:location];
  NSLog(@"Now the resulting file needs to be encoded...");
}

#pragma mark - SOXResamplerTaskDelegate

- (void)resampler:(SOXResampler *)encoder task:(SOXResamplerTask *)task didCompleteWithError:(NSError *)error {
  NSLog(@"Resampling error");
}

#pragma mark - TWLEncoderDelegate

- (void)encoder:(TWLEncoder *)encoder task:(TWLEncoderTask *)task didCompleteWithError:(NSError *)error {
  NSLog(@"error %@", error);
}

#pragma mark - TWLEncoderTaskDelegate

- (void)encoder:(TWLEncoder *)encoder task:(TWLEncoderTask *)task didWriteFrames:(int64_t)framesWritten totalFramesWritten:(int64_t)totalFramesWritten totalFrameExpectedToWrite:(int64_t)totalFramesExpectedToWrite bytesWritten:(int64_t)bytessWritten totalBytesWritten:(int64_t)totalBytesWritten {
  
  dispatch_async(dispatch_get_main_queue(), ^{
    if (framesWritten == totalFramesWritten) {
      self.dropzoneView.progressIndicator.maxValue = totalFramesExpectedToWrite;
      self.dropzoneView.progressIndicator.minValue = 0;
    }
    
    self.dropzoneView.progressIndicator.doubleValue = totalFramesWritten;
  });
}

- (void)encoder:(TWLEncoder *)encoder task:(TWLEncoderTask *)task didFinishEncodingToURL:(NSURL *)location {
  NSURL *inputDirectory = [task.originalURL URLByDeletingLastPathComponent];
  NSString *inputFileName = [task.originalURL.pathComponents lastObject];
  
  NSString *outputFileName = [NSString stringWithFormat:@"%@.mp2", inputFileName];
  NSURL *outputURL = [inputDirectory URLByAppendingPathComponent:outputFileName];
  
  [NSFileManager.defaultManager copyItemAtURL:location toURL:outputURL error:nil];
  
  dispatch_async(dispatch_get_main_queue(), ^{
    [[[self dropzoneView] textField] setStringValue:@"Done!"];
    self.dropzoneView.progressIndicator.doubleValue = 0;
  });
  
  NSUserNotification *notification = NSUserNotification.new;
  notification.title = @"Encoding complete";
  notification.subtitle = inputFileName;
  notification.informativeText = @"Broadcast-ready MP2 now available";
  notification.soundName = NSUserNotificationDefaultSoundName;
  notification.userInfo = @{ @"path": outputURL.path };
  
  NSUserNotificationCenter *center = NSUserNotificationCenter.defaultUserNotificationCenter;
  [center setDelegate:self];
  [center deliverNotification:notification];
}

#pragma mark - NSUserNotificationCenterDelegate

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification {
  return YES;
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification {
  NSString *path = notification.userInfo[@"path"];
  NSURL *fileURL = [NSURL fileURLWithPath:path];
  [NSWorkspace.sharedWorkspace activateFileViewerSelectingURLs:@[ fileURL ]];
}

@end
