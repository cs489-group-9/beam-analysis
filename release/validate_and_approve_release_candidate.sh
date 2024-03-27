#!/usr/bin/env bash
printf "\nPlease follow the instructions on https://github.com/apache/beam/blob/master/contributor-docs/release-guide.md#vote-and-validate-the-release-candidate up until 'Run validation tests'\n"
read -r -p "Continue [y/n]: " continue

if [[ "$continue" = "n" ]]; then
     exit 0
fi

printf "\n==================== Run validations using run_rc_validation.sh =======================\n"
printf "\nPlease update required configurations listed in RC_VALIDATE_CONFIGS in script.config\n"

read -r -p "Done [y/n]: " continue

if [[ "$continue" = "n" ]]; then
     exit 0
fi
 
./release/src/main/scripts/run_rc_validation.sh

printf "\n\n Please complete the following:
* Check whether validations succeed by following console output instructions.
* Terminate streaming jobs and java injector.
* Run Java quickstart (wordcount) and mobile game examples with the staged artifacts. The easiest way to do this is by running the tests on GitHub Actions.
* Other manual validation will follow, but this will at least validate that the staged artifacts can be used.
    - Go to https://github.com/apache/beam/actions/workflows/beam_PostRelease_NightlySnapshot.yml/.
    - Click 'Run Workflow'.
    - Set RELEASE to 2.xx.0, and set SNAPSHOT_URL to point to the staged artifacts in Maven central (https://repository.apache.org/content/repositories/orgapachebeam-NNNN/).
    - Click "Build".
* Sign up spreadsheet.
* Vote in the release thread.\n"

read -r -p "Continue [y/n]: " continue

if [[ "$continue" = "n" ]]; then
     exit 0
fi

