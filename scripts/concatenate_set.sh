#!/usr/bin/env bash


#############################################
# This script prepares the codebase for analysis.
# It concatenates files into a single file, with comments indicating
# the full relative path of each file, based on predefined sets of files.
# to get a full list of available files in the src directory to add to a list - for example
# find ../src -type f ! \( -name "*.jpg" -o -name "*.png" -o -name "*.svg" \) | sed 's/..\///' > lists/list_allSrcFiles.txt
# change ../src to the directory you want to search for and concatenate files
# then edit the list to remove files you don't want to include in the set
#############################################

# Initialize empty array to keep track of processed files
declare -A processed

# Define directories or file patterns to exclude
declare -a EXCLUDE_DIRS=("node_modules" "dist")

# Find the root directory of the project above this script file where the package.json file is
# located by searching the directory tree for the package.json file
current_dir=$(pwd)
root_dir=""
# Traverse upwards until main.py is found or root is reached
while [ "$current_dir" != "/" ]; do
    if [ -f "$current_dir/package.json" ]; then
        root_dir="$current_dir"
        break
    fi
    current_dir=$(dirname "$current_dir")
done

# Check if root directory is found
if [ -z "$root_dir" ]; then
    echo "package.json not found. Exiting."
    exit 1
fi

# Prompt user to select a set
echo "Available sets:"
set_index=1
declare -A INDEX_TO_SET
for file in lists/list_*.txt; do
    set_name=$(basename "$file" .txt | sed 's/^list_//')
    echo "$set_index) $set_name"
    INDEX_TO_SET[$set_index]=$set_name
    ((set_index++))
done

read -p "Enter the number of the set to concatenate: " selected_number

selected_set=${INDEX_TO_SET[$selected_number]}

# Check if the selected set exists
if [[ -z "$selected_set" ]]; then
    echo "Set not found. Exiting."
    exit 1
fi

output_file="$root_dir/output/${selected_set}_output.txt"
input_file="lists/list_${selected_set}.txt"

# Check if the input file exists
if [[ ! -f "$input_file" ]]; then
    echo "File list '$input_file' not found. Exiting."
    exit 1
fi

# Function to prepend filename as a comment. Include full relative path.
prepend_filename() {
    local file=$1
    local output_file=$2
    # Convert to full path and then to relative path from current directory
    if [[ "$OSTYPE" == "darwin"* ]]; then
        full_path=$(grealpath --relative-to="." "$file")
    else
        full_path=$(realpath --relative-to="." "$file")
    fi
    # Add a clear delimiter and the file path as a comment
    echo -e "\n\n********************************************************************\n# File: $full_path\n********************************************************************\n\n" >> "$output_file"
}

# Function to process a file if it matches the set
process_file() {
    local file=$1

    # Check if the file was already processed
    if [[ ${processed[$file]} ]]; then
        return
    fi
    processed[$file]=1

    # Prepend the filename as a comment
    prepend_filename "$file" "$output_file"

    # Concatenate the file content
    cat "$file" >> "$output_file"
}

# Header text for the output file
python_header_comment="These are the files that I want to ask questions about. Each section is clearly delimited and begins with the file's relative path to the project root. This structure is designed to facilitate a comprehensive analysis of the codebase.\n\n"

echo -e "$python_header_comment" > "$output_file"

# Read and process the file list
while IFS= read -r file; do
    if [[ -f "$root_dir/$file" ]]; then
        process_file "$root_dir/$file"
    else
        echo "Warning: $root_dir/$file not found."
    fi
done < "$input_file"

echo "Project files from set '$selected_set' have been concatenated into $output_file."
