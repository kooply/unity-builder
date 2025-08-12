#!/usr/bin/env bash

echo "*********************************** Reading the Cocoa Repos Cache: ****************************************"

echo "current folder:"
ls -la

# Define the source and target directories
REPO_SOURCE_DIR="./CocoaSpecs"
REPO_TARGET_DIR="${HOME}/.cocoapods/repos"

# Check if the source directory exists
if [[ -d "${REPO_SOURCE_DIR}" ]]; then
    # Ensure the target directory exists; create if it doesn't
    mkdir -p "${REPO_TARGET_DIR}"

    # Try to copy the contents from the source to the target
    cp -R "${REPO_SOURCE_DIR}/." "${REPO_TARGET_DIR}/" && echo "Successfully copied contents." || echo "Failed to copy contents."
else
    echo "Source directory '${REPO_SOURCE_DIR}' does not exist. Nothing to copy."
fi

echo "******************************************************************************************************"


echo "*********************************** Reading the Cocoa Cache: ****************************************"

echo "current folder:"
ls -la

# Define the source and target directories
CACHE_SOURCE_DIR="./CocoaCache"
CACHE_TARGET_DIR="${HOME}/.cache/CocoaPods"

# Check if the source directory exists
if [[ -d "${CACHE_SOURCE_DIR}" ]]; then
    # Ensure the target directory exists; create if it doesn't
    mkdir -p "${CACHE_TARGET_DIR}"

    # Try to copy the contents from the source to the target
    cp -R "${CACHE_SOURCE_DIR}/." "${CACHE_TARGET_DIR}/" && echo "Successfully copied contents." || echo "Failed to copy contents."
else
    echo "Source directory '${CACHE_SOURCE_DIR}' does not exist. Nothing to copy."
fi

df -h

echo "******************************************************************************************************"