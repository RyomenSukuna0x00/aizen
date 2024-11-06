#!/bin/bash

# Function to display usage
usage() {
    echo "Usage: $0 -f <input_filename>"
    exit 1
}

# Check if the correct number of arguments is provided
if [ "$#" -lt 2 ]; then
    usage
fi

# Parse command-line arguments
while getopts "f:" opt; do
    case $opt in
        f) filename="$OPTARG" ;;
        *) usage ;;
    esac
done

# Check if input file exists
if [ ! -f "$filename" ]; then
    echo "File not found: $filename"
    exit 1
fi

# Check if the LinkFinder script exists
linkfinder_path="$HOME/LinkFinder/linkfinder.py"
if [ ! -f "$linkfinder_path" ]; then
    echo "LinkFinder not found at $linkfinder_path"
    exit 1
fi

# Create the js-files directory if it doesn't exist
output_dir="js-files"
mkdir -p "$output_dir"

# Read the URLs from the file, filter for .js URLs, and run LinkFinder
grep "\.js$" "$filename" | while read url; do
    # Run LinkFinder and redirect output to /dev/null
    output=$(python3 "$linkfinder_path" -i "$url" -o cli 2>/dev/null)

    # Check for specific error messages in the output
    if [[ "$output" != *"Usage: python $HOME/LinkFinder/linkfinder.py [Options] use -h for help"* ]] && \
       [[ "$output" != *"Error: invalid input defined or SSL error: HTTP Error 404: Not Found"* ]] && \
       [[ ! -z "$output" ]]; then

        # Save the output to a file in the js-files directory without displaying it
        output_file="$output_dir/$(basename "$url").txt"
        echo "$url" >> "$output_file"
        echo "$output" >> "$output_file"
        echo "" >> "$output_file"
    fi
done > /dev/null 2>&1  # Suppress all output while the loop runs
