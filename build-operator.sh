#!/usr/bin/env bash

# script to make kudo operators
# takes form of `./build-operator.sh  repository/kafka/operator/`
# or `./build-operator kafka` which assumes the above common layout
# or `./build-operator cassandra 3.11`

set -o errexit
set -o nounset
set -o pipefail

CMD=kubectl-kudo
REPO_DIR=build/repo


# script requires kudo `kubectl-kudo` to be installed and in the path
command -v $CMD >/dev/null 2>&1 || { echo >&2 "$CMD is required in the path.  Aborting."; exit 1; }

# which operator to build must be passed
if [ $# -lt 1 ]; then
  echo 1>&2 "Usage: $0 path_to_operator [optional_version]"
  exit 1
fi

# convenience assumption which allow for operator name only
# for pass in.  `./build-operator kafka`
# or `./build-operator cassandra 3.11`
if [ $# -eq 2 ]; then
  OP_DIR="repository/${1}/${2}/operator/"
else
  OP_DIR="repository/${1}/operator/"
fi

# the passed in operator must be the operator folder
if [[ ! -d "${OP_DIR}" ]]; then
  OP_DIR="${1}"
fi

# the passed in operator must be the operator folder
if [[ ! -d "${OP_DIR}" ]]; then
  echo 1>&2 "Usage: $0 path_to_operator [optional_version]"
  echo 1>&2 "$1 is not a directory"
  exit 1
fi

# output of kudo version for human or ci logs
version=$($CMD version)
echo "Using $version"

# the build dir must be created
# we don't "clean" it because a user may want to build multiple operators to it at a time

if [[ ! -d "${REPO_DIR}" ]]; then
  # if repo dir doesn't exist create it
  mkdir -p $REPO_DIR
fi

$CMD package create "$OP_DIR" --destination $REPO_DIR
