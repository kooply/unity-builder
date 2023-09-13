#!/usr/bin/env bash

echo "*********************************** Reading the Gradle Cache: ****************************************"

echo "current folder:"
ls -la

# Define the source and target directories
SOURCE_DIR="./GradleCache"
TARGET_DIR="${HOME}/.gradle/caches"

# Check if the source directory exists
if [[ -d "${SOURCE_DIR}" ]]; then
    # Ensure the target directory exists; create if it doesn't
    mkdir -p "${TARGET_DIR}"

    # Try to copy the contents from the source to the target
    cp -R "${SOURCE_DIR}/." "${TARGET_DIR}/" && echo "Successfully copied contents." || echo "Failed to copy contents."
else
    echo "Source directory '${SOURCE_DIR}' does not exist. Nothing to copy."
fi

echo "******************************************************************************************************"
