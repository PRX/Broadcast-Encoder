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

- (void)drawRect:(NSRect)dirtyRect {
  CGContextRef context = (CGContextRef) [[NSGraphicsContext currentContext] graphicsPort];
  CGContextSetRGBFillColor(context, 0.227,0.251,0.337,0.8);
  CGContextFillRect(context, NSRectToCGRect(dirtyRect));
}

#pragma mark - Mouse Events

- (void)mouseDown:(NSEvent *)theEvent {
  NSLog(@"click");
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
