#!/usr/bin/env bash

# script to remove kudo operator build directory

set -o errexit
set -o nounset
set -o pipefail

REPO_DIR=build/repo
BIN_DIR=bin

if [[ -d "${REPO_DIR}" ]]; then
  rm -rf $REPO_DIR
fi

if [[ -d "${BIN_DIR}" ]]; then
  rm -rf $BIN_DIR
fi
