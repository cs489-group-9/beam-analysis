#!/usr/bin/env bash

read -r -p "RELEASE_VERSION: " RELEASE_VERSION

read -r -p "RC_NUM: " RC_NUM

read -r -p "COMMIT_REF: " COMMIT_REF


# echo $RELEASE_VERSION $RC_NUM $COMMIT_REF


printf "\n==================== 3.1 Tag a chosen commit for the RC =======================\n"

read -r -p "Do you want to do a dry run [y/n]: " dry_run
read -r -p "Do you already have a cloned repo that includes the commit ref ${COMMIT_REF} [y/n]: " dont_need_clone

# echo $dry_run $dont_need_clone

if [[ "$dry_run" == "y" && "$dont_need_clone" == "y" ]]; then 
     # echo "dry run and don't need clone"
     ./release/src/main/scripts/choose_rc_commit.sh \
     --release "${RELEASE_VERSION}" \
     --rc "${RC_NUM}" \
     --commit "${COMMIT_REF}"
elif [[ "$dry_run" = "y" && "$dont_need_clone" = "n" ]]; then
     # echo "dry run, need clone"
     ./release/src/main/scripts/choose_rc_commit.sh \
     --release "${RELEASE_VERSION}" \
     --rc "${RC_NUM}" \
     --commit "${COMMIT_REF}" \
     --clone
elif [[ "$dry_run" = "n" && "$dont_need_clone" = "y" ]]; then
     # echo "not a dry run, dont need clone"
     ./release/src/main/scripts/choose_rc_commit.sh \
     --release "${RELEASE_VERSION}" \
     --rc "${RC_NUM}" \
     --commit "${COMMIT_REF}" \
     --push-tag
else
     # echo "not a dry run, need clone"
     ./release/src/main/scripts/choose_rc_commit.sh \
     --release "${RELEASE_VERSION}" \
     --rc "${RC_NUM}" \
     --commit "${COMMIT_REF}" \
     --clone \
     --push-tag
fi

printf "\n\nPlease confirm the following...
* The release branch is unchanged.
* There is a commit not on the release branch with the version adjusted.
* The RC tag points to that commit.\n"

read -r -p "Continue [y/n]: " continue
# echo $continue

if [[ "$continue" = "n" ]]; then
     exit 0
fi

printf "\n==================== 3.2 Run build_release_candidate GitHub Action to create a release candidate =======================\n"
# NOTE!!! need to 1. configure github cli (e..g brew install gh), set up auth, and then make sure the github actions ur calling (the yml files) have on: workflow_dispatch
gh workflow run build_release_candidate.yml #--ref idk NEED TO CHOOSE THE RIGHT REF.. i think its just the release branch?

printf "\n\nPlease verify the following...
* The source zip of the whole project is present in dist.apache.org.
* The Python binaries are present in dist.apache.org.\n"

read -r -p "Continue [y/n]: " continue

if [[ "$continue" = "n" ]]; then
     exit 0
fi

printf "\n==================== 3.3 Verify docker images =======================\n"
RC_TAG=${RELEASE_VERSION}rc${RC_NUM}
for pyver in 3.8 3.9 3.10 3.11; do
docker run --rm --entrypoint sh \
     apache/beam_python${pyver}_sdk:${RC_TAG} \
     -c 'ls -al /opt/apache/beam/third_party_licenses/ | wc -l'
done

for javaver in 8 11 17; do
docker run --rm --entrypoint sh \
     apache/beam_java${javaver}_sdk:${RC_TAG} \
     -c 'ls -al /opt/apache/beam/third_party_licenses/ | wc -l'
done

printf "\n==================== 3.4 Publish Java staging artifacts (manual) =======================\n"
printf "1. Log in to the Apache Nexus website.
2. Navigate to Build Promotion -> Staging Repositories (in the left sidebar).
3. Select repository orgapachebeam-NNNN.
4. Click the Close button.
5. When prompted for a description, enter “Apache Beam, version X, release candidate Y”.
6. Review all staged artifacts on https://repository.apache.org/content/repositories/orgapachebeam-NNNN/. They should contain all relevant parts for each module, including pom.xml, jar, test jar, javadoc, etc. Artifact names should follow the existing format in which artifact name mirrors directory structure, e.g., beam-sdks-java-io-kafka. Carefully review any new artifacts. Some additional validation should be done during the rc validation step.\n"

read -r -p "Continue [y/n]: " continue
# echo $continue

if [[ "$continue" = "n" ]]; then
     exit 0
fi

printf "\n==================== 3.5 Upload rc artifacts to PyPI =======================\n"
gh workflow run deploy_release_candidate_pypi

printf "\n\nPlease verify the following...
* The File names version include rc-# suffix
* Download Files have: 
     - [ ] All wheels uploaded as artifacts 
     - [ ] Release source's zip published 
     - [ ] Signatures and hashes do not need to be uploaded\n"

read -r -p "Continue [y/n]: " continue

if [[ "$continue" = "n" ]]; then
     exit 0
fi

printf "\n==================== 3.6 Propose pull requests for website updates =======================\n"
echo "Please follow the release guide."
