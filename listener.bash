#!/usr/bin/env bash

PID=$$
INSTR_FILE="bash_instr.txt"

touch $INSTR_FILE
ABS_PATH=$(pwd)
ABS_PATH+="/"
ABS_PATH+=$INSTR_FILE
echo "Copy and paste this path to INSTR_FILE variable: $ABS_PATH"

while true; do
    cmd=$(cat $INSTR_FILE)

    if [ "$cmd" = "SKIP" ]; then
        continue
    elif [ "$cmd" = "EXIT" ]; then
        kill $PID
        break
    else  # a music file
        # afplay works on mac, not sure about linux but def not windows
        afplay "$cmd" > /dev/null 2>&1
    fi
done