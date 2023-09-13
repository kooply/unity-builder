#!/usr/bin/env bash

echo "*********************************** Updating the Gradle Cache: ****************************************"
echo "Current Folder:"
ls -la ~/.gradle 2>/dev/null

#!/bin/bash

# Define the source and target directories
SOURCE_DIR="${HOME}/.gradle/caches"
TARGET_DIR="./GradleCache"

# Check if the source directory exists
if [[ -d "${SOURCE_DIR}" ]]; then
    # Ensure the target directory exists; create if it doesn't
    mkdir -p "${TARGET_DIR}"

    # Try to copy the contents from the source to the target
    if cp -R "${SOURCE_DIR}/." "${TARGET_DIR}/"; then
        echo "Successfully copied contents."

        echo -n "Target after copy:"
        ls -la "${TARGET_DIR}"
        
        # Print the size of the copied folder
        echo -n "Size of the copied folder: "
        du -sh "${TARGET_DIR}"
    else
        echo "Failed to copy contents."
    fi
else
    echo "Source directory '${SOURCE_DIR}' does not exist. Nothing to copy."
fi

echo "*******************************************************************************************************"
