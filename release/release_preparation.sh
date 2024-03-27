#!/usr/bin/env bash

printf "\n==================== 1.1 Prepare accounts, keys, etc =======================\n"

printf "Please confirm the following...
* You have an Apache ID and Password
* Github ID, Password, and Personal Access Token
* Access to Beam's Apache Nexus respository\n"

read -r -p "Continue [y/n]: " continue
printf "\n"

if [[ "$continue" = "n" ]]; then
    printf "\nPlease find the steps to create those credentials \e]8;;https://github.com/apache/beam/blob/master/contributor-docs/release-guide.md#prepare-accounts-keys-etc\e\\here\n\e]8;;\e\\"
    exit 1
fi

read -r -p "A GPG key is required. Do you need to generate one? [y/n]: " continue

if [[ "$continue" = "y" ]]; then
    ./release/src/main/scripts/preparation_before_release.sh

    printf "Key ID\n"
    gpg --list-sigs --keyid-format LONG
fi

printf "\n"
read -r -p "Do you need to upload your key into Ubuntu OpenPGP Server? [y/n]: " continue

if [[ "$continue" = "y" ]]; then
    gpg --export --armor
    printf "Please find the steps to upload the key \e]8;;https://github.com/apache/beam/blob/7f04c4f07f2698f823953902bfb79fc7cb6e1584/contributor-docs/release-guide.md#access-to-apache-nexus-repository\e\\here\n\e]8;;\e\\"

    read -r -p "Continue [y/n]: " continue

    if [[ "$continue" = "n" ]]; then
        exit 1
    fi
fi

printf "\nNext, please configure access to Apache Nexus Repository. Steps to do so can be found \e]8;;https://github.com/apache/beam/blob/7f04c4f07f2698f823953902bfb79fc7cb6e1584/contributor-docs/release-guide.md#access-to-apache-nexus-repository\e\\here\n\e]8;;\e\\"
read -r -p "Do you have access [y/n]: " continue

if [[ "$continue" = "n" ]]; then
   exit 1
fi

printf "\n==================== 1.2 Dependency checks =======================\n"
printf "\nPlease complete the following dependency checks\n"

printf "* Update the base image dependencies for Python container Images
* Update the Go version for container builds
Steps to do so can be found \e]8;;https://github.com/apache/beam/blob/master/contributor-docs/release-guide.md#dependency-checks\e\\here\n\e]8;;\e\\"

read -r -p "Continue [y/n]: " continue

if [[ "$continue" = "n" ]]; then
    exit 1
fi


printf "\n==================== 1.3 Cut the release branch =======================\n"
gh workflow run cut_release_branch.yml


printf "\nPlease complete and confirm the following:
* The master branch has the SNAPSHOT/dev version incremented.
* The release branch has the SNAPSHOT/dev version to be released.
* The Dataflow container image should be modified to the version to be released.
* Due to current limitation in the workflow, you must navigate to https://github.com/apache/beam/actions/workflows/beam_Release_NightlySnapshot.yml and click 'Run workflow' and select the branch just created (release-2.xx.0) to build a snapshot.
* Manually update CHANGES.md on master by adding a new section for the next release (example).\n"

read -r -p "Continue [y/n]: " continue

if [[ "$continue" = "n" ]]; then
    exit 1
fi