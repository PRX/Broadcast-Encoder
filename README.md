# Broadcast Encoder

![Demo](https://dl.dropboxusercontent.com/u/1400235/prx-brenc-demo.png)

This is a project maintained by [PRX](http://www.prx.org) designed to help with encoding broadcast-ready MP2 audio files suitable for distributing to radio stations.

The Broacast Encoder application is designed to work with standard PCM files, usually either WAV or AIFF. The specification generally used for broadcast-ready MP2 files is:

- Sample rate: **44100 Hz**
- Channels: **Mono or Stereo (including Joint Stereo)**
- Bit rate: **128 kbps per channel**

This application can transcode from a number of different PCM encodings to create MP2s that meet this standard. Not all PCM data, though, will work properly. The input file *must* be 16 bit, for example. The encoder does not support any other bit depth. It will support files that have a native sample rate other than 44100 Hz, though, insofar as it will do additional processing to meet the broadcast standard.

In order to avoid any unexpected results, the input files should be 44.1 kHz, 16 bit, mono/stereo, WAV/AIFF files whenever possible.

### System Requirements

The Broadcast Encoder is designed to work with Mac OS X 10.7 and later.

### Contributing

PRX maintains the Broadcast Encoder as an open source project and welcomes contributions from the community.

Transoding is handled with the help of several third-party libraries:

- **[libsndfile](http://www.mega-nerd.com/libsndfile/)** 
- **[The SoX Resampler library](http://sourceforge.net/projects/soxr/)**
- **[TwoLAME](http://www.twolame.org/)**

We have created static libraries for each of these projects, and packaged them as individual [CocoaPods](http://cocoapods.org/). We also maintain Objective-C wrappers for **[TwoLAME](https://github.com/PRX/TWLEncoder)** and the **[SoX Resampler](https://github.com/PRX/SOXResampler)**, which provide a standard interface for configuring and queueing jobs with their respective libraries.

The Broadcast Encoder application is itself only a lightweight wrapper around these five external dependencies. If you encounter issues with resampling or encoding when using the Broadcast Encoder, the cause is likely is one of these other projects. They are also all open source, so contributions or discussions are encouraged.