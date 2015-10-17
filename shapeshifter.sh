#!/usr/bin/bash
# -----
# Name: shapeshifter
# Autor: Mick (mick@threelions.ch)
# Date: 17-10-2015
# Version:	0.5.0
# -----

# -----
# Variables
# -----
VERSION="0.5.0"
CMD_FFMPEG="/opt/ffmpeg/ffmpeg"
CMD_NPROC=`which nproc`
THREADS=$((`$CMD_NPROC` - 1))

FORMAT="all"
INPUTFILE=
OUTPUTNAME=
TITLE=
AUTHOR=
COMPATIBLEBRANDS=""
MAJORBRAND=""
MINORVERSION=""

# -----
# display help
# -----
Usage() {
	echo "Usage: ${0##*/} [-hv] [-f FORMAT] [-i FILE] [-o OUTPUT FILENAME] [-t TITLE] [-a ARTIST]..."
	echo "    -h                         display this help and exit"
	echo "    -f <all|h264|webm|ogg>     media formats"
	echo "    -i <file>                  input file"
	echo "    -o <name>                  output file name (without extension)"
	echo "    -t <name>                  title of the film"
	echo "    -a <name>                  name of the artist"
	echo "    -v                         display version"
	exit 0
}

# -----
# display version number
# -----
Version() {
	echo -e "${0##*/} version $VERSION"
	exit 0
}

# -----
# check if we got all needed parameters.
# based on http://wiki.bash-hackers.org/howto/getopts_tutorial
# -----
CheckParams() {
	while getopts "hvf:i:o:t:a:" opts; do
		case $opts in
			h)
				Usage
				exit 0
				;;
			v)
				Version
				exit 0
				;;
			f)
				FORMAT=$OPTARG
				;;
			i)
				INPUTFILE=$OPTARG
				;;
			o)
				OUTPUTNAME=$OPTARG
				;;
			t)
				TITLE=$OPTARG
				;;
			a)
				ARTIST=$OPTARG
				;;
			'?')
				Usage
				exit 1
				;;
		esac
	done

	if [[ -z $FORMAT ]] || [[ -z $INPUTFILE ]] || [[ -z $OUTPUTNAME ]]; then
		Usage
		exit 2
	fi
}

StartEncoding() {
	case $FORMAT in
		"all")
			CreateOgg
			CreateWebm
			CreateH264
			;;
		"ogg")
			CreateOgg
			;;
		"webm")
			CreateWebm
			;;
		"h264")
			CreateH264
			;;
		*)
			echo "[!] Invalid option for media format: -$FORMAT" >&2
			exit 4
			;;
	esac
}

# --
# .ogg | Theora
# based http://trac.ffmpeg.org/wiki/GuidelinesHighQualityAudio | http://trac.ffmpeg.org/wiki/TheoraVorbisEncodingGuide
#
CreateOgg() {
	# 720p
	$CMD_FFMPEG -y -threads $THREADS -i $INPUTFILE -metadata title="$TITLE" -metadata author="$AUTHOR" -metadata compatible_brands="$COMPATIBLEBRANDS" -metadata major_brand="$MAJORBRAND" -metadata minor_version="$MINORVERSION" -c:v libtheora -vf scale=-1:720 -b:v 7000k -qscale:v 8 -c:a libopus -b:a 256k $OUTPUTNAME.ogg

	# 360p
	$CMD_FFMPEG -y -threads $THREADS -i $INPUTFILE -metadata title="$TITLE" -metadata author="$AUTHOR" -metadata compatible_brands="$COMPATIBLEBRANDS" -metadata major_brand="$MAJORBRAND" -metadata minor_version="$MINORVERSION" -c:v libtheora -vf scale=-1:360 -b:v 7000k -qscale:v 8 -c:a libopus -b:a 256k $OUTPUTNAME-small.ogg
}

# --
# .webm | VPX8
# based on https://www.virag.si/2012/01/webm-web-video-encoding-tutorial-with-ffmpeg-0-9/ | http://www.webmproject.org/docs/encoder-parameters/ | http://trac.ffmpeg.org/wiki/Encode/VP8
#
CreateWebm() {
	# 720p
	$CMD_FFMPEG -y -threads $THREADS -i $INPUTFILE -metadata title="$TITLE" -metadata author="$AUTHOR" -c:v libvpx -b:v 7000k -vf scale=-1:720 -quality best -pass 1 -an -f webm $OUTPUTNAME.webm
	$CMD_FFMPEG -y -threads $THREADS -i $INPUTFILE -metadata title="$TITLE" -metadata author="$AUTHOR" -c:v libvpx -b:v 7000k -vf scale=-1:720 -quality best -pass 2 -c:a libvorbis -b:a 256k -f webm $OUTPUTNAME.webm

	# 360p
	$CMD_FFMPEG -y -threads $THREADS -i $INPUTFILE -metadata title="$TITLE" -metadata author="$AUTHOR" -c:v libvpx -b:v 3500k -vf scale=-1:360 -quality best -pass 1 -an -f webm /dev/null
	$CMD_FFMPEG -y -threads $THREADS -i $INPUTFILE -metadata title="$TITLE" -metadata author="$AUTHOR" -c:v libvpx -b:v 3500k -vf scale=-1:360 -quality best -pass 2 -c:a libvorbis -b:a 256k -f webm $OUTPUTNAME-small.webm
}

# --
# .mp4 | h264
# based on https://www.virag.si/2012/01/web-video-encoding-tutorial-with-ffmpeg-0-9/ | https://trac.ffmpeg.org/wiki/Encode/H.264
#
CreateH264() {
	# 720p
	$CMD_FFMPEG -y -threads 0 -i $INPUTFILE -metadata title="$TITLE" -metadata author="$AUTHOR" -c:v libx264 -vprofile high -preset veryslow -b:v 7000k -vf scale=-1:720 -pass 1 -an -f mp4 /dev/null
	$CMD_FFMPEG -y -threads 0 -i $INPUTFILE -metadata title="$TITLE" -metadata author="$AUTHOR" -c:v libx264 -vprofile high -preset veryslow -b:v 7000k -vf scale=-1:720 -pass 2 -c:a libfdk_aac -b:a 256k -ar 44100 -strict experimental -f mp4 $OUTPUTNAME.mp4

	# 360p
	$CMD_FFMPEG -y -threads 0 -i $INPUTFILE -metadata title="$TITLE" -metadata author="$AUTHOR" -c:v libx264 -vprofile high -preset veryslow -b:v 3500k -vf scale=-1:360 -pass 1 -an -f mp4 /dev/null
	$CMD_FFMPEG -y -threads 0 -i $INPUTFILE -metadata title="$TITLE" -metadata author="$AUTHOR" -c:v libx264 -vprofile high -preset veryslow -b:v 3500k -vf scale=-1:360 -pass 2 -c:a libfdk_aac -b:a 256k -ar 44100 -strict experimental -f mp4 $OUTPUTNAME-small.mp4

	# 360p - legacy
	#$CMD_FFMPEG -y -threads 0 -i $INPUTFILE -metadata title="$TITLE" -metadata author="$AUTHOR" -vcodec libx264 -vprofile high -preset slower -vb 3500k -vf scale=-1:360 -pass 1 -an -f mp4 /dev/null
	#$CMD_FFMPEG -y -threads 0 -i $INPUTFILE -metadata title="$TITLE" -metadata author="$AUTHOR" -vcodec libx264 -vprofile high -preset slower -vb 3500k -vf scale=-1:360 -pass 2 -acodec aac -ab 128k -ar 44100 -strict experimental -f mp4 $OUTPUTNAME-legacy.mp4
}

# -----
# main
# -----
CheckParams $@
StartEncoding
