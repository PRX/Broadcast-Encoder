//
//  TWLEncoder.m
//  Broadcast Encoder
//
//  Created by Christopher Kalafarski on 3/12/14.
//  Copyright (c) 2014 PRX. All rights reserved.
//


#import "TWLEncoder_private.h"
#import "TWLEncoderTask_private.h"
#import "TWLEncoderTaskOperation.h"
#import "TWLEncoderConfiguration.h"
#import "TWLEncoderError.h"

NSString * const TWLEncoderErrorDomain = @"TWLEncoderErrorDomain";

@implementation TWLEncoder

@synthesize operationQueue = _operationQueue;

#pragma mark - Initializers
#pragma mark Public

+ (instancetype)sharedEncoder {
  static dispatch_once_t pred;
  static id instance = nil;
  
  dispatch_once(&pred, ^{
    if (!instance) {
      instance = self.new;
    }
  });
  
  return instance;
}

+ (instancetype)encoderWithConfiguration:(TWLEncoderConfiguration *)configuration {
  return [self encoderWithConfiguration:configuration delegate:nil operationQueue:nil];
}

+ (instancetype)encoderWithConfiguration:(TWLEncoderConfiguration *)configuration delegate:(id<TWLEncoderDelegate>)delegate operationQueue:(NSOperationQueue *)queue {
  return [[self alloc] initWithConfiguration:configuration delegate:delegate operationQueue:queue];
}

#pragma mark Private

- (instancetype)initWithConfiguration:(TWLEncoderConfiguration *)configuration {
  return [self initWithConfiguration:configuration delegate:nil operationQueue:nil];
}

- (instancetype)initWithConfiguration:(TWLEncoderConfiguration *)configuration delegate:(id<TWLEncoderDelegate>)delegate operationQueue:(NSOperationQueue *)queue {
  self = [super init];
  if (self) {
    _configuration = configuration;
#warning should be a copy
    _immutableConfiguration = configuration;
    _operationQueue = queue;
    _delegate = delegate;
  }
  return self;
}

#pragma mark - TwoLAME Encoder

- (twolame_options *)encoderOptionsWithSFInfo:(SF_INFO)sfinfo {
  NSError *error;
  twolame_options *options = twolame_init();
  
  if (options == NULL) {
    NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: @"Encoding was unsuccessful.",
                                NSLocalizedFailureReasonErrorKey: @"Could not initialize encoder.",
                                NSLocalizedRecoverySuggestionErrorKey: @"This is an internal error." };
    error = [NSError errorWithDomain:TWLEncoderErrorDomain code:TWLEncoderErrorCannotInitialize userInfo:userInfo];
    
    [self didBecomeInvalidWithError:error];
    
    return NULL;
  }
  
  twolame_set_num_channels(options, sfinfo.channels);
  twolame_set_in_samplerate(options, sfinfo.samplerate);
  
  TWLEncoderConfiguration *config = self.immutableConfiguration;
  
  twolame_set_copyright(options, config.markAsCopyright);
  twolame_set_original(options, config.markAsOriginal);
  twolame_set_error_protection(options, config.protect);
  twolame_set_energy_levels(options, config.energy);
  
  twolame_set_bitrate(options, (int)config.kilobitrate);

  if (config.padding) {
    twolame_set_padding(options, TWOLAME_PAD_ALL);
  } else {
    twolame_set_padding(options, TWOLAME_PAD_NO);
  }
  
  if (config.variableBitrate) {
    twolame_set_VBR(options, TRUE);
  }
  
  if (config.variableBitrateLevel) {
    twolame_set_VBR(options, TRUE);
    twolame_set_VBR_level(options, config.variableBitrateLevel.floatValue);
  }
  
  switch (config.outputMode) {
    case TWLEncoderOutputModeAuto:
      twolame_set_mode(options, TWOLAME_AUTO_MODE);
      break;
    case TWLEncoderOutputModeMono:
      twolame_set_mode(options, TWOLAME_MONO);
      break;
    case TWLEncoderOutputModeStereo:
      twolame_set_mode(options, TWOLAME_STEREO);
      break;
    case TWLEncoderOutputModeJointStereo:
      twolame_set_mode(options, TWOLAME_JOINT_STEREO);
      break;
    case TWLEncoderOutputModeDualChannel:
      twolame_set_mode(options, TWOLAME_DUAL_CHANNEL);
      break;
    default:
      break;
  }
  
  switch (config.deemphasis) {
    case TWLEncoderEmphasisNone:
      twolame_set_emphasis(options, TWOLAME_EMPHASIS_N);
      break;
    case TWLEncoderEmphasisC:
      twolame_set_emphasis(options, TWOLAME_EMPHASIS_C);
      break;
    case TWLEncoderEmphasis5:
      twolame_set_emphasis(options, TWOLAME_EMPHASIS_5);
      break;
    default:
      break;
  }
  
  twolame_print_config(options);
  
  if (twolame_init_params(options) != 0) {
    NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: @"Encoding was unsuccessful.",
                                NSLocalizedFailureReasonErrorKey: @"Could not initialize encoder.",
                                NSLocalizedRecoverySuggestionErrorKey: @"Configuring TwoLAME with these options failed." };
    error = [NSError errorWithDomain:TWLEncoderErrorDomain code:TWLEncoderErrorCannotInitialize userInfo:userInfo];
    
    [self didBecomeInvalidWithError:error];
    
    return NULL;
  }
  
  return options;
}

#pragma mark - Operation Queue

- (NSOperationQueue *)operationQueue {
  if (!_operationQueue) {
    _operationQueue = [[NSOperationQueue alloc] init];
    _operationQueue.name = @"TWLEncoderDefaultOperationQueue";
  }
  
  return _operationQueue;
}

- (void)encodeTask:(TWLEncoderTask *)task {
  if (!self.isInvalid) {
    TWLEncoderTaskOperation *operation;
    operation = [TWLEncoderTaskOperation operationWithTask:task];
    
    [self.operationQueue addOperation:operation];
  }
}

#pragma mark - Task Creation

- (TWLEncoderTask *)taskWithURL:(NSURL *)url {
  if (!self.isInvalid) {
    id taskDelegate;
    
    if ([self.delegate conformsToProtocol:@protocol(TWLEncoderTaskDelegate)]) {
      taskDelegate = self.delegate;
    }
    
    TWLEncoderTask *task = [[TWLEncoderTask alloc] initWithURL:url encoder:self delegate:taskDelegate];
    return task;
  }
  
  return nil;
}

#pragma mark - Delegate Notification

- (void)didBecomeInvalidWithError:(NSError *)error {
  self.isInvalid = YES;
  
  if ([self.delegate respondsToSelector:@selector(encoder:didBecomeInvalidWithError:)]) {
    [self.delegate encoder:self didBecomeInvalidWithError:error];
  }
}

- (void)didFinishEncodingTask:(TWLEncoderTask *)task toURL:(NSURL *)location {
  [self.delegate encoder:self task:task didFinishEncodingToURL:location];
#warning clean up temp file once delegate returns
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
  TWLEncoder *copy = self.class.new;
  
  copy->_configuration = self.immutableConfiguration.copy;
  copy->_immutableConfiguration = self.immutableConfiguration.copy;
  
  copy.isInvalid = self.isInvalid;
  
  copy.encoderDescription = self.encoderDescription.copy;
  
  copy->_delegate = self.delegate;
  copy->_operationQueue = self.operationQueue.copy;
  
  return copy;
}

@end
