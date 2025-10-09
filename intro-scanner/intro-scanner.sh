#!/bin/bash

. ../dhash.sh

# rename to captures per second
capture_rate=24

# summary: Generates pHash ready frammes of a video
# arg1: Directory path of videos to generate frames
function fun_outputVideoFrames {
    rm -rf ./out/*

    local episode=1
    local mod=$(( 24 / $capture_rate ))

    while read -d $'\0' file;
    do
        mkdir -p "./out/${episode}/"

        ffmpeg -i "${file}" -hide_banner -loglevel panic -nostdin -vf "select=not(mod(n\,${mod})),format=gray,scale=9:8" -vsync 0 -frame_pts 1 -q:v 1 "./out/${episode}/%06d.jpg"

        (( episode += 1 ))
    done < <(find "$1" -maxdepth 1 -type f -print0)
}

#fun_outputVideoFrames "./Season 01/"
#exit





function fun_hashVideoFrames {
    rm -rf "./out/frames/*"
    mkdir -p "./out/frames"

    local episode_num=1

    while read -d $'\0' episode;
    do
        touch "./out/frames/${episode_num}.txt"

        local pixels=""
        local bits=""
        local frame_bits=""
        local timestamps=""
        local filename=""

        while read -d $'\0' frame;
        do
            pixels=$(fun_getPixelData "${frame}")
            bits=$(fun_getDhashBits "${pixels[*]}")
            frame_bits+=" ${bits}"

            filename="${frame##*/}"
            timestamps+=" ${filename%.*}"
        done < <(find "${episode}" -maxdepth 1 -type f -print0)

        echo "${frame_bits}" >> "./out/frames/${episode_num}.txt"
        echo "${timestamps}" >> "./out/frames/${episode_num}.txt"

        (( episode_num += 1 ))
    done < <(find "./out/" -mindepth 1 -maxdepth 1 -not -path "./out/frames" -type d -print0)
}

#fun_hashVideoFrames
#exit


function fun_timestampToString {
    timestamp=${1##+(0)}
    #echo "timestamp: $timestamp"
    seconds=$(printf %.0f $(echo "${timestamp} * (1 / 24)" | bc -l ))
    #echo "seconds: $seconds"
    minutes=$(( $seconds / 60))
    #echo "minutes: $minutes"
    remainder=$(( $seconds - ($minutes * 60) ))
    #echo "remainder: $remainder"

    printf "${minutes}:%02d\n" ${remainder}
}




episode_bits=()
episode_times=()
num_episodes=0

while read -d $'\0' frame;
do
    episode_bits+=("$(sed '1q;d' "${frame}")")
    episode_times+=("$(sed '2q;d' "${frame}")")

    (( num_episodes += 1 ))
done < <(find "./out/frames/" -maxdepth 1 -type f -print0)






episode2_bits=(${episode_bits[0]})
episode2_times=(${episode_times[0]})
episode3_bits=(${episode_bits[0]})
episode3_times=(${episode_times[0]})

# get hashes from known intro start: 02:02 (122)
# Asuming 24fps for now...
start_time_seconds=122
i=$(echo "${start_time_seconds} * ${capture_rate} - 10")
start_time=$(printf %.0f $(echo "${start_time_seconds}/(1/24)" | bc -l))
last_time=0
closest_time=0
intro_bits=()
intro_times=()


# start_time might not be one of the times taken by ffmpeg, so we need to find the nearest.
# While we are hear, we might as well take the 10 intro times to match against...
while read -r time
do
    filename=$(echo "${time}" | grep -oP '[1-9]+[0-9]{1,5}')

    # The filename is the timestamp we need to compare too
    diffy=$(( $start_time - $filename))

    if [ $diffy -lt 0 ] && [ $closest_time -eq 0 ]
    then
        closest_time=$last_time
    fi

    if [ $closest_time -ne 0 ] && [ ${#intro_times[@]} -lt 24 ]
    then
        intro_bits+=("${episode2_bits[$(( $i - 1 ))]}")
        intro_times+=("$last_time")
    fi

    last_time=$filename
    (( i += 1 ))
done < <(printf '%s\n' "${episode2_times[@]:$i:50}")

#echo "${intro_bits[*]}"
#echo "${intro_times[*]}"

match_index=0
matches=0
misses=0
match_begins_at=-1
i=0

for hash in ${episode3_bits[@]}
do
    for intro in ${intro_bits[@]:$match_index}
    do
        ham=$(fun_calculateHammingDistance "${hash}" "${intro}")

        if [ $ham -le 10 ]
        then
            misses=0
            (( matches += 1 ))
            (( match_index += 1 ))

            if [ $matches -eq 1 ]
            then
                match_begins_at=$i
            fi

            break
        else
            (( misses += 1 ))

            if [ $misses -gt 5 ]
            then
                match_index=0
                matches=0
                misses=0
                match_begins_at=0

                break
            fi
        fi
    done

    if [ $matches -ge 18 ]
    then
        echo -n "match: ${matches} | misses: ${misses} | ${episode3_times[$match_begins_at]} | "; fun_timestampToString ${episode3_times[$match_begins_at]}
        break
    fi

    match_test=$(( ${#intro_times[@]} - 1 ))
    if [ $match_index -ge $match_test ]
    then
        echo "reset"
        match_index=0
        matches=0
        misses=0
        match_begins_at=0
    fi

    (( i += 1 ))
done

























