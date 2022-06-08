#!/bin/bash
set -e

if [ -z "$1" ]; then
  read -p 'Enter your GitHub username: ' USER
else
  USER=$1
fi
if [ -z "$2" ]; then
  echo "You need a GitHub token with the 'read:packages' scope to download packages."
  echo 'You should generate a short-lived token here: https://github.com/settings/tokens/new?scopes=read:packages&description=Revanced'
  read -sp 'Enter your GitHub token: ' TOKEN
else
  TOKEN=$2
fi

components=(
  'revanced-integrations.apk'
  'com.google.android.youtube_17.20.37.apk'
)

repos=(
  'revanced-patcher'
  'revanced-patches'
  'revanced-cli'
)

for component in "${components[@]}" ; do
  printf "\nChecking for file '%s'...\n" "$component"
  if [ -f "./build/$component" ] ; then
    printf "Found file '%s'!\n" "$component"
  else
    printf "Error: file '%s' does not exist. Please place it in ./builds/ and retry.\n" "$component"
    exit 1
  fi
done

for repo in "${repos[@]}" ; do
  printf "\nChecking for repo '%s'...\n" "$repo"
  if [ -d "./build/$repo" ] ; then
    printf "Found repo '%s'!\n" "$repo"
  else
    printf "Did not find repo '%s'. Cloning now...\n" "$repo"
    git clone --quiet "https://github.com/revanced/$repo" "./build/$repo"
  fi
done

if [[ -z "$(docker images -q revanced-builder)" ]]; then
  printf '\nBuilding Docker image\n'
  chmod +x entrypoint.sh
  docker build --tag revanced-builder .
fi

printf '\nRunning Docker image\n'
docker run --rm -v "$(pwd)/build":/build -e "GH_USER=$USER" -e "GH_TOKEN=$TOKEN" --name ReVanced-Builder revanced-builder
