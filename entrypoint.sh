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
if ! ls /build/libs/revanced-patcher-*.jar 1> /dev/null 2>&1; then
	cd /build/revanced-patcher || exit 1
	chmod +x ./gradlew
	printf '\nRunning build...\n'
	./gradlew publish
	printf '\nRelocating build asset(s)...\n'
	mv ./build/libs/revanced-patcher-*.jar /build/libs/
	printf '\nDone.\n'
else
	printf '\nrevanced-patcher already built. Skipping build.\n'
fi

printf '\n===============================\n== Building revanced-patches ==\n===============================\n'
if ! ls /build/libs/revanced-patches-*.jar 1> /dev/null 2>&1; then
	cd /build/revanced-patches || exit 1
	chmod +x ./gradlew
	printf '\nRunning build...\n'
	./gradlew build
	printf '\nRelocating build asset(s)...\n'
	mv ./build/libs/revanced-patches-*.jar /build/libs/
	printf '\nDone.\n'
else
	printf '\nrevanced-patches already built. Skipping build.\n'
fi

printf '\n===========================\n== Building revanced-cli ==\n===========================\n'
if ! ls /build/libs/revanced-cli-*-all.jar 1> /dev/null 2>&1; then
	cd /build/revanced-cli || exit 1
	chmod +x ./gradlew
	printf '\nRunning build...\n'
	./gradlew build
	printf '\nRelocating build asset(s)...\n'
	mv ./build/libs/revanced-cli-*.jar /build/libs/
	printf '\nDone.\n'
else
	printf '\nrevanced-cli already built. Skipping build.\n'
fi

printf '\n==========================\n== Patching YouTube APK ==\n==========================\n'
printf '\nFinding dependendant files...\n'
cd /build
yt_apk=$(find . -name "*youtube*.apk" | cut -c 3-)
integrations_apk='revanced-integrations.apk'
cd ./libs
cli_jar=$(find . -name "*.jar" | grep -oE "revanced-cli-[[:digit:]]\.[[:digit:]]\.[[:digit:]]-all\.jar")
patches_jar=$(find . -name "*.jar" | grep -oE "revanced-patches-([[:digit:]]\.){1,3}jar")

for var in "$yt_apk" "$integrations_apk" "$cli_jar" "$patches_jar"; do
	if [ -z "$var" ]; then
		printf 'Error: dependency not found. Please ensure the following files exist in ./build/libs/:'
		printf '\n  * *youtube*.apk'
		printf '\n  * revanced-integrations.apk'
		printf '\n  * revanced-cli-*-all.jar'
		printf '\n  * revanced-patches-*.jar'
		printf '\n  * revanced-patcher-*.jar'
	fi
done

if [ ! -d revanced-cache ] ; then
	printf '\nCreating directory: revanced-cache\n'
	mkdir revanced-cache
fi

printf '\nPatching APK...\n\n'
java -jar "$cli_jar" \
	--patches="$patches_jar" \
	--merge="../$integrations_apk" \
	--apk="../$yt_apk" \
	--out="revanced.apk" \
	--temp-dir="revanced-cache"

printf '\nPlease wait...\n'

if [ -f ./revanced.apk ] ; then
	mv ./revanced.apk /build/
	rm -rf revanced-cache
	printf '\nDone.\nYour patched APK can be found at: ./build/revanced.apk\n'
else
	printf '\nPatch failed; no file outputted. Please retry.\n'
fi
