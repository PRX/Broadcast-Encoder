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
#import <sndfile/sndfile.h>
#import <soxr/soxr.h>

@interface PRXDropzoneViewController ()

@property (nonatomic, strong, readonly) SOXResampler *resampler;
@property (nonatomic, strong, readonly) TWLEncoder *monoEncoder;
@property (nonatomic, strong, readonly) TWLEncoder *stereoEncoder;

@property (nonatomic, strong) NSMutableDictionary *originalURLs;

@end

@implementation PRXDropzoneViewController

@synthesize resampler = _resampler;
@synthesize monoEncoder = _monoEncoder;
@synthesize stereoEncoder = _stereoEncoder;

- (void)awakeFromNib {
  [super awakeFromNib];
  
  self.originalURLs = NSMutableDictionary.dictionary;
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

#pragma mark - Actions 

- (void)closeAction:(id)sender {
  NSWindow *window = self.view.window;
  [window performClose:self];
}

- (void)helpAction:(id)sender {
  NSString *helpBookName = [NSBundle.mainBundle objectForInfoDictionaryKey: @"CFBundleHelpBookName"];
  [NSHelpManager.sharedHelpManager openHelpAnchor:@"nil" inBook:helpBookName];
}

#pragma mark - Encoding

- (SOXResampler *)resampler {
  if (!_resampler) {
    SOXResamplerConfiguration *config = SOXResamplerConfiguration.publicRadioConfiguration;
    _resampler = [SOXResampler resamplerWithConfiguration:config delegate:self operationQueue:nil];
  }
  
  return _resampler;
}

- (TWLEncoder *)monoEncoder {
  if (!_monoEncoder) {
    TWLEncoderConfiguration *config = TWLEncoderConfiguration.publicRadioConfiguration;
    config.outputMode = TWLEncoderOutputModeMono;
    config.kilobitrate = 128;
    
    _monoEncoder = [TWLEncoder encoderWithConfiguration:config delegate:self operationQueue:nil];
  }
  
  return _monoEncoder;
}

- (TWLEncoder *)stereoEncoder {
  if (!_stereoEncoder) {
    TWLEncoderConfiguration *config = TWLEncoderConfiguration.publicRadioConfiguration;
    _stereoEncoder = [TWLEncoder encoderWithConfiguration:config delegate:self operationQueue:nil];
  }
  
  return _stereoEncoder;
}

- (void)encodeFilesFromURLs:(NSArray *)fileURLs {
  NSArray *acceptableExtensions = @[ @"wav", @"aiff", @"aif" ];
  
  for (NSURL *fileURL in fileURLs) {
    if ([acceptableExtensions containsObject:fileURL.pathExtension.lowercaseString]) {
      [self resampleAndOrEncodeFileAtURL:fileURL];
    }
  }
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
  static SNDFILE *input_file;
  SF_INFO input_file_info;
  
  input_file = sf_open(url.path.fileSystemRepresentation, SFM_READ, &input_file_info);
  
  BOOL needsResampling = NO;
  
  if (input_file == NULL) {
    NSLog(@"error 3");
    return;
  } else {
    needsResampling = (input_file_info.samplerate != 44100);
  }
  
  BOOL isClean = YES;
  
  if (needsResampling) { isClean = NO; NSLog(@"Not clean; resample"); }
  if (input_file_info.channels != 1 && input_file_info.channels != 2) { isClean = NO; NSLog(@"Not clean; channels"); }
  if ((input_file_info.format & SF_FORMAT_PCM_16) != SF_FORMAT_PCM_16 ) { isClean = NO; NSLog(@"Not clean; bit depth"); }
  
  sf_close(input_file);
  
  if (isClean) {
    [self _resampleAndOrEncodeFileAtURL:url];
  } else {
    NSAlert *alert = NSAlert.new;
    alert.messageText = @"Non-Standard Audio Encoding";
    alert.informativeText = @"This file is not standard 44.1 kHz, 16 bit audio.\n\nAdditional processing will occur to create a broadcast-ready MP2, but this can affect audio quality. Please review the MP2 once encoding has completed.\n\nIf there are problems, try using a standard 44.1/16 WAV or AIFF file instead.";
    alert.alertStyle = NSWarningAlertStyle;
    alert.showsHelp = YES;
    
    [alert addButtonWithTitle:@"OK"];
    [alert addButtonWithTitle:@"Cancel"];
    
    [alert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse returnCode) {
      if (returnCode == NSAlertFirstButtonReturn) {
        [self _resampleAndOrEncodeFileAtURL:url];
      }
    }];
  }
}

- (void)_resampleAndOrEncodeFileAtURL:(NSURL *)url {
  static SNDFILE *input_file;
  SF_INFO input_file_info;
  
  input_file = sf_open(url.path.fileSystemRepresentation, SFM_READ, &input_file_info);
  
  BOOL needsResampling = NO;
  
  if (input_file == NULL) {
    NSLog(@"error 2");
    return;
  } else {
    needsResampling = (input_file_info.samplerate != 44100);
  }
  
  if (needsResampling) {
    NSLog(@"Input file sample rate is not 44100; will try to resample then encode");
    [self resampleAndEncodeFileAtURL:url];
  } else {
    NSLog(@"Input file sample rate was 44100; going straight to encoding");
    [self encodeFileAtURL:url];
  }
}

- (void)resampleAndEncodeFileAtURL:(NSURL *)url {
  dispatch_async(dispatch_get_main_queue(), ^{
    self.dropzoneView.textField.stringValue = @"Resampling...";
    
    [self.dropzoneView.progressIndicator setUsesThreadedAnimation:YES];
    [self.dropzoneView.progressIndicator setIndeterminate:YES];
    [self.dropzoneView.progressIndicator startAnimation:self];
  });
  
  SOXResamplerTask *task = [self.resampler taskWithURL:url];
  [task resume];
}

- (void)encodeFileAtURL:(NSURL *)url {
  static SNDFILE *input_file;
  SF_INFO input_file_info;
  
  input_file = sf_open(url.path.fileSystemRepresentation, SFM_READ, &input_file_info);
  
  BOOL isMono = NO;
  
  if (input_file == NULL) {
    NSLog(@"error 1");
    return;
  } else {
    isMono = (input_file_info.channels == 1);
  }
 
  TWLEncoderTask *task;
  
  if (isMono) {
    NSLog(@"Encoding mono file at %@", url);
    task = [self.monoEncoder taskWithURL:url];
  } else {
    NSLog(@"Encoding stereo file at %@", url);
    task = [self.stereoEncoder taskWithURL:url];
  }
  
  [task resume];
}

#pragma mark - PRXDropzoneViewDelegate

- (void)performDropzoneDragOperation:(id<NSDraggingInfo>)sender {
  NSPasteboard *pasteboard = [sender draggingPasteboard];
  
  NSArray *acceptableTypes = @[ NSFilenamesPboardType ];
  NSString *availableTypes = [pasteboard availableTypeFromArray:acceptableTypes];
  
  if ([availableTypes isEqualToString:NSFilenamesPboardType]) {
    NSArray *filePaths = [pasteboard propertyListForType:NSFilenamesPboardType];
    [self encodeFilesFromPaths:@[ filePaths.firstObject ]];
  }
}

- (void)performFileOpenOperation:(id)sender {
  if ([sender isKindOfClass:NSOpenPanel.class]) {
    NSOpenPanel *openPanel = sender;
    
    NSArray *files = openPanel.URLs;
    [self encodeFilesFromURLs:files];
  }
}

#pragma mark - SOXResamplerDelegate

- (void)resampler:(SOXResampler *)resampler task:(SOXResamplerTask *)task didFinishResamplingToURL:(NSURL *)location {
  NSLog(@"Resampled; now the resulting file needs to be encoded...");
  
  self.originalURLs[location] = task.originalURL;
  
  [self encodeFileAtURL:location];
}

#pragma mark - SOXResamplerTaskDelegate

- (void)resampler:(SOXResampler *)encoder task:(SOXResamplerTask *)task didCompleteWithError:(NSError *)error {
  NSLog(@"Resampling error");
}

#pragma mark - TWLEncoderDelegate

- (void)encoder:(TWLEncoder *)encoder task:(TWLEncoderTask *)task didWriteFrames:(int64_t)framesWritten totalFramesWritten:(int64_t)totalFramesWritten totalFrameExpectedToWrite:(int64_t)totalFramesExpectedToWrite bytesWritten:(int64_t)bytessWritten totalBytesWritten:(int64_t)totalBytesWritten {
  
  dispatch_async(dispatch_get_main_queue(), ^{
    if (framesWritten == totalFramesWritten) {
      [[[self dropzoneView] textField] setStringValue:@"Encoding..."];
      
      [self.dropzoneView.progressIndicator setUsesThreadedAnimation:NO];
      [self.dropzoneView.progressIndicator setIndeterminate:NO];
      [self.dropzoneView.progressIndicator stopAnimation:self];
      
      self.dropzoneView.progressIndicator.minValue = 0;
      self.dropzoneView.progressIndicator.maxValue = totalFramesExpectedToWrite;
    }
    
    self.dropzoneView.progressIndicator.doubleValue = totalFramesWritten;
  });
}

- (void)encoder:(TWLEncoder *)encoder task:(TWLEncoderTask *)task didFinishEncodingToURL:(NSURL *)location {
  NSURL *originalURL;
  
  // If the encoding task was created from resampling, the URL is going to be a temp
  // file, and we don't want to copy there; we can look up the resampling task's URL
  // from a dictionary that we are maintaining
  if (self.originalURLs[task.originalURL]) {
    originalURL = [self.originalURLs[task.originalURL] copy];
    [self.originalURLs removeObjectForKey:task.originalURL];
  } else {
    originalURL = task.originalURL;
  }
  
  NSURL *inputDirectory = [originalURL URLByDeletingLastPathComponent];
  NSString *inputFileName = originalURL.pathComponents.lastObject;
  
  NSString *outputFileName = [NSString stringWithFormat:@"%@.broadcast.mp2", inputFileName.stringByDeletingPathExtension];
  NSURL *outputURL = [inputDirectory URLByAppendingPathComponent:outputFileName];
  
  NSError *error;
  [NSFileManager.defaultManager copyItemAtURL:location toURL:outputURL error:&error];
  if (error) {
    NSLog(@"error: %@", error);
  }
  
  dispatch_async(dispatch_get_main_queue(), ^{
    [[[self dropzoneView] textField] setStringValue:@"Drop a .WAV or .AIFF file"];
    self.dropzoneView.progressIndicator.doubleValue = 0;
    
    [self.dropzoneView.progressIndicator setIndeterminate:NO];
    [self.dropzoneView.progressIndicator stopAnimation:self];
  });
  
  if (!(NSAppKitVersionNumber < NSAppKitVersionNumber10_8)) {
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
  
  [NSApp requestUserAttention:NSInformationalRequest];
}

#pragma mark - TWLEncoderTaskDelegate

- (void)encoder:(TWLEncoder *)encoder task:(TWLEncoderTask *)task didCompleteWithError:(NSError *)error {
  NSLog(@"error %@", error);
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
