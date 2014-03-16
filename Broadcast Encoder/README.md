# Broadcast Encoder

I don't know how to link against SoX, sndfile, or TwoLAME the right way, 
so right now the paths the paths to them are hard coded in the build config
to the default homebrew install locations (for the current versions). If
you have them installed I assume this will run, but I'm sure there's a 
better way to do that.

If the Pods.xcconfig is regenerated, things will break

    -L"/usr/local/Cellar/two-lame/0.3.13/lib"  -ltwolame -L"/usr/local/Cellar/sox/14.4.1/lib" -lsox -L"/usr/local/Cellar/libsndfile/1.0.25/lib" -lsndfile

Need to figure out a better way to handle the progress bar when multiple
jobs are running.

Needs an icon and a pretty UI

Cancel button?

Alert the user before resamling?

Would like to get sox and TwoLAME built as .frameworks and available as cocoapods

Sox and twolame wrappers should also be cocoapods
