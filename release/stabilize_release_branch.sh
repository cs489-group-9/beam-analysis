#!/usr/bin/env bash

echo "stabilize release branch"

printf "\n\nPlease confirm the following...
* The release branch is cut, builds, and has no significant issues\n"

read -r -p "Continue [y/n]: " continue
# echo $continue

if [[ "$continue" = "n" ]]; then
     exit 0
fi

printf "Verify the Release Branch by running verify_release_build.sh\n"
./release/src/main/scripts/verify_release_build.sh

printf "Investigate Performance Regressions\n"
printf "Check Beam load tests for possible regressions. Measurements are available at http://metrics.beam.apache.org/"

printf "Triage release-blocking issues in Github\n"
printf "Instructions are available at https://github.com/apache/beam/blob/master/contributor-docs/release-guide.md#triage-release-blocking-issues-in-github"

printf "Review cherry-picks\n"
printf "Instructions are available at https://github.com/apache/beam/blob/master/contributor-docs/release-guide.md#review-cherry-picks"

