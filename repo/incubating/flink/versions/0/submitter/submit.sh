#!/bin/bash

set -e
set -x
#Requires the following environment variables
# CONFIGMAP - name fo the configmap that will get patched with the jobid

# Variables
PARALLELISM=${PARALLELISM:-5}


printenv

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

# job_response=`curl -s -XPOST -d '{
#     "program-args": "'"${PROGRAM_ARGS}"'",
#     "parallelism": "'"${PARALLELISM}"'",
#     "entryClass": "'"${CLASSNAME}"'",
# }' $JOBMANAGER:8081/jars/$jar_id/run` 

# job_response=`curl -s -XPOST -d '{
#     "entry-class": "'"${CLASSNAME}"'",
# }' $JOBMANAGER:8081/jars/$jar_id/run` 

job_response=`curl -s -XPOST  "$JOBMANAGER:8081/jars/$jar_id/run?parallelism=10&entry-class=${CLASSNAME}&programArgs=${PROGRAM_ARGS}"` 
echo "Submitting Job... Response: $job_response"

job_id=`echo $job_response | jq -r .jobid`

echo "JobID: $job_id"
kubectl patch configmap $CONFIGMAP -p '{"data": {"jobid": "'$job_id'"}}'

#download
              # 
            #   'export JOB_FILENAME=$(basename $DOWNLOAD_URL); echo "DOWNLOAD_URL: $DOWNLOAD_URL FILE: $JOB_FILENAME JOBMANAGER: $JOBMANAGER"; apk add --no-cache jq curl;
            #   curl -s $DOWNLOAD_URL -o $JOB_FILENAME;
            #   curl -s -X POST -H "Expect:" -F "jarfile=@$JOB_FILENAME" $JOBMANAGER:8081/jars/upload;
            #   while true; do date; export JAR_ID=$(curl -s $JOBMANAGER:8081/jars | jq -r ".files[].id");
            #   if [ -z $JAR_ID ];
            #   then
            #   echo "No uploaded jar detected";
            #   else
            #   echo "Found jar $JAR_ID";
            #   export SUBMIT_MSG=$(curl -s -X POST -H "Expect:" $JOBMANAGER:8081/jars/$JAR_ID/run?program-args=--kafka_host%20{{NAME}}-kafka-kafka-1.{{NAME}}-kafka-svc.default.svc.cluster.local:9093 | jq -r ".errors");
            #   echo "RESPONSE: $SUBMIT_MSG";
            #   if [ $SUBMIT_MSG == "null" ];
            #   then
            #   echo "SUBMITTED JOB!";
            #   exit 0;
            #   else
            #   echo "Failed to submit job: $SUBMIT_MSG";
            #   fi;
            #   fi;
            #   echo "=====================";
