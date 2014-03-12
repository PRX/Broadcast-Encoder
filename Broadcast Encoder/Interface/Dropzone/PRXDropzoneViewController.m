//
//  PRXDropzoneViewController.m
//  Broadcast Encoder
//
//  Created by Christopher Kalafarski on 3/12/14.
//  Copyright (c) 2014 PRX. All rights reserved.
//

#import "PRXDropzoneViewController.h"

@interface PRXDropzoneViewController ()

@end

@implementation PRXDropzoneViewController

- (void)setView:(NSView *)view {
  [super setView:view];
  
  if ([view isKindOfClass:PRXDropzoneView.class]) {
    PRXDropzoneView *dropzoneView = (PRXDropzoneView *)view;
    dropzoneView.delegate = self;
  }
}

#pragma mark - PRXDropzoneViewDelegate

- (void)performDropzoneDragOperation:(id<NSDraggingInfo>)sender {
  NSLog(@"%@", sender);
}

@end
