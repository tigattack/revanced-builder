#!/bin/bash
set -e

printf '\n========================\n==Configuring gradle ==\n========================\n'
mkdir -p ~/.gradle/
touch ~/.gradle/gradle.properties
echo "gpr.user = $GH_USER" >> ~/.gradle/gradle.properties
echo "gpr.key = $GH_TOKEN" >> ~/.gradle/gradle.properties
echo "org.gradle.welcome=never" >> ~/.gradle/gradle.properties # Doesn't work?
printf '\nDone.\n'

printf '\n===============================\n== Building revanced-patcher ==\n===============================\n'
cd /build/revanced-patcher || exit 1
chmod +x ./gradlew
printf '\nRunning build...\n'
./gradlew publish
printf '\nRelocating build asset(s)...\n'
mv ./build/libs/revanced-patcher-*.jar /build/libs/
printf '\nDone.\n'

printf '\n===============================\n== Building revanced-patches ==\n===============================\n'
cd /build/revanced-patches || exit 1
chmod +x ./gradlew
printf '\nRunning build...\n'
./gradlew build
printf '\nRelocating build asset(s)...\n'
mv ./build/libs/revanced-patches-*.jar /build/libs/
printf '\nDone.\n'

printf '\n===========================\n== Building revanced-cli ==\n===========================\n'
cd /build/revanced-cli || exit 1
chmod +x ./gradlew
printf '\nRunning build...\n'
./gradlew build
printf '\nRelocating build asset(s)...\n'
mv ./build/libs/revanced-cli-*.jar /build/libs/
printf '\nDone.\n'

printf '\n==========================\n== Patching YouTube APK ==\n==========================\n'
printf '\nFinding dependendant files...\n'
cd /build
yt_apk=$(find . -name "*youtube*.apk" | cut -c 3-)
integrations_apk='revanced-integrations.apk'
cd ./libs
cli_jar=$(find . -name "*.jar" | grep -oE "revanced-cli-[[:digit:]]\.[[:digit:]]\.[[:digit:]]-all\.jar")
patches_jar=$(find . -name "*.jar" | grep -oE "revanced-patches-([[:digit:]]\.){1,3}jar")

if [ ! -d revanced-cache ] ; then
  printf '\nCreating directory: revanced-cache\n'
  mkdir revanced-cache
fi

printf '\nPatching APK...\n'
java -jar "$cli_jar" \
  --patches="$patches_jar" \
  --merge="../$integrations_apk" \
  --apk="../$yt_apk" \
  --out="/build/revanced.apk" \
  --temp-dir="revanced-cache" \
  --clean &&\
printf '\nDone.\nYour patched APK can be found at: ./build/revanced.apk\n'
