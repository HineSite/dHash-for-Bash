#!/bin/bash

. ../dhash.sh

# rename to captures per second
capture_rate=24


# Hmm... Do we want these here???
declare -A episodes
declare -a intro_bits
declare -a intro_times




function fun_timestampToString {
    timestamp=${1##+(0)}
    seconds=$(printf %.0f $(echo "${timestamp} * (1 / 24)" | bc -l ))
    minutes=$(( $seconds / 60))
    remainder=$(( $seconds - ($minutes * 60) ))

    printf "${minutes}:%02d\n" ${remainder}
}


# summary: Generates pHash ready frames of a video
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


function fun_loadFrameData {
    episode_counter=0
    while read -d $'\0' frame_data;
    do
        episodes["E${episode_counter}_bits"]="$(sed '1q;d' "${frame_data}")"
        episodes["E${episode_counter}_times"]="$(sed '2q;d' "${frame_data}")"

        (( episode_counter += 1 ))
    done < <(find "./out/frames/" -maxdepth 1 -type f -print0)
}


function fun_findIntroFramesFromSeconds {
    local episode1_bits=(${episodes["E${1}_bits"]})
    local episode1_times=(${episodes["E${1}_times"]})

    # Assuming 24fps for now...
    local start_time_seconds="${2}"
    local i=$(echo "${start_time_seconds} * ${capture_rate} - 10")
    local start_time=$(printf %.0f $(echo "${start_time_seconds}/(1/24)" | bc -l))
    local last_time=0
    local closest_time=0

    # This step is only really needed if using a capture rate less than the full rate
    # start_time might not be one of the times taken by ffmpeg, so we need to find the nearest.
    # While we are hear, we might as well take the 10 intro times to match against...
    while read -r time
    do
        local filename=$(echo "${time}" | grep -oP '[1-9]+[0-9]{1,5}')

        # The filename is the timestamp we need to compare too
        local diffy=$(( $start_time - $filename))

        if [ $diffy -lt 0 ] && [ $closest_time -eq 0 ]
        then
            closest_time=$last_time
        fi

        if [ $closest_time -ne 0 ] && [ ${#intro_times[@]} -lt 24 ]
        then
            intro_bits+=("${episode1_bits[$(( $i - 1 ))]}")
            intro_times+=("$last_time")
        fi

        last_time=$filename
        (( i += 1 ))
    done < <(printf '%s\n' "${episode1_times[@]:$i:50}")
}


function fun_findIntroInEpisode {
    local ebits=(${episodes["E${1}_bits"]})
    local etimes=(${episodes["E${1}_times"]})

    local match_index=0
    local matches=0
    local misses=0
    local match_begins_at=-1
    local i=0
    local hash=""
    local intro=""

    for hash in ${ebits[@]}
    do
        for intro in ${intro_bits[@]:$match_index}
        do
            local ham=$(fun_calculateHammingDistance "${hash}" "${intro}")

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
            echo -n "match: ${matches} | misses: ${misses} | ${etimes[$match_begins_at]} | "; fun_timestampToString ${etimes[$match_begins_at]}
            break
        fi

        local match_test=$(( ${#intro_times[@]} - 1 ))
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
}



#fun_outputVideoFrames "./Season 01/"
#exit


#fun_hashVideoFrames
#exit


fun_loadFrameData
#e0bits=(${episodes["E0_bits"]})
#e0times=(${episodes["E0_times"]})
#echo "${e0times[13]}"
#exit


# Get hashes from episode 0 with known intro start: 02:02 (122 seconds)
fun_findIntroFramesFromSeconds 0 122
#echo "${intro_times[6]}"


fun_findIntroInEpisode 1



















