#!/bin/sh

attempt_counter=0
max_attempts=120
#url=https://kudo-controller-manager-service.kudo-system.svc:443/admit-kudo-dev-v1beta1-instance
url=https://localhost:443/admit-kudo-dev-v1beta1-instance

until curl --insecure --output /dev/null --silent --head --fail $url
do
    if [ ${attempt_counter} -eq ${max_attempts} ];then
      echo "Failed to reach KUDO manager webhook: $url"
      exit 1
    fi

    printf '.'
    attempt_counter=$((attempt_counter+1))
    sleep 1
done