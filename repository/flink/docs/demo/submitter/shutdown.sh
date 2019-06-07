#!/bin/bash

set -e
set -x

# kubectl patch configmap $CONFIGMAP -p '{"data": {"jobid": "'$job_id'"}}'
job_id=`kubectl get configmap ${CONFIGMAP} -o jsonpath="{.data.jobid}"`

echo "Stopping JobID $job_id"

job_info=`curl -s \
$JOBMANAGER:8081/jobs/$job_id | jq . `

echo "Job Info:"
echo "$job_info"

# Check to see if the job is still running or not.
state=`echo $job_info | jq -r .state`

if [ "$state" != "RUNNING" ] ; then 
    echo "Job is not running, so I don't know how to stop it yet."
    exit 1
fi

# if its still running,

echo "Triggering Savepoint"


#We probably want a different savepoint location
savepoint_response=`curl -s -XPOST \
-d '{"target-directory":"/ha/savepoints/'${job_id}'","cancel-job":"true"}' \
$JOBMANAGER:8081/jobs/$job_id/savepoints` 

echo "Savepoint Response:"
echo "${savepoint_response}"

response_id=`echo ${savepoint_response} | jq -r '.["request-id"]'`
savepoint=`curl -s $JOBMANAGER:8081/jobs/$job_id/savepoints/${response_id}`
while [ "$( echo $savepoint | jq -r .status.id)" != "COMPLETED" ]; do
    echo "Shutting down..."
    sleep 1
    savepoint=`curl -s $JOBMANAGER:8081/jobs/$job_id/savepoints/${response_id}`
done

location=`echo $savepoint | jq -r .operation.location`

if [ "$location" != "" ] ; then 
    kubectl patch configmap $CONFIGMAP -p '{"data": {"location": "'$location'"}}'
    echo "Savepoint successful made, and job shut down"
else
    echo "Location not returned in final save status.  Not sure what went wrong:"
    echo "Final Save:"
    echo "$final_save" | jq .
fi

