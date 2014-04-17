//
//  PRXDropzoneView.h
//  Broadcast Encoder
//
//  Created by Christopher Kalafarski on 3/12/14.
//  Copyright (c) 2014 PRX. All rights reserved.
//

@import Cocoa;

@protocol PRXDropzoneViewDelegate;

@interface PRXDropzoneView : NSView <NSDraggingDestination>

@property (nonatomic, assign) id<PRXDropzoneViewDelegate> delegate;

@property (nonatomic, strong) IBOutlet NSTextField *textField;
@property (nonatomic, strong) IBOutlet NSTextField *versionTextField;
@property (nonatomic, strong) IBOutlet NSProgressIndicator *progressIndicator;

@property (nonatomic, strong) IBOutlet NSButton *closeButton;
@property (nonatomic, strong) IBOutlet NSButton *helpButton;

@end

@protocol PRXDropzoneViewDelegate <NSObject>

- (void)performFileOpenOperation:(id)sender;
- (void)performDropzoneDragOperation:(id<NSDraggingInfo>)sender;

@end
