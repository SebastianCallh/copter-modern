#!/bin/bash

file=$1

if [ "$file" ]; then
    python assembler.py "$file" 
    echo "Machine code successfully saved to file 'machine_code'"
    cat machine_code | xclip -selection clipboard
    echo "Machine code succesfully copied to clipboard"
else
    echo "No file specified"
fi