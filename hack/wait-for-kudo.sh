#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

attempt_counter=0
max_attempts=120

while [ "$(kubectl get sts -n kudo-system kudo-controller-manager -o jsonpath='{.status.readyReplicas}')" != "1" ]; do
    if [ ${attempt_counter} -eq ${max_attempts} ];then
      printf "\nFailed to reach KUDO manager webhook"
      exit 1
    fi

    printf '.'
    attempt_counter=$((attempt_counter+1))
    sleep 1
done