//
//  PRXDropzoneViewController.h
//  Broadcast Encoder
//
//  Created by Christopher Kalafarski on 3/12/14.
//  Copyright (c) 2014 PRX. All rights reserved.
//

@import Cocoa;

#import "PRXDropzoneView.h"
#import "TWLEncoderTask.h"
#import "TWLEncoder.h"

@interface PRXDropzoneViewController : NSViewController <PRXDropzoneViewDelegate, TWLEncoderTaskDelegate, TWLEncoderDelegate>

@end
