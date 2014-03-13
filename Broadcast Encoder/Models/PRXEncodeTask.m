//
//  PRXEncoder.m
//  Broadcast Encoder
//
//  Created by Christopher Kalafarski on 3/12/14.
//  Copyright (c) 2014 PRX. All rights reserved.
//

#import "PRXEncoder.h"
#import "audio_wave.h"
#import "twolame.h"

#define MP2BUFSIZE		(16384)
#define AUDIOBUFSIZE	(9216)

@interface PRXEncoder () {
  twolame_options *encodeOptions;
  
  short int *pcmaudio;
  unsigned char *mp2buffer;
  
  wave_info_t *wave_info;
  
  FILE *outfile;
  
  int num_samples;
  int mp2fill_size;
  int frames;
}


@end

@implementation PRXEncoder

+ (instancetype)defaultEncoder {
  static dispatch_once_t pred;
  static id instance = nil;
  
  dispatch_once(&pred, ^{
    if (!instance) {
      instance = self.new;
    }
  });
  
  return instance;
}

- (void)encodeFileAtPath:(NSString *)path {
  NSLog(@"%@", path);
  
  if ((pcmaudio = (short *) calloc(AUDIOBUFSIZE, sizeof(short))) == NULL) {
    fprintf(stderr, "pcmaudio alloc failed\n");
    exit(99);
  }
  
  if ((mp2buffer = (unsigned char *) calloc(MP2BUFSIZE, sizeof(unsigned char))) == NULL) {
    fprintf(stderr, "mp2buffer alloc failed\n");
    exit(99);
  }
  
  printf("Using libtwolame version %s.\n", get_twolame_version());
  encodeOptions = twolame_init();
  
  if ((wave_info = wave_init(path.UTF8String)) == NULL) {
    fprintf(stderr, "Not a recognised WAV file.\n");
    exit(99);
  }
  
  // Use sound file to over-ride preferences for
  // mono/stereo and sampling-frequency
  twolame_set_num_channels(encodeOptions, wave_info->channels);
  if (wave_info->channels == 1) {
    twolame_set_mode(encodeOptions, TWOLAME_MONO);
  } else {
    twolame_set_mode(encodeOptions, TWOLAME_STEREO);
  }
  
  /* Set the input and output sample rate to the same */
  twolame_set_in_samplerate(encodeOptions, wave_info->samplerate);
  twolame_set_out_samplerate(encodeOptions, wave_info->samplerate);
  
  /* Set the bitrate to 192 kbps */
  twolame_set_bitrate(encodeOptions, 192);
  
  /* initialise twolame with this set of options */
  if (twolame_init_params(encodeOptions) != 0) {
    fprintf(stderr, "Error: configuring libtwolame encoder failed.\n");
    exit(99);
  }
  
  /* Open the output file for the encoded MP2 data */
  NSString *outputPath = @"/Users/farski/Desktop/foo.mp2";
  
  if ((outfile = fopen(outputPath.UTF8String, "wb")) == 0) {
    fprintf(stderr, "error opening output file %s\n", outputPath.UTF8String);
    exit(99);
  }
  
  // Read num_samples of audio data *per channel* from the input file
  while ((num_samples = wave_get_samples(wave_info, pcmaudio, AUDIOBUFSIZE)) != 0) {
    
    // Encode the audio!
    mp2fill_size =
    twolame_encode_buffer_interleaved(encodeOptions, pcmaudio, num_samples, mp2buffer,
                                      MP2BUFSIZE);
    
    // Write the MPEG bitstream to the file
    fwrite(mp2buffer, sizeof(unsigned char), mp2fill_size, outfile);
    
    // Display the number of MPEG audio frames we have encoded
    frames += (num_samples / TWOLAME_SAMPLES_PER_FRAME);
    printf("[%04i]\r", frames);
    fflush(stdout);
  }
  
  /* flush any remaining audio. (don't send any new audio data) There should only ever be a max
   of 1 frame on a flush. There may be zero frames if the audio data was an exact multiple of
   1152 */
  mp2fill_size = twolame_encode_flush(encodeOptions, mp2buffer, MP2BUFSIZE);
  fwrite(mp2buffer, sizeof(unsigned char), mp2fill_size, outfile);
  
  
  twolame_close(&encodeOptions);
  free(pcmaudio);
  
  printf("\nFinished nicely.\n");
}

@end
