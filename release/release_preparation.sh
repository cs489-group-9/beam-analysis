#!/usr/bin/env bash
echo "prepare for release"

printf "\n\nPlease confirm the following...
* You have an Apache ID and Password
* Github ID, Password, and Personal Access Token
* Access to Beam's Apache Nexus respository\n"

read -r -p "Continue [y/n]: " continue
# echo $continue

if [[ "$continue" = "n" ]]; then
    printf "\nPlease find the steps to create those credentials \e]8;;https://github.com/apache/beam/blob/master/contributor-docs/release-guide.md#prepare-accounts-keys-etc\e\\here\n\e]8;;\e\\"
    exit 0
fi

printf "\nA GPG key is required. Do you need to generate one?\n"

read -r -p "Continue [y/n]: " continue

if [[ "$continue" = "y" ]]; then
    ./release/src/main/scripts/preparation_before_release.sh

    printf "Key ID\n"
    gpg --list-sigs --keyid-format LONG
fi


printf "\nDo you need to upload your key into Ubuntu OpenPGP Server?\n"

read -r -p "Continue [y/n]: " continue

if [[ "$continue" = "y" ]]; then
    gpg --export --armor
    printf "\nPlease find the steps to upload the key \e]8;;https://github.com/apache/beam/blob/7f04c4f07f2698f823953902bfb79fc7cb6e1584/contributor-docs/release-guide.md#access-to-apache-nexus-repository\e\\here\n\e]8;;\e\\"
fi


printf "\nDependency Checks\n"

printf "\nUpdate the base image dependencies for Python container Images\n"

printf "\nUpdate the Go version for container builds \n"

printf "\nSteps to do so can be found here \e]8;;https://github.com/apache/beam/blob/master/contributor-docs/release-guide.md#dependency-checks\e\\here\n\e]8;;\e\\"



