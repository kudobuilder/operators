#!/usr/bin/env bash

# script to remove kudo operator build directory

set -o errexit
set -o nounset
set -o pipefail

REPO_DIR=build/repo


if [[ -d "${REPO_DIR}" ]]; then
  rm -rf $REPO_DIR
fi
