//
//  PRXAppDelegate.m
//  Broadcast Encoder
//
//  Created by Christopher Kalafarski on 3/12/14.
//  Copyright (c) 2014 PRX. All rights reserved.
//

#import "PRXAppDelegate.h"
#import "PRXDropzoneViewController.h"

@implementation PRXAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  NSApplication *application = aNotification.object;

  PRXDropzoneViewController *dropzoneViewController;
  dropzoneViewController = [[PRXDropzoneViewController alloc] initWithNibName:@"PRXDropzoneView" bundle:nil];
  
  NSWindow *window = application.windows.firstObject;
  [window.contentView addSubview:dropzoneViewController.view];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
  return YES;
}

@end
