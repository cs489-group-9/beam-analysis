#!/usr/bin/env bash

printf "\n==================== 2.1 Verify release branch =======================\n"
./release/src/main/scripts/verify_release_build.sh

printf "\n==================== 2.2 Investigate Performance Regressions =======================\n"
printf "Check Beam load tests for possible regressions. Measurements are available at http://metrics.beam.apache.org/\n"
read -r -p "Continue [y/n]: " continue

if [[ "$continue" = "n" ]]; then
    exit 1
fi


printf "\n==================== 2.3 Triage release-blocking issues in Github =======================\n"
printf "Instructions are available \e]8;;https://github.com/apache/beam/blob/master/contributor-docs/release-guide.md#triage-release-blocking-issues-in-github\e\\here\n\e]8;;\e\\"

read -r -p "Continue [y/n]: " continue

if [[ "$continue" = "n" ]]; then
    exit 1
fi


printf "\n==================== 2.4 Review cherry-picks =======================\n"
printf "Instructions are available \e]8;;https://github.com/apache/beam/blob/master/contributor-docs/release-guide.md#review-cherry-picks\e\\here\n\e]8;;\e\\"
read -r -p "Continue [y/n]: " continue

if [[ "$continue" = "n" ]]; then
    exit 1
fi


