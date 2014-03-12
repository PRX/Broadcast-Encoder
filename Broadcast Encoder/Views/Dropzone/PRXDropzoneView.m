//
//  PRXDropzoneView.m
//  Broadcast Encoder
//
//  Created by Christopher Kalafarski on 3/12/14.
//  Copyright (c) 2014 PRX. All rights reserved.
//

#import "PRXDropzoneView.h"

@implementation PRXDropzoneView

- (id)initWithFrame:(NSRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    [self registerForDraggedTypes:@[ NSColorPboardType, NSFilenamesPboardType ]];
  }
  return self;
}

- (void)awakeFromNib {
  [super awakeFromNib];
}

- (void)drawRect:(NSRect)dirtyRect {
  // Fill in background Color
  CGContextRef context = (CGContextRef) [[NSGraphicsContext currentContext] graphicsPort];
  CGContextSetRGBFillColor(context, 0.227,0.251,0.337,0.8);
  CGContextFillRect(context, NSRectToCGRect(dirtyRect));
}

#pragma mark - NSDragOperation

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
  NSLog(@"%@", sender);
  
  return NSDragOperationNone;
}

- (NSDragOperation)draggingUpdated:(id<NSDraggingInfo>)sender {
  return NSDragOperationNone;
}

- (void)draggingExited:(id<NSDraggingInfo>)sender {
  
}

- (BOOL)prepareForDragOperation:(id<NSDraggingInfo>)sender {
  return NO;
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender {
  return NO;
}

- (void)concludeDragOperation:(id<NSDraggingInfo>)sender {
  
}

@end
