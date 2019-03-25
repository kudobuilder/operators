#!/bin/bash

set -e
set -x
#Requires the following environment variables
# CONFIGMAP - name fo the configmap that will get patched with the jobid

# Variables
PARALLELISM=${PARALLELISM:-1}

ls -la ${JAR_PATH}
cp ${JAR_PATH} .
JAR=$(basename ${JAR_PATH})
echo "Local jar is $JAR"
ls -la ${JAR}

# Assume local JAR for upload
filename=`curl -X POST -H "Expect:" -F "jarfile=@${JAR_PATH}" $JOBMANAGER:8081/jars/upload`

echo "Filename: $filename"
raw=`echo $filename | jq -r .filename`
echo "Raw: $raw"
# Jar ID is just the last part of the filename
jar_id=`basename $raw`
echo "JarID: $jar_id"
# Start the job

job_response=`curl -s -XPOST \
-d '{"entryClass":"'"${CLASSNAME}"'","programArgs":"'"${PROGRAM_ARGS}"'","parallelism":"'"${PARALLELISM}"'","savepointPath":"'"${SAVEPOINT_PATH}"'"}' \
$JOBMANAGER:8081/jars/$jar_id/run` 

echo "Submitting Job... Response: $job_response"

job_id=`echo $job_response | jq -r .jobid`

echo "JobID: $job_id"
kubectl patch configmap $CONFIGMAP -p '{"data": {"jobid": "'$job_id'"}}'


