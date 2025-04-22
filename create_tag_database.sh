#!/bin/bash

# Set script to exit immediately if a command exits with a non-zero status
set -e

# START ### CONFIGURATION ###
# File containing the raw list of NVIDIA CUDA tags, one per line.
# Make sure this file exists and has the tags from https://termbin.com/5ceo
INPUT_TAG_FILE="nvidia_tags.txt"

# The output JSON file we gon' create. This is your database.
OUTPUT_JSON_FILE="cuda_tags_database.json"
# FINISH ### CONFIGURATION ###


# START ### SCRIPT BANNER ###
echo "=============================================="
echo " NVIDIA CUDA Tag Database Creator Script      "
echo " Input : $INPUT_TAG_FILE                      "
echo " Output: $OUTPUT_JSON_FILE                   "
echo "=============================================="
# FINISH ### SCRIPT BANNER ###


# START ### INPUT VALIDATION ###
echo "[*] Checkin' if input file '$INPUT_TAG_FILE' is present..."
if [ ! -f "$INPUT_TAG_FILE" ]; then
    echo "[!] ERROR: Input tag file '$INPUT_TAG_FILE' not found, my boy."
    echo "[!] Make sure you saved that tag list from termbin into this file."
    echo "[!] Peace out."
    exit 1
else
    echo "[+] Input file found. Solid."
fi

echo "[*] Checkin' if 'jq' command is available..."
if ! command -v jq &> /dev/null; then
    echo "[!] ERROR: 'jq' command not found. This script needs jq to build the JSON."
    echo "[!] Install that tool, G. On Debian/Ubuntu run this:"
    echo "    sudo apt update && sudo apt install jq"
    echo "[!] Peace out."
    exit 1
else
    echo "[+] 'jq' is installed. We good."
fi
# FINISH ### INPUT VALIDATION ###


# START ### TAG PROCESSING ###
echo "[*] Aight, processin' tags from '$INPUT_TAG_FILE'..."
echo "[*] Readin' raw lines, choppin' empty ones, buildin' JSON array..."

# Use jq:
# -R : Read raw text strings, not JSON
# -s : Slurp the entire input into a single string
# 'split("\n")' : Split the slurped string into an array based on newlines
# '| map(select(length > 0))' : Filter out any empty strings resulting from blank lines
jq -R -s 'split("\n") | map(select(length > 0))' "$INPUT_TAG_FILE" > "$OUTPUT_JSON_FILE"

if [ $? -ne 0 ]; then
    echo "[!] FUCK! Somethin' went wrong usin' jq."
    echo "[!] Couldn't create '$OUTPUT_JSON_FILE'. Check for errors above."
    exit 1
fi
# FINISH ### TAG PROCESSING ###


# START ### COMPLETION MESSAGE ###
echo "[+] BET! Operation complete."
echo "[+] We processed them tags and dropped a clean JSON database file:"
echo "    '$OUTPUT_JSON_FILE'"
echo "[+] Now your application can load this file and know all the CUDA tags."
echo "[+] Handle your business, big dawg!"
# FINISH ### COMPLETION MESSAGE ###

exit 0
