#!/usr/bin/env bash

echo "finalize release"

read -r -p "RELEASE_VERSION: " RELEASE_VERSION
read -r -p "OLD_RELEASE_VERSION: " OLD_RELEASE_VERSION



printf "Deploy Artifacts to Maven Central Repository\n"
printf "\nPlease upload the key on the \e]8;;https://repository.apache.org/#stagingRepositories\e\\Apache Nexus Respository Manager\n\e]8;;\e\\"

printf "Deploying Python Artifacts, Docker Images, and Tagging Releases\n"

gh workflow run finalize_release.yml

printf "\nVerify that everything is correct before moving on to the next step...
* Verify that the files at https://pypi.org/project/apache-beam/#files are correct. All wheels should be published, in addition to the zip of the release source. (Signatures and hashes do not need to be uploaded.)
* Images are published at DockerHub with tags {RELEASE_VERSION} and latest.
* Images with latest tag are pointing to current release by confirming the digest of the image with latest tag is the same as the one with {RELEASE_VERSION} tag.
* v{RELEASE_VERSION} and sdks/v{RELEASE_VERSION} tags should be visible on Github's Tags page.\n"

read -r -p "Continue [y/n]: " continue

if [[ "$continue" = "n" ]]; then
    exit 0
fi

printf "PMC-Only Finalization\n"

printf "\nCopy source release from dev to the release repository at dist.apache.org\n"

svn co https://dist.apache.org/repos/dist/dev/beam dev  # Checkout the `dev` artifact repo.

svn co https://dist.apache.org/repos/dist/release/beam release  # Checkout the `release` artifact repo.

mkdir release/${RELEASE_VERSION}

cp -R dev/${RELEASE_VERSION}/* release/${RELEASE_VERSION}/

cd release

svn add ${RELEASE_VERSION}

svn rm ${OLD_RELEASE_VERSION}   # Delete all artifacts from old releases.

svn commit -m "Adding artifacts for the ${RELEASE_VERSION} release and removing old artifacts"