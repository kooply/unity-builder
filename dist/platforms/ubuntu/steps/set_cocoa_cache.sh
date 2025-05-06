#!/usr/bin/env bash


echo "*********************************** Showing Cocoapods Repos and Cache: ****************************************"

if ! pod cache list 2>/dev/null; then
  echo "Failed to list CocoaPods cache"
fi


if ! pod repo list 2>/dev/null; then
  echo "Failed to list CocoaPods repos"
fi



echo "*********************************** Updating the Cocoapods Repo Cache: ****************************************"
echo "Current Folder:"
ls -la ~/.gradle 2>/dev/null

#!/bin/bash

# Define the source and target directories
REPO_TARGET_DIR="./CocoaSpecs"
REPO_SOURCE_DIR="${HOME}/.cocoapods/repos"

# Check if the source directory exists
if [[ -d "${REPO_SOURCE_DIR}" ]]; then
    # Ensure the target directory exists; create if it doesn't
    mkdir -p "${REPO_TARGET_DIR}"

    # Try to copy the contents from the source to the target
    if cp -R "${REPO_SOURCE_DIR}/." "${REPO_TARGET_DIR}/"; then
        echo "Successfully copied contents."

        echo -n "Target after copy:"
        ls -la "${REPO_TARGET_DIR}"
        
        # Print the size of the copied folder
        echo -n "Size of the copied folder: "
        du -sh "${REPO_TARGET_DIR}"
    else
        echo "Failed to copy contents."
    fi
else
    echo "Source directory '${REPO_SOURCE_DIR}' does not exist. Nothing to copy."
fi

echo "*******************************************************************************************************"

echo "*********************************** Updating the Cocoapods Cache: ****************************************"
echo "Current Folder:"
ls -la ~/.gradle 2>/dev/null

#!/bin/bash

# Define the source and target directories
CACHE_TARGET_DIR="./CocoaCache/"
CACHE_SOURCE_DIR="${HOME}/Library/Caches/CocoaPods"

# Check if the source directory exists
if [[ -d "${CACHE_SOURCE_DIR}" ]]; then
    # Ensure the target directory exists; create if it doesn't
    mkdir -p "${CACHE_TARGET_DIR}"

    # Try to copy the contents from the source to the target
    if cp -R "${CACHE_SOURCE_DIR}/." "${CACHE_TARGET_DIR}/"; then
        echo "Successfully copied contents."

        echo -n "Target after copy:"
        ls -la "${CACHE_TARGET_DIR}"
        
        # Print the size of the copied folder
        echo -n "Size of the copied folder: "
        du -sh "${CACHE_TARGET_DIR}"
    else
        echo "Failed to copy contents."
    fi
else
    echo "Source directory '${CACHE_SOURCE_DIR}' does not exist. Nothing to copy."
fi

echo "*******************************************************************************************************"
