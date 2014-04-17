//
//  PRXAppDelegate.m
//  Broadcast Encoder
//
//  Created by Christopher Kalafarski on 3/12/14.
//  Copyright (c) 2014 PRX. All rights reserved.
//

#import "PRXAppDelegate.h"
#import "PRXDropzoneViewController.h"

@interface PRXAppDelegate ()

@property (retain) PRXDropzoneViewController *dropzoneViewController;

@end

@implementation PRXAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  NSApplication *application = aNotification.object;

  self.dropzoneViewController = [[PRXDropzoneViewController alloc] initWithNibName:@"PRXDropzoneView" bundle:nil];
  
  NSWindow *window = application.windows.firstObject;
  [window.contentView addSubview:self.dropzoneViewController.view];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
  return YES;
}

@end
