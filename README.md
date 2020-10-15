# shapeshifter

A video converter based on ffmpeg.

## Introduction

The goal of shapeshifter is to generate high quality videos for the integration into websites. For each supported media format/codec, settings are defined that prefer quality over encoding speed.

Currently the following media formats are supported:

* H.264
* H.265
* VP8
* VP9
* Theora/Ogg
* AV1
* Gif 

## How to run

For encoding, scaling, frame rate, and medium format can be defined by using parameters. It is also possible to set the artist and the title of the movie.

```bash
Usage: shapeshifter.sh [-hv] [-f FORMAT] [-r FRAMES] [-s SCALE] [-i FILE] [-o OUTPUT FILENAME] [-t TITLE] [-a ARTIST]...
    -h                                        display this help and exit
    -f <web|h264|h265|av1|vp8|vp9|ogg|gif>    media formats
    -r <number>                               frames
    -s <360|720|1080>                         scale
    -i <file>                                 input file
    -o <name>                                 output file name (without extension)
    -t <name>                                 title of the film
    -a <name>                                 name of the artist
    -v                                        display version
```
