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
#import "SOXResampler.h"
#import "SOXResamplerTask.h"

@interface PRXDropzoneViewController : NSViewController <PRXDropzoneViewDelegate, TWLEncoderTaskDelegate, TWLEncoderDelegate, SOXResamplerDelegate, SOXResamplerTaskDelegate, NSUserNotificationCenterDelegate>

@end
