#!/bin/bash

file=$1

if [ "$file" ]; then
    python assembler.py "$file" 
    echo "Machine code successfully saved to file 'machine_code'"
    cat machine_code | xclip -selection clipboard
else
    echo "No file specified"
fi