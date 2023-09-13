#!/usr/bin/env bash

echo "*********************************** Updating the Gradle Cache: ****************************************"
ls -la ~/.gradle 2>/dev/null

#!/bin/bash

# Define the source and target directories
SOURCE_DIR="${HOME}/.gradle"
TARGET_DIR="./GradleCache"

# Check if the source directory exists
if [[ -d "${SOURCE_DIR}" ]]; then
    # Ensure the target directory exists; create if it doesn't
    mkdir -p "${TARGET_DIR}"

    # Try to copy the contents from the source to the target
    cp -R "${SOURCE_DIR}/." "${TARGET_DIR}/" && echo "Successfully copied contents." || echo "Failed to copy contents."
else
    echo "Source directory '${SOURCE_DIR}' does not exist. Nothing to copy."
fi

ls -la

echo "*******************************************************************************************************"
