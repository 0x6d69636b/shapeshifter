#! /bin/sh

# -----
# Title:	shapeshifter
# Date:		2014/07/09
# Version:	0.4.2
# -----

# --
# Variables
#
FFMPEG="/opt/ffmpeg/ffmpeg"
NPROC=`which nproc`
THREADS=$((`$NPROC` - 1))
INPUTMOVIE=$(pwd)/$2
OUTPUTNAME=$(pwd)/$3
TITLE=$4
AUTHOR=$5
COMPATIBLEBRANDS=""
MAJORBRAND=""
MINORVERSION=""

# --
# .ogg | Theora
# based http://trac.ffmpeg.org/wiki/GuidelinesHighQualityAudio | http://trac.ffmpeg.org/wiki/TheoraVorbisEncodingGuide
#
createOgg()
{	
	# 720p	
	$FFMPEG -y -threads $THREADS -i $INPUTMOVIE -metadata title="$TITLE" -metadata author="$AUTHOR" -metadata compatible_brands="$COMPATIBLEBRANDS" -metadata major_brand="$MAJORBRAND" -metadata minor_version="$MINORVERSION" -c:v libtheora -vf scale=-1:720 -b:v 7000k -qscale:v 8 -c:a libopus -b:a 256k $OUTPUTNAME.ogg
	
	# 360p
	$FFMPEG -y -threads $THREADS -i $INPUTMOVIE -metadata title="$TITLE" -metadata author="$AUTHOR" -metadata compatible_brands="$COMPATIBLEBRANDS" -metadata major_brand="$MAJORBRAND" -metadata minor_version="$MINORVERSION" -c:v libtheora -vf scale=-1:360 -b:v 7000k -qscale:v 8 -c:a libopus -b:a 256k $OUTPUTNAME-small.ogg
}

# --
# .webm | VPX8
# based on https://www.virag.si/2012/01/webm-web-video-encoding-tutorial-with-ffmpeg-0-9/ | http://www.webmproject.org/docs/encoder-parameters/ | http://trac.ffmpeg.org/wiki/Encode/VP8
#
createWebm()
{
	# 720p
	$FFMPEG -y -threads $THREADS -i $INPUTMOVIE -metadata title="$TITLE" -metadata author="$AUTHOR" -c:v libvpx -b:v 7000k -vf scale=-1:720 -quality best -pass 1 -an -f webm $OUTPUTNAME.webm
	$FFMPEG -y -threads $THREADS -i $INPUTMOVIE -metadata title="$TITLE" -metadata author="$AUTHOR" -c:v libvpx -b:v 7000k -vf scale=-1:720 -quality best -pass 2 -c:a libvorbis -b:a 256k -f webm $OUTPUTNAME.webm
	
	# 360p
	$FFMPEG -y -threads $THREADS -i $INPUTMOVIE -metadata title="$TITLE" -metadata author="$AUTHOR" -c:v libvpx -b:v 3500k -vf scale=-1:360 -quality best -pass 1 -an -f webm /dev/null
	$FFMPEG -y -threads $THREADS -i $INPUTMOVIE -metadata title="$TITLE" -metadata author="$AUTHOR" -c:v libvpx -b:v 3500k -vf scale=-1:360 -quality best -pass 2 -c:a libvorbis -b:a 256k -f webm $OUTPUTNAME-small.webm
}

# --
# .mp4 | h264
# based on https://www.virag.si/2012/01/web-video-encoding-tutorial-with-ffmpeg-0-9/ | https://trac.ffmpeg.org/wiki/Encode/H.264
#
createMp4()
{
	# 720p
	$FFMPEG -y -threads 0 -i $INPUTMOVIE -metadata title="$TITLE" -metadata author="$AUTHOR" -c:v libx264 -vprofile high -preset veryslow -b:v 7000k -vf scale=-1:720 -pass 1 -an -f mp4 /dev/null
	$FFMPEG -y -threads 0 -i $INPUTMOVIE -metadata title="$TITLE" -metadata author="$AUTHOR" -c:v libx264 -vprofile high -preset veryslow -b:v 7000k -vf scale=-1:720 -pass 2 -c:a libfdk_aac -b:a 256k -ar 44100 -strict experimental -f mp4 $OUTPUTNAME.mp4
	
	# 360p
	$FFMPEG -y -threads 0 -i $INPUTMOVIE -metadata title="$TITLE" -metadata author="$AUTHOR" -c:v libx264 -vprofile high -preset veryslow -b:v 3500k -vf scale=-1:360 -pass 1 -an -f mp4 /dev/null
	$FFMPEG -y -threads 0 -i $INPUTMOVIE -metadata title="$TITLE" -metadata author="$AUTHOR" -c:v libx264 -vprofile high -preset veryslow -b:v 3500k -vf scale=-1:360 -pass 2 -c:a libfdk_aac -b:a 256k -ar 44100 -strict experimental -f mp4 $OUTPUTNAME-small.mp4

	# 360p - legacy
	#$FFMPEG -y -threads 0 -i $INPUTMOVIE -metadata title="$TITLE" -metadata author="$AUTHOR" -vcodec libx264 -vprofile high -preset slower -vb 3500k -vf scale=-1:360 -pass 1 -an -f mp4 /dev/null
	#$FFMPEG -y -threads 0 -i $INPUTMOVIE -metadata title="$TITLE" -metadata author="$AUTHOR" -vcodec libx264 -vprofile high -preset slower -vb 3500k -vf scale=-1:360 -pass 2 -acodec aac -ab 128k -ar 44100 -strict experimental -f mp4 $OUTPUTNAME-legacy.mp4
}

# -- 
# read parameters
#
case $1 in
  "all"		) createOgg; createWebm; createMp4;;
  "ogg"		) createOgg;;
  "webm"	) createWebm;;
  "mp4"		) createMp4;;
  *			) echo "[*] syntax: $0 option (all, ogg, webm or mp4), inputfile, outputfilename, title, artist";; 
esac
