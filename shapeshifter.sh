#!/usr/bin/bash
# -----
# Name: shapeshifter
# Autor: Mick (mick@threelions.ch)
# Date: 28-02-2016
# Version: 0.6.5
# -----

# -----
# Variables
# -----
VERSION="0.6.5"
CMD_FFMPEG="/opt/ffmpeg/ffmpeg"
CMD_NPROC=`which nproc`
THREADS=$((`$CMD_NPROC` - 1))
FORMAT=
INPUTFILE=
OUTPUTNAME=
TITLE=
AUTHOR=
COMPATIBLEBRANDS=""
MAJORBRAND=""
MINORVERSION=""
PALETTE="/tmp/palette.png"

# -----
# display help
# -----
Usage() {
	echo "Usage: ${0##*/} [-hv] [-f FORMAT] [-i FILE] [-o OUTPUT FILENAME] [-t TITLE] [-a ARTIST]..."
	echo "    -h                         display this help and exit"
	echo "    -f <all|h264|h265|vp8|vp9|ogg|gif> media formats"
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

# -----
# Start the different encoding commands
# -----
StartEncoding() {
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
	# 720p
	$CMD_FFMPEG -y -threads $THREADS -i $INPUTFILE -c:v libtheora -vf scale=-1:720 -b:v 7000k -qscale:v 8 -c:a libopus -b:a 128k -f ogg -metadata title="$TITLE" -metadata author="$AUTHOR" -metadata compatible_brands="$COMPATIBLEBRANDS" -metadata major_brand="$MAJORBRAND" -metadata minor_version="$MINORVERSION" $OUTPUTNAME"_hd.ogg"
	# 360p
	$CMD_FFMPEG -y -threads $THREADS -i $INPUTFILE -c:v libtheora -vf scale=-1:360 -b:v 3500k -qscale:v 8 -c:a libopus -b:a 128k -f ogg -metadata title="$TITLE" -metadata author="$AUTHOR" -metadata compatible_brands="$COMPATIBLEBRANDS" -metadata major_brand="$MAJORBRAND" -metadata minor_version="$MINORVERSION" $OUTPUTNAME"_lq.ogg"
}

# -----
# .webm | VP9
# based on https://sites.google.com/a/webmproject.org/wiki/ffmpeg/vp9-encoding-guide
# -----
CreateVP9() {
	# 720p
	$CMD_FFMPEG -y -threads $THREADS -i $INPUTFILE -c:v libvpx-vp9 -b:v 7000k -vf scale=-1:720 -pass 1 -speed 4 -tile-columns 0 -frame-parallel 0 -g 9999 -aq-mode 0 -an -f webm /dev/null
	$CMD_FFMPEG -y -threads $THREADS -i $INPUTFILE -c:v libvpx-vp9 -b:v 7000k -vf scale=-1:720 -pass 2 -speed 1 -tile-columns 0 -frame-parallel 0 -auto-alt-ref 1 -lag-in-frames 25 -g 9999 -aq-mode 0 -c:a libopus -b:a 128k -f webm -metadata title="$TITLE" -metadata author="$AUTHOR" $OUTPUTNAME"_hd_vp9.webm"
	# 360p
	$CMD_FFMPEG -y -threads $THREADS -i $INPUTFILE -c:v libvpx-vp9 -b:v 3500k -vf scale=-1:360 -pass 1 -speed 4 -tile-columns 0 -frame-parallel 0 -g 9999 -aq-mode 0 -an -f webm /dev/null
	$CMD_FFMPEG -y -threads $THREADS -i $INPUTFILE -c:v libvpx-vp9 -b:v 3500k -vf scale=-1:360 -pass 2 -speed 1 -tile-columns 0 -frame-parallel 0 -auto-alt-ref 1 -lag-in-frames 25 -g 9999 -aq-mode 0 -c:a libopus -b:a 128k -f webm -metadata title="$TITLE" -metadata author="$AUTHOR" $OUTPUTNAME"_lq_vp9.webm"
}

# -----
# .webm | VP8
# -----
CreateVP8() {
	# 720p
	$CMD_FFMPEG -y -threads $THREADS -i $INPUTFILE -c:v libvpx -b:v 7000k -vf scale=-1:720 -pass 1 -speed 4 -tile-columns 0 -frame-parallel 0 -g 9999 -aq-mode 0 -an -f webm /dev/null
	$CMD_FFMPEG -y -threads $THREADS -i $INPUTFILE -c:v libvpx -b:v 7000k -vf scale=-1:720 -pass 2 -speed 1 -tile-columns 0 -frame-parallel 0 -auto-alt-ref 1 -lag-in-frames 25 -g 9999 -aq-mode 0 -c:a libopus -b:a 128k -f webm -metadata title="$TITLE" -metadata author="$AUTHOR" $OUTPUTNAME"_hd.webm"
	# 360p
	$CMD_FFMPEG -y -threads $THREADS -i $INPUTFILE -c:v libvpx -b:v 3500k -vf scale=-1:360 -pass 1 -speed 4 -tile-columns 0 -frame-parallel 0 -g 9999 -aq-mode 0 -an -f webm /dev/null
	$CMD_FFMPEG -y -threads $THREADS -i $INPUTFILE -c:v libvpx -b:v 3500k -vf scale=-1:360 -pass 2 -speed 1 -tile-columns 0 -frame-parallel 0 -auto-alt-ref 1 -lag-in-frames 25 -g 9999 -aq-mode 0 -c:a libopus -b:a 128k -f webm -metadata title="$TITLE" -metadata author="$AUTHOR" $OUTPUTNAME"_lq.webm"
}

# -----
# .mp4 | h264
# based on https://www.virag.si/2012/01/web-video-encoding-tutorial-with-ffmpeg-0-9/ | https://trac.ffmpeg.org/wiki/Encode/H.264
# -----
CreateH264() {
	# 720p
	$CMD_FFMPEG -y -threads 0 -i $INPUTFILE -c:v libx264 -vprofile high -preset veryslow -b:v 7000k -vf scale=-1:720 -pass 1 -an -f mp4 /dev/null
	$CMD_FFMPEG -y -threads 0 -i $INPUTFILE -c:v libx264 -vprofile high -preset veryslow -b:v 7000k -vf scale=-1:720 -pass 2 -c:a libfdk_aac -b:a 192k -ar 44100 -strict experimental -metadata title="$TITLE" -metadata author="$AUTHOR" -f mp4 $OUTPUTNAME"_hd.mp4"

	# 360p
	$CMD_FFMPEG -y -threads 0 -i $INPUTFILE -c:v libx264 -vprofile high -preset veryslow -b:v 3500k -vf scale=-1:360 -pass 1 -an -f mp4 /dev/null
	$CMD_FFMPEG -y -threads 0 -i $INPUTFILE -c:v libx264 -vprofile high -preset veryslow -b:v 3500k -vf scale=-1:360 -pass 2 -c:a libfdk_aac -b:a 192k -ar 44100 -strict experimental -metadata title="$TITLE" -metadata author="$AUTHOR" -f mp4 $OUTPUTNAME"_lq.mp4"
}

# -----
# .mp4 | h265
# based on https://trac.ffmpeg.org/wiki/Encode/H.265
# -----
CreateH265() {
	# 720p
	$CMD_FFMPEG -y -threads 0 -i $INPUTFILE -c:v libx265 -preset veryslow -b:v 7000k -vf scale=-1:720 -pass 1 -an -f mp4 /dev/null
	$CMD_FFMPEG -y -threads 0 -i $INPUTFILE -c:v libx265 -preset veryslow -b:v 7000k -vf scale=-1:720 -pass 2 -c:a libfdk_aac -b:a 192k -ar 44100 -strict experimental -metadata title="$TITLE" -metadata author="$AUTHOR" -f mp4 $OUTPUTNAME"_h265_hd.mp4"
	# 360p
	$CMD_FFMPEG -y -threads 0 -i $INPUTFILE -c:v libx265 -preset veryslow -b:v 3500k -vf scale=-1:360 -pass 1 -an -f mp4 /dev/null
	$CMD_FFMPEG -y -threads 0 -i $INPUTFILE -c:v libx265 -preset veryslow -b:v 3500k -vf scale=-1:360 -pass 2 -c:a libfdk_aac -b:a 192k -ar 44100 -strict experimental -metadata title="$TITLE" -metadata author="$AUTHOR" -f mp4 $OUTPUTNAME"_h265_lq.mp4"
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
