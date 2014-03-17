//
//  PRXDropzoneView.m
//  Broadcast Encoder
//
//  Created by Christopher Kalafarski on 3/12/14.
//  Copyright (c) 2014 PRX. All rights reserved.
//

#import "PRXDropzoneView.h"
#import <twolame.h>

@implementation PRXDropzoneView

- (void)awakeFromNib {
  [super awakeFromNib];
  
  [self registerForDraggedTypes:@[ NSColorPboardType, NSFilenamesPboardType ]];
  
  self.versionTextField.stringValue = [NSString stringWithFormat:@"TwoLAME version %s", get_twolame_version()];
}

#pragma mark - Mouse Events

- (void)mouseDown:(NSEvent *)theEvent {
  NSOpenPanel *openPanel = NSOpenPanel.openPanel;
  openPanel.prompt = @"Encode";
  
  [openPanel setAllowsMultipleSelection:YES];
  [openPanel setAllowedFileTypes:@[ @"wav", @"aif", @"aiff" ]];
  
  [openPanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
    if (result == NSFileHandlingPanelOKButton) {
      [self.delegate performFileOpenOperation:openPanel];
    } else if (result == NSFileHandlingPanelCancelButton) {
      
    }
  }];
}

#pragma mark - NSDragOperation

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
  if ((NSDragOperationGeneric & sender.draggingSourceOperationMask) == NSDragOperationGeneric) {
    return NSDragOperationGeneric;
  }
  
  return NSDragOperationNone;
}

//- (NSDragOperation)draggingUpdated:(id<NSDraggingInfo>)sender {
//  return NSDragOperationGeneric;
//}
//
//- (void)draggingExited:(id<NSDraggingInfo>)sender {
//  
//}

- (BOOL)prepareForDragOperation:(id<NSDraggingInfo>)sender {
  return YES;
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender {
  if ([self.delegate respondsToSelector:@selector(performDropzoneDragOperation:)]) {
    [self.delegate performDropzoneDragOperation:sender];
    return YES;
  }
  
  return NO;
}

- (void)concludeDragOperation:(id<NSDraggingInfo>)sender {
}

@end
