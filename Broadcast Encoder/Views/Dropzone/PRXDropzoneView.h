//
//  PRXDropzoneView.h
//  Broadcast Encoder
//
//  Created by Christopher Kalafarski on 3/12/14.
//  Copyright (c) 2014 PRX. All rights reserved.
//

@import Cocoa;

@protocol PRXDropzoneViewDelegate;

@interface PRXDropzoneView : NSView

@property (nonatomic, strong) id<PRXDropzoneViewDelegate> delegate;

@property (nonatomic, strong) IBOutlet NSTextField *textField;

@end

@protocol PRXDropzoneViewDelegate <NSObject>

- (void)performDropzoneDragOperation:(id<NSDraggingInfo>)sender;

@end
