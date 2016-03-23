#!/usr/bin/sh
# -----
# Name: shapeshifter
# Autor: Mick (mick@threelions.ch)
# Date: 23-03-2016
# Version: 0.7.0
# -----

# -----
# Variables
# -----
VERSION="0.7.0"
CMD_FFMPEG="/opt/ffmpeg/ffmpeg"
CMD_NPROC=`which nproc`
THREADS=$((`$CMD_NPROC` - 1))
FORMAT=""
INPUTFILE=""
OUTPUTNAME=""
TITLE=""
AUTHOR=""
COMPATIBLEBRANDS=""
MAJORBRAND=""
MINORVERSION=""
PALETTE="/tmp/palette.png"
SCALE="720"
FRAMES="60"
VIDEOBITRATE=""

# -----
# display help
# -----
Usage() {
	echo "Usage: ${0##*/} [-hv] [-f FORMAT] [-r FRAMES] [-s SCALE] [-i FILE] [-o OUTPUT FILENAME] [-t TITLE] [-a ARTIST]..."
	echo "    -h                         display this help and exit"
	echo "    -f <all|h264|h265|vp8|vp9|ogg|gif> media formats"
	echo "    -r <number>                frames"
	echo "    -s <360|720|1080>          scale"
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
	while getopts "hvf:r:s:i:o:t:a:" opts; do
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
			r)
				FRAMES=$OPTARG
				;;
			s)
				SCALE=$OPTARG
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

# -----
# Start the different encoding commands
# -----
StartEncoding() {
	case $SCALE in
		"360")
			VIDEOBITRATE="3500k"
			;;
		"720")
			VIDEOBITRATE="7000k"
			;;
		"1080")
			VIDEOBITRATE="7000k"
			;;
		*)
			VIDEOBITRATE="7000k"
			;;
	esac

	case $FORMAT in
		"all")
			CreateVP8
			CreateH264
			;;
		"ogg")
			CreateOgg
			;;
		"vp8")
			CreateVP8
			;;
		"vp9")
			CreateVP9
			;;
		"h264")
			CreateH264
			;;
		"h265")
			CreateH265
			;;
		"gif")
				CreateGif
				;;
		*)
			echo "[!] Invalid option for media format: -$FORMAT" >&2
			exit 4
			;;
	esac
}

# -----
# .ogg | Theora
# based http://trac.ffmpeg.org/wiki/GuidelinesHighQualityAudio | http://trac.ffmpeg.org/wiki/TheoraVorbisEncodingGuide
# -----
CreateOgg() {
	$CMD_FFMPEG -y -threads $THREADS -i $INPUTFILE -c:v libtheora -r $FRAMES -vf scale=-1:$SCALE -b:v $VIDEOBITRATE -qscale:v 8 -c:a libopus -b:a 128k -f ogg -metadata title="$TITLE" -metadata author="$AUTHOR" -metadata compatible_brands="$COMPATIBLEBRANDS" -metadata major_brand="$MAJORBRAND" -metadata minor_version="$MINORVERSION" $OUTPUTNAME"_"$SCALE".ogg"
}

# -----
# .webm | VP9
# based on https://sites.google.com/a/webmproject.org/wiki/ffmpeg/vp9-encoding-guide
# -----
CreateVP9() {
	$CMD_FFMPEG -y -threads $THREADS -i $INPUTFILE -c:v libvpx-vp9 -r $FRAMES -b:v $VIDEOBITRATE -vf scale=-1:$SCALE -pass 1 -speed 4 -tile-columns 0 -frame-parallel 0 -g 9999 -aq-mode 0 -an -f webm /dev/null
	$CMD_FFMPEG -y -threads $THREADS -i $INPUTFILE -c:v libvpx-vp9 -r $FRAMES -b:v $VIDEOBITRATE -vf scale=-1:$SCALE -pass 2 -speed 1 -tile-columns 0 -frame-parallel 0 -auto-alt-ref 1 -lag-in-frames 25 -g 9999 -aq-mode 0 -c:a libopus -b:a 128k -f webm -metadata title="$TITLE" -metadata author="$AUTHOR" $OUTPUTNAME"_"$SCALE"_vp9.webm"
}

# -----
# .webm | VP8
# -----
CreateVP8() {
	$CMD_FFMPEG -y -threads $THREADS -i $INPUTFILE -c:v libvpx -r $FRAMES -b:v $VIDEOBITRATE -vf scale=-1:$SCALE -pass 1 -speed 4 -g 9999 -an -f webm /dev/null
	$CMD_FFMPEG -y -threads $THREADS -i $INPUTFILE -c:v libvpx -r $FRAMES -b:v $VIDEOBITRATE -vf scale=-1:$SCALE -pass 2 -speed 1 -auto-alt-ref 1 -lag-in-frames 25 -g 9999 -c:a libopus -b:a 128k -f webm -metadata title="$TITLE" -metadata author="$AUTHOR" $OUTPUTNAME"_"$SCALE".webm"
}

# -----
# .mp4 | h264
# based on https://www.virag.si/2012/01/web-video-encoding-tutorial-with-ffmpeg-0-9/ | https://trac.ffmpeg.org/wiki/Encode/H.264
# -----
CreateH264() {
	$CMD_FFMPEG -y -threads 0 -i $INPUTFILE -c:v libx264 -r $FRAMES -vprofile high -preset veryslow -b:v $VIDEOBITRATE -vf scale=-1:$SCALE -pass 1 -an -f mp4 /dev/null
	$CMD_FFMPEG -y -threads 0 -i $INPUTFILE -c:v libx264 -r $FRAMES -vprofile high -preset veryslow -b:v $VIDEOBITRATE -vf scale=-1:$SCALE -pass 2 -c:a libfdk_aac -b:a 192k -ar 44100 -strict experimental -metadata title="$TITLE" -metadata author="$AUTHOR" -f mp4 $OUTPUTNAME"_"$SCALE".mp4"
}

# -----
# .mp4 | h265
# based on https://trac.ffmpeg.org/wiki/Encode/H.265
# -----
CreateH265() {
	$CMD_FFMPEG -y -threads 0 -i $INPUTFILE -c:v libx265 -r $FRAMES -preset veryslow -b:v $VIDEOBITRATE  -vf scale=-1:$SCALE -pass 1 -an -f mp4 /dev/null
	$CMD_FFMPEG -y -threads 0 -i $INPUTFILE -c:v libx265 -r $FRAMES -preset veryslow -b:v $VIDEOBITRATE  -vf scale=-1:$SCALE -pass 2 -c:a libfdk_aac -b:a 192k -ar 44100 -strict experimental -metadata title="$TITLE" -metadata author="$AUTHOR" -f mp4 $OUTPUTNAME"_"$SCALE"_h265.mp4"
}

# -----
# .gif | GIF
# based on http://blog.pkh.me/p/21-high-quality-gif-with-ffmpeg.html
# -----
CreateGif() {
	$CMD_FFMPEG -y -i $INPUTFILE -vf "fps=15,scale=700:-1:flags=lanczos,palettegen" $PALETTE
	$CMD_FFMPEG -y -i $INPUTFILE -i $PALETTE -lavfi "fps=15,scale=700:-1:flags=lanczos [x]; [x][1:v] paletteuse" $OUTPUTNAME".gif"
}

# -----
# Main
# -----
CheckParams $@
StartEncoding
