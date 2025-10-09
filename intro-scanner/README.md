# Intro Scanner


### Overview
The objective is to scan a television series for intro and outro credits, mark their timestamp, and produce chapter information for them.

The process is relatively straight forward. First, FFMPEG is used to convert each episode into a series of images that can be directly used to create the pHash (grayscaled and resized). Next, the pHash hashes of two episodes are compared to  look for similar sequences in each episode. If there is enough confidence in the identity of the sequences, a chapter marker is produced.

### Current status
This script is still very much a work in progress. Right now, the intro sequence for the first episode is manually entered, via its time (in seconds). This known intro sequence is then looked for in the other episodes. This is working, but it is rather slow and not well written.

### Performance
FFMPEG is doing a fantastic job outputting 24 FPS  in about 2 minutes for a 24 minute episode. However, to open the image with ImageMagick, read the pixels, and calculate the hash takes about 7 minutes per episode when dealing with 24 FPS.

Scanning an episode for a known intro is done nearly in real time. So, if you are you are only searching for intros and they are typically within the first 2 minutes of the show, it is not bad. But if you want to search for an interlude in the middle of the episode, you could be waiting 12 minutes.

The easiest speedup I've seen so far is to generate frames at 12 FPS instead of 24. This literally doubled the speed and it still had very high accuracy. Switching to 12 FPS means that every other frame is captured. Since the difference from one frame to the next is generally quite minimal, it makes sense that the pHash would handle this. However, a frame rate less than 6 FPS will likely not work.


