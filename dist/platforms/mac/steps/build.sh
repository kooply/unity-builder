#!/usr/bin/env bash

#
# Set project path
#

UNITY_PROJECT_PATH="$GITHUB_WORKSPACE/$PROJECT_PATH"
echo "Using project path \"$UNITY_PROJECT_PATH\"."

#
# Display the name for the build, doubles as the output name
#

echo "Using build name \"$BUILD_NAME\"."

#
# Display the build's target platform;
#

echo "Using build target \"$BUILD_TARGET\"."

#
# Display the build profile
#

if [ -z "$BUILD_PROFILE" ]; then
  # User has not provided a build profile
  #
  echo "Doing a default \"$BUILD_TARGET\" platform build."
  #
else
  # User has provided a path to a build profile `.asset` file
  #
  echo "Using build profile \"$BUILD_PROFILE\" relative to \"$UNITY_PROJECT_PATH\"."
  #
fi


#
# Display build path and file
#

echo "Using build path \"$BUILD_PATH\" to save file \"$BUILD_FILE\"."
BUILD_PATH_FULL="$GITHUB_WORKSPACE/$BUILD_PATH"
CUSTOM_BUILD_PATH="$BUILD_PATH_FULL/$BUILD_FILE"

#
# Set the build method, must reference one of:
#
#   - <NamespaceName.ClassName.MethodName>
#   - <ClassName.MethodName>
#
# For example: `BuildCommand.PerformBuild`
#
# The method must be declared static and placed in project/Assets/Editor
#

if [ -z "$BUILD_METHOD" ]; then
  # User has not provided their own build command.
  #
  # Use the script from this action which builds the scenes that are enabled in
  # the project.
  #
  echo "Using built-in build method."
  # Create Editor directory if it does not exist
  mkdir -p "$UNITY_PROJECT_PATH/Assets/Editor/"
  # Copy the build script of Unity Builder action
  cp -R "$ACTION_FOLDER/default-build-script/Assets/Editor/" "$UNITY_PROJECT_PATH/Assets/Editor/"
  # Set the Build method to that of UnityBuilder Action
  BUILD_METHOD="UnityBuilderAction.Builder.BuildProject"
  # Verify recursive paths
  ls -Ralph "$UNITY_PROJECT_PATH/Assets/Editor/"
  #
else
  # User has provided their own build method.
  # Assume they also bring their own script.
  #
  echo "Using build method \"$BUILD_METHOD\"."
  #
fi

#
# Prepare Android keystore and SDK, if needed
#

if [[ "$BUILD_TARGET" == "Android" && -n "$ANDROID_KEYSTORE_NAME" && -n "$ANDROID_KEYSTORE_BASE64" ]]; then
  echo "Creating Android keystore."
  echo "$ANDROID_KEYSTORE_BASE64" | base64 --decode > "$UNITY_PROJECT_PATH/$ANDROID_KEYSTORE_NAME"
  echo "Created Android keystore."
else
  echo "Not creating Android keystore."
fi

if [[ "$BUILD_TARGET" == "Android" && -n "$ANDROID_SDK_MANAGER_PARAMETERS" ]]; then
  echo "Updating Android SDK with parameters: $ANDROID_SDK_MANAGER_PARAMETERS"
  ANDROID_INSTALL_LOCATION="/Applications/Unity/Hub/Editor/$UNITY_VERSION/PlaybackEngines/AndroidPlayer"
  export JAVA_HOME="$ANDROID_INSTALL_LOCATION/OpenJDK"
  export ANDROID_HOME="$ANDROID_INSTALL_LOCATION/SDK"
  yes | "$ANDROID_HOME/tools/bin/sdkmanager" "$ANDROID_SDK_MANAGER_PARAMETERS"
  echo "Updated Android SDK."
else
  echo "Not updating Android SDK."
fi

#
# Pre-build debug information
#

echo ""
echo "###########################"
echo "#    Custom parameters    #"
echo "###########################"
echo ""

echo "$CUSTOM_PARAMETERS"

echo ""
echo "###########################"
echo "#    Current build dir    #"
echo "###########################"
echo ""

echo "Creating \"$BUILD_PATH_FULL\" if it does not exist."
mkdir -p "$BUILD_PATH_FULL"
ls -alh "$BUILD_PATH_FULL"

echo ""
echo "###########################"
echo "#    Project directory    #"
echo "###########################"
echo ""

ls -alh "$UNITY_PROJECT_PATH"

#
# Build
#

echo ""
echo "###########################"
echo "#    Building project     #"
echo "###########################"
echo ""

# Reference: https://docs.unity3d.com/2019.3/Documentation/Manual/CommandLineArguments.html

# Transient-failure retry - see the matching block in platforms/ubuntu/steps/build.sh for the rationale.
# Retries the Unity build only when the log shows a git/UPM package-resolution flake, never a real
# compile/build error. Keep BUILD_RETRY_PATTERN in sync with the ubuntu script.
BUILD_MAX_ATTEMPTS="${BUILD_MAX_ATTEMPTS:-3}"
BUILD_RETRY_PATTERN="${BUILD_RETRY_PATTERN:-Error when executing git command|error: RPC failed|bytes of body are still expected|Failed to resolve packages|Unable to (add|update|resolve) [^ ]*package|Cannot resolve packages}"

BUILD_ATTEMPT=1
while : ; do
  echo ""
  echo "=== Build attempt ${BUILD_ATTEMPT} of ${BUILD_MAX_ATTEMPTS} ==="
  BUILD_LOG="$(mktemp)"

  set -o pipefail
  /Applications/Unity/Hub/Editor/$UNITY_VERSION/Unity.app/Contents/MacOS/Unity \
    -logFile - \
    $( [ "${MANUAL_EXIT}" == "true" ] || echo "-quit" ) \
    -batchmode \
    $( [ "${ENABLE_GPU}" == "true" ] || echo "-nographics" ) \
    -customBuildName "$BUILD_NAME" \
    -projectPath "$UNITY_PROJECT_PATH" \
    $( [ -z "$BUILD_PROFILE" ] && echo "-buildTarget $BUILD_TARGET") \
    -customBuildTarget "$BUILD_TARGET" \
    -customBuildPath "$CUSTOM_BUILD_PATH" \
    -customBuildProfile "$BUILD_PROFILE" \
    ${BUILD_PROFILE:+-activeBuildProfile} ${BUILD_PROFILE:+"$BUILD_PROFILE"} \
    -executeMethod "$BUILD_METHOD" \
    -buildVersion "$VERSION" \
    -androidVersionCode "$ANDROID_VERSION_CODE" \
    -androidKeystoreName "$ANDROID_KEYSTORE_NAME" \
    -androidKeystorePass "$ANDROID_KEYSTORE_PASS" \
    -androidKeyaliasName "$ANDROID_KEYALIAS_NAME" \
    -androidKeyaliasPass "$ANDROID_KEYALIAS_PASS" \
    -androidTargetSdkVersion "$ANDROID_TARGET_SDK_VERSION" \
    -androidExportType "$ANDROID_EXPORT_TYPE" \
    -androidSymbolType "$ANDROID_SYMBOL_TYPE" \
    $CUSTOM_PARAMETERS 2>&1 | tee "$BUILD_LOG"

  # Catch exit code (of Unity, not tee)
  BUILD_EXIT_CODE=${PIPESTATUS[0]}
  set +o pipefail

  if [ $BUILD_EXIT_CODE -eq 0 ]; then
    echo "Build succeeded (attempt ${BUILD_ATTEMPT} of ${BUILD_MAX_ATTEMPTS})";
    rm -f "$BUILD_LOG"
    break
  fi

  echo "Build failed, with exit code $BUILD_EXIT_CODE (attempt ${BUILD_ATTEMPT} of ${BUILD_MAX_ATTEMPTS})";

  if [ "$BUILD_ATTEMPT" -ge "$BUILD_MAX_ATTEMPTS" ]; then
    echo "No attempts left; giving up.";
    rm -f "$BUILD_LOG"
    break
  fi

  if grep -qiE "$BUILD_RETRY_PATTERN" "$BUILD_LOG"; then
    RETRY_DELAY=$(( BUILD_ATTEMPT * 15 ))
    echo "Detected a transient network/package-resolution failure; retrying in ${RETRY_DELAY}s.";
    rm -f "$BUILD_LOG"
    sleep "$RETRY_DELAY"
    BUILD_ATTEMPT=$(( BUILD_ATTEMPT + 1 ))
    continue
  fi

  echo "Failure is not a known transient error; not retrying.";
  rm -f "$BUILD_LOG"
  break
done

#
# Permissions
#

# Make a given user owner of all artifacts
if [[ -n "$CHOWN_FILES_TO" ]]; then
  chown -R "$CHOWN_FILES_TO" "$BUILD_PATH_FULL"
  chown -R "$CHOWN_FILES_TO" "$UNITY_PROJECT_PATH"
fi

# Add read permissions for everyone to all artifacts
chmod -R a+r "$BUILD_PATH_FULL"
chmod -R a+r "$UNITY_PROJECT_PATH"

# Add execute permissions to specific files
if [[ "$BUILD_TARGET" == "StandaloneOSX" ]]; then
  OSX_EXECUTABLE_PATH="$BUILD_PATH_FULL/$BUILD_NAME.app/Contents/MacOS"
  find "$OSX_EXECUTABLE_PATH" -type f -exec chmod +x {} \;
fi

#
# Results
#

echo ""
echo "###########################"
echo "#       Build output      #"
echo "###########################"
echo ""

ls -alh "$BUILD_PATH_FULL"
