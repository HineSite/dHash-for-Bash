#!/bin/bash

# summary: Converts an image to grayscale then scales the image.
# arg1: Path to the image for which the dHash should be created.
# returns: Returns a list of pixel data in the following format: "X,Y,DEC X,Y,DEC"
#   Where "X,Y" is the xy coordinates of the pixel and "DEC" is the decimal value of the color.
function fun_convertImage {
    local pixels=$(convert "${1}" -quality 100 -colorspace Gray -scale 9x8\! - | convert - sparse-color:)

    # ImageMagick returns the pixel data in this format: "0,0,gray(188) 1,0,gray(185)"
    # This is a space separated list of pixel data. The pixel data is a comma separated list
    #   where the first and second parameters are the x,y coordinates of the pixel, and
    #   the third is the decimal pixel value wrapped in gray(x).

    # The problem is, there are different kinds of grayscale. For example, when using FFMPEG
    #   to produce grayscale images using the format=gray VF filter, the results are gray,
    #   but I still end up with three different values for RGB.

    # If the data is not recognized as grayscale by ImageMagick, the third parameter might
    #   contain rgb information. In my testing this results in an "srgb" parameter
    #   (e.g. X,Y,srgb(162,140,116)) as opposed to a "gray" parameter (e.g. X,Y,gray(172)).

    # The output for a gif also ends up as srgb with RGB being all the same value.
    #   I assume this is a bug in ImageMagick?

    # Here I assume the RGB values are close enough to each other that I can ignore R and B?
    pixels=$(echo "${pixels}" | sed -r -e 's/[a-zA-Z\(\)]|\([0-9]{1,3},[0-9]{1,3},//g')

    echo "${pixels}"
}


# summary: Gets the pixel data from an image that is already 9x8 and in grayscale. Note: there
#   are no safety checks here...
# arg1: Path to the image for which the dHash should be created.
# returns: Returns a list of pixel data in the following format: "X,Y,DEC X,Y,DEC"
#   Where "X,Y" is the xy coordinates of the pixel and "DEC" is the decimal value of the color.
function fun_getPixelData {
    # See fun_convertImage for notes

    local pixels=$(convert "${1}" sparse-color:)
    pixels=$(echo "${pixels}" | sed -r -e 's/[a-zA-Z\(\)]|\([0-9]{1,3},[0-9]{1,3},//g')

    echo "${pixels}"
}


# summary: Parses the Image Magick pixel data and forms a string of dHash bits.
#   A "1" indicates that P[x] < P[x+1] with the bits set from left to right, top to bottom.
# arg1: Image Magick pixel data formatted in the following format: 0,0,gray(188) 1,0,gray(185)
# returns: A string of bits representing the dHash
function fun_getDhashBits {
    local pixels=($1)
    local bits=""
    local hash=""
    local pixParts=[]
    local pixValue=""
    local lastValue=0
    local pixel=""

    for pixel in "${pixels[@]}"
    do
        # Split the pixel into its parts comma separated parts and grab the value
        IFS=',' read -r -a pixParts <<< "${pixel}"
        pixValue=${pixParts[2]}

        # If this is the start of a row, reset the lastValue and continue.
        if [ ${pixParts[0]} -eq 0 ]
        then
            # This prevents the pixel at the end of the row from being compared to the
            #   pixel at the start of the next row.

            lastValue=${pixValue}
            continue
        fi

        if [ ${lastValue} -lt ${pixValue} ]
        then
            bits="1${bits}"
        else
            bits="0${bits}"
        fi

        lastValue=${pixValue}
    done

    echo "${bits}"
}


# summary: Converts the dHash bits into base16 pairs. Note: this will fail if bits are not
#   evenly divisible by 16!
# arg1: A string of dHash bits
# returns: The base16 hash of the dHash bits
function fun_convertBitsToBase16 {
    local bits="${1}"
    local i=0
    local hash=""

    while [ $i -lt ${#bits} ]
    do
        # I'm doing this in 16 "bit" chunks to prevent integer overflow.
        hash+=$(printf '%X\n' $((2#${bits:i:16})))
        ((i += 16))
    done

    echo "${hash}"
}

# summary: Converts the base16 dHash into a string of bits.
# arg1: The base16 dHash to convert.
# returns: The dHash bits.
function fun_convertBase16ToBits {
    # "bc" requires the hex to be uppercase
    local hash=$(echo "${1}" | tr '[:lower:]' '[:upper:]')
    local bits=""
    local i=0

    while [ $i -lt ${#hash} ]
    do
        # I'm doing this in 16 "bit" chunks to prevent integer overflow.
        # The printf keeps the bit output padded to 16 bits.
        #   "bc" will convert "0x33 to "110011", but we need "00110011".
        bits+=$(printf "%016d" $(echo "ibase=16;obase=2;${hash:i:4}" | bc))
        ((i += 4))
    done

    echo "${bits}"
}

# summary: Calculates the hamming distance between to dHash "bit" strings. Note: both bit strings
#    must be the same length!
# arg1: The first string of bits to compare.
# arg2: The second string of bits to compare.
# returns: The hamming distance.
function fun_calculateHammingDistance {
    local leftBits="${1}"
    local rightBits="${2}"
    local ham=0
    local i=0

    while [ $i -lt ${#leftBits} ]
    do
        if [ "${leftBits:$i:1}" != "${rightBits:$i:1}" ]
        then
            ((ham += 1))
        fi

        ((i += 1))
    done

    echo "${ham}"
}

