#!/bin/bash

# --- CONFIGURATION ---
# 1. Path to the folder where your PS2 games are located on your USB drive.
#    If the games are in the root of the USB drive (e.g., ul.CODE.SLUS_ID.XX), point to the root.
GAMES_DIR="/run/media/USER_NAME/DISKNAME/"

# 2. Path to the OPL ART folder on your USB drive.
#    Covers will be saved here. This folder is usually in the root of the OPL USB drive.
OPL_ART_DIR="/run/media/USER_NAME/DISKNAME/ART/"

# 3. Base URL for the GitHub cover repository for the Default JPG format.
#    This URL now points directly to the format you have confirmed.
GITHUB_DEFAULT_JPG_URL="https://raw.githubusercontent.com/xlenore/ps2-covers/main/covers/default/"

echo "--- Starting OPL cover download ---"
echo "Checking games in: ${GAMES_DIR}"
echo "Saving covers to: ${OPL_ART_DIR}"
echo "---"

# Ensure the ART folder exists
mkdir -p "${OPL_ART_DIR}"

# Iterate over each file that starts with "ul."
for GAME_FILE in "${GAMES_DIR}"ul.*; do
    # Check if there are files to process
    # Also ignore ul.cfg, which is not a game file.
    if [ ! -f "$GAME_FILE" ] || [[ "$GAME_FILE" =~ \.cfg$ ]]; then
        continue
    fi

    GAME_BASENAME=$(basename "$GAME_FILE")
    echo "Processing: ${GAME_BASENAME}"

    # --- ID EXTRACTION AND REFORMATTING LOGIC ---
    # Extract the game ID using 'cut'. The complete ID is the concatenation of the 3rd and 4th fields.
    # Ex: ul.1A595FC6.SLUS_217.82.00 -> GAME_ID_PART1=SLUS_217, GAME_ID_PART2=82
    GAME_ID_PART1=$(echo "$GAME_BASENAME" | cut -d'.' -f3)
    GAME_ID_PART2=$(echo "$GAME_BASENAME" | cut -d'.' -f4)
    RAW_GAME_ID="${GAME_ID_PART1}.${GAME_ID_PART2}" # Ex: SLUS_217.82 (OPL Format)

    # Convert the ID to the repository format: SLUS-XXXXX
    # Ex: SLUS_217.82 -> SLUS-21782
    FORMATTED_GAME_ID=$(echo "$RAW_GAME_ID" | tr '_' '-' | tr -d '.')


    # A basic check to ensure the formatted ID is not empty and looks like a game ID.
    if [[ -n "$FORMATTED_GAME_ID" && "$FORMATTED_GAME_ID" =~ ^S[A-Z]+-[0-9]+$ ]]; then
        echo "  Game ID found (OPL): ${RAW_GAME_ID}"
        echo "  Formatted Game ID (Repository): ${FORMATTED_GAME_ID}"

        # The filename for OPL still uses the RAW_GAME_ID and the .JPG extension
        COVER_FILE_NAME="${RAW_GAME_ID}_COV.JPG"
        OUTPUT_PATH="${OPL_ART_DIR}${COVER_FILE_NAME}" # Full path to save the cover

        # Check if the cover already exists in the ART folder to avoid repeated downloads
        if [ -f "$OUTPUT_PATH" ]; then
            echo "  Cover already exists for ${RAW_GAME_ID}. Skipping."
            continue
        fi

        # URL to download the cover from the repository (using the formatted ID)
        DOWNLOAD_URL="${GITHUB_DEFAULT_JPG_URL}${FORMATTED_GAME_ID}.jpg"

        echo "  Attempting to download from: ${DOWNLOAD_URL}"
        # Download the cover using wget
        wget -q -O "${OUTPUT_PATH}" "${DOWNLOAD_URL}"

        if [ $? -eq 0 ]; then
            echo "  Cover downloaded successfully: ${COVER_FILE_NAME}"
        else
            echo "  Error or cover not found for ${RAW_GAME_ID} in the default repository. Check the ID on GitHub."
            rm -f "${OUTPUT_PATH}" # Remove empty or incomplete file if download failed
        fi
    else
        echo "  Could not extract or format a valid game ID from: ${GAME_BASENAME}. Skipping."
    fi
    echo "---"
done

echo "--- Cover download process completed ---"
