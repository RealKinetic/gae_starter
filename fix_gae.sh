#!/usr/bin/env bash

if [ -z "$VIRTUAL_ENV" ]; then
    echo "Must run in a virtualenv!"
    echo "(this script modifies the current virtualenv's import path)"
    exit 1
fi

file_to_write="$VIRTUAL_ENV/lib/python2.7/site-packages/gae.pth"

if [ -d '/usr/lib/google-cloud-sdk/platform/google_appengine' ]; then
	# On Ubuntu the standard installation method places the google-cloud-sdk folder
	# in this location. However, the tools are spread throughout /usr/ according to
	# Linux convention so we can't rely on searching for `dev_appserver.py`.
	echo "Detected installation of gcloud in /usr/lib/"

	echo '/usr/lib/google-cloud-sdk/platform/google_appengine' \
	    > "$file_to_write"
else
	echo "Determining gcloud location based on 'dev_appserver.py'"

	echo "$(dirname "$(dirname "$(which dev_appserver.py)")")/platform/google_appengine" \
	    > "$file_to_write"
fi

echo 'import dev_appserver; dev_appserver.fix_sys_path();' >> "$file_to_write"
echo "Updated '$file_to_write'"

