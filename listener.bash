#!/usr/bin/env bash

PID=$$

while true; do
    cmd=$(cat bash_instruction.txt)

    if [ "$cmd" = "EXIT" ];
    then
        kill $PID
        break
    else  # a music file
        afplay "$cmd" > /dev/null 2>&1
    fi
done