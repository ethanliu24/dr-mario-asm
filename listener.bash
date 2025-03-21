#!/usr/bin/env bash

# supports mac only for now

INSTR_FILE="bash_instr.txt"

touch $INSTR_FILE
ABS_PATH=$(pwd)
ABS_PATH+="/"
ABS_PATH+=$INSTR_FILE
echo "Copy and paste this path to INSTR_FILE variable: $ABS_PATH"

AUDIO_DIR="sfx/"

while true
do
    cmd=$(cat $INSTR_FILE)

    if [[ "$cmd" == "SKIP" || -z "$cmd" || "$cmd" =~ ^[[:space:]]*$ ]]  # sm crazy gpt regex to check for skips
    then
        continue
    elif [ "$cmd" = "EXIT" ]
    then
        echo "Exiting..."
        pkill -P $$ afplay # kill all bg music jobs
        kill $$
        break
    elif [ "$cmd" = "KILL_SFX" ]
    then
        pkill -P $$ afplay # kill all bg music jobs
    else  # a music file
        # afplay works on mac, not sure about linux but def not windows
        audio_file=$AUDIO_DIR
        audio_file+=$cmd
        afplay $audio_file &  # play audio in a background job
    fi
done