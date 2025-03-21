#!/usr/bin/env bash

INSTR_FILE="bash_instr.txt"

touch $INSTR_FILE
ABS_PATH=$(pwd)
ABS_PATH+="/"
ABS_PATH+=$INSTR_FILE
echo "Copy and paste this path to INSTR_FILE variable: $ABS_PATH"

AUDIO_DIR="sfx/"

while true; do
    cmd=$(cat $INSTR_FILE)

    if [ "$cmd" = "SKIP" ]; then
        continue
    elif [ "$cmd" = "EXIT" ]; then
        echo "Exiting..."
        killall $$  # stop audio playing in children processes
        kill $$
        break
    else  # a music file
        # afplay works on mac, not sure about linux but def not windows
        audio_file=$AUDIO_DIR
        audio_file+=$cmd
        afplay $audio_file > /dev/null 2>&1 &  # play audio in a child process
    fi
done