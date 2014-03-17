//
//  PRXStaticImageView.m
//  Broadcast Encoder
//
//  Created by Christopher Kalafarski on 3/17/14.
//  Copyright (c) 2014 PRX. All rights reserved.
//

#import "PRXStaticImageView.h"

@implementation PRXStaticImageView

- (void)awakeFromNib {
  [super awakeFromNib];
  
  [self unregisterDraggedTypes];
}

@end
