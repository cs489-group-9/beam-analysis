#!/usr/bin/env bash

printf "\nPlease complete the following:
* Announce release on the user@ mailing list.
* Public blog post, if applicable.
* Record release in reporter.apache.org.
* Announce release on social media.
* Declare release completion on the dev@ mailing list.
* Update the Wikipedia Apache Beam article.\n"

read -r -p "Done [y/n]: " continue

if [[ "$continue" = "n" ]]; then
     exit 1
fi

