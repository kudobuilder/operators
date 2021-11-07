#!/usr/bin/env bash

# script to make "community" operator repository index file
# using the build/repo as a source and merging with an operator repository


set -o errexit
set -o nounset
set -o pipefail

CMD=kubectl-kudo
REPO_DIR=build/repo


# script requires kudo `kubectl-kudo` to be installed and in the path
command -v $CMD >/dev/null 2>&1 || { echo >&2 "$CMD is required in the path.  Aborting."; exit 1; }


# output of kudo version for human or ci logs
version=$($CMD version)
echo "Using $version"

# the build dir must be created
# we don't "clean" it because a user may want to build multiple operators to it at a time

if [[ ! -d "${REPO_DIR}" ]]; then
  # this script doesn't make a repo build dir... fails if it doesn't exist
  echo 1>&2 "$REPO_DIR does not exist"
  exit 1
fi


# test to confirm community repo is configured
# this command will fail non-zero unless it exists
$CMD repo context community

$CMD repo index $REPO_DIR --merge-repo community --url-repo community
