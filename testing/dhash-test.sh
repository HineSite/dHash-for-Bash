#!/bin/bash

. ../dhash.sh

# These are precalculated values
declare -A values
values["mustache.jpg"]=0
values["wash-out.jpg"]=0
values["meme.jpg"]=0
values["autographed.jpg"]=1
values["full.jpg"]=1
values["sweater.jpg"]=1
values["wallpaper.jpg"]=1
values["compressed-20.jpg"]=0
values["compressed-50.jpg"]=0
values["test-image.jpg"]=0
values["crop-25.jpg"]=0
values["scale-80.jpg"]=0
values["rot-90.jpg"]=1
values["crop-100.jpg"]=1
values["rot-180.jpg"]=1
values["scale-200.jpg"]=0
values["rot-240.jpg"]=1
values["stretch-700-horiz.jpg"]=0
values["stretch-700-vert.jpg"]=0
values["stretch-900-horiz.jpg"]=0
values["stretch-900-vert.jpg"]=0
values["scale-1000.jpg"]=0

failures=0

function fun_checkValue {
    local filename=${1}
    local testValue=${2}

    if [ -v values["${filename}"] ] 
    then
        local ham_test=${values["${filename}"]}

        if ([ ${ham_test} == 0 ] && [ ${testValue} -le 10 ]) || ([ ${ham_test} == 1 ] && [ ${testValue} -gt 10 ])
        then
            echo "(pass)"

            return 0
        fi
    fi

    (( failures += 1 ))
    echo "(FAIL)"

    return 1
}


# Load the test image
test_image="./test-image.jpg"
filename=$(basename "${test_image}")
pixels=$(fun_convertImage "${test_image}")
bits=$(fun_getDhashBits "${pixels[*]}")
hash=$(fun_convertBitsToBase16 "${bits}")


if [ "${1}" == "generate" ]
then
    rm -rf "./dhash-test/dhash-gray/"
    mkdir -p "./dhash-test/dhash-gray/"
else
    echo "Testing: ${filename}"
    echo "bits: ${bits}"
    echo "hash: ${hash}"
    echo ""
fi


while read -d $'\0' file;
do
    file_filename=$(basename "${file}")

    if [ "${1}" != "generate" ]
    then
        echo "${file_filename}"
    fi

    # Note: the "[0]" next to the filename will only allow a single frame of an animation.
    file_pixels=$(fun_convertImage "${file}[0]")
    file_bits=$(fun_getDhashBits "${file_pixels[*]}")
    file_hash=$(fun_convertBitsToBase16 "${file_bits}")
    ham=$(fun_calculateHammingDistance "${bits}" "${file_bits}")

    if [ "${1}" == "generate" ]
    then
        ham_test=1
        if [ ${ham} -lt 10 ]
        then
            ham_test=0
        fi

        convert "${file}" -quality 100 -colorspace Gray -scale 9x8\! "./dhash-test/dhash-gray/${file_filename}"
        echo "values[\"${file_filename}\"]=${ham_test}"
    else
        gray_pixels=$(fun_getPixelData "./dhash-test/dhash-gray/${file_filename}[0]")
        gray_bits=$(fun_getDhashBits "${gray_pixels[*]}")

        if [ "${gray_bits}" != "${file_bits}" ]
        then
            (( failures += 1 ))
            echo "Failed gray test!"

            echo "file bits: ${file_bits}"
            echo "gray bits: ${gray_bits}"
            echo "file pixels: ${file_pixels}"
            echo "gray pixels: ${gray_pixels}"
        fi

        echo "bits: ${file_bits}"
        echo "hash: ${file_hash}"
        echo -n "ham: ${ham} "; fun_checkValue "${file_filename}" "${ham}"
        echo ""
    fi
done < <(find "./dhash-test/" -maxdepth 1 -type f -print0)


if [ "${1}" != "generate" ]
then
    if [ ${failures} -gt 0 ]
    then
        echo "${failures} Failures detected"
    else
        echo "All tests passed"
    fi
fi


















