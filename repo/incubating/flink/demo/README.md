# Flink

## Flink Demo

This demo follows the outline provided by [DCOS's](https://github.com/dcos/demos/tree/master/flink-k8s/1.11) demo

### Architecture

We should modify the demo image to have everything run on K8s

## Prerequisites

If you run on Minikube run first:

`minikube ssh 'sudo ip link set docker0 promisc on'`

Install all required frameworks:

- `kubectl apply -f https://raw.githubusercontent.com/kudobuilder/frameworks/master/repo/stable/zookeeper/versions/0/zookeeper-framework.yaml`
- `kubectl apply -f https://raw.githubusercontent.com/kudobuilder/frameworks/master/repo/stable/zookeeper/versions/0/zookeeper-frameworkversion.yaml`
- `kubectl apply -f https://raw.githubusercontent.com/kudobuilder/frameworks/master/repo/stable/kafka/versions/0/kafka-framework.yaml`
- `kubectl apply -f https://raw.githubusercontent.com/kudobuilder/frameworks/master/repo/stable/kafka/versions/0/kafka-frameworkversion.yaml`
- `kubectl apply -f https://raw.githubusercontent.com/kudobuilder/frameworks/master/repo/incubating/flink/versions/0/flink-framework.yaml`
- `kubectl apply -f https://raw.githubusercontent.com/kudobuilder/frameworks/master/repo/incubating/flink/versions/0/flink-frameworkversion.yaml`

## Getting Started

Install the `flink-financial-demo` via:

`kubectl apply -f https://raw.githubusercontent.com/kudobuilder/frameworks/master/repo/incubating/flink/demo/flink-demo.yaml`

To see if Flink is working properly run:

`kubectl proxy` and access in your web-browser: http://127.0.0.1:8001/api/v1/namespaces/default/services/demo-flink-jobmanager:ui/proxy/#/overview

Wait until Zookeeper, Kafka and Flink are healthy and running.
Once everything is up, start the job:

### Deploy Upload Plan

```bash
cat <<EOF | kubectl apply -f -
apiVersion: kudo.k8s.io/v1alpha1
kind: PlanExecution
metadata:
  labels:
    framework-version: flink-financial-demo
    instance: demo-flink-submit-job
  name: flink-submit-job
  namespace: default
spec:
  instance:
    kind: Instance
    name: demo
    namespace: default
  planName: upload
EOF
```

To get the job output:

```bash
$ kubectl logs $(kubectl get pod -l planexecution=flink-submit-job -o jsonpath="{.items[0].metadata.name}")
DOWNLOAD_URL: https://downloads.mesosphere.com/dcos-demo/flink/flink-job-1.0.jar FILE: flink-job-1.0.jar JOBMANAGER: demo-flink-jobmanager
fetch http://dl-cdn.alpinelinux.org/alpine/v3.8/main/x86_64/APKINDEX.tar.gz
fetch http://dl-cdn.alpinelinux.org/alpine/v3.8/community/x86_64/APKINDEX.tar.gz
(1/7) Installing ca-certificates (20171114-r3)
(2/7) Installing nghttp2-libs (1.32.0-r0)
(3/7) Installing libssh2 (1.8.0-r3)
(4/7) Installing libcurl (7.61.1-r1)
(5/7) Installing curl (7.61.1-r1)
(6/7) Installing oniguruma (6.8.2-r0)
(7/7) Installing jq (1.6_rc1-r1)
Executing busybox-1.28.4-r2.trigger
Executing ca-certificates-20171114-r3.trigger
OK: 15 MiB in 24 packages
{"filename":"/tmp/flink-web-1324b551-a734-43fe-824b-396d7760647c/flink-web-upload/684b6919-9e66-4064-94d9-22641c9c2fb1_flink-job-1.0.jar","status":"success"}Thu Jan 24 04:59:15 UTC 2019
No uploaded jar detected
=====================
Thu Jan 24 04:59:20 UTC 2019
Found jar 684b6919-9e66-4064-94d9-22641c9c2fb1_flink-job-1.0.jar
RESPONSE: null
SUBMITTED JOB!
```

To get the fraud output from the actor:

```bash
kubectl logs $(kubectl get pod -l step=act -o jsonpath="{.items[0].metadata.name}")
```




## Modifications 

### Flink Cluster Framework

Creates a Flink Cluster

### Flink Application

Runs an application on a Flink Cluster
References a FlinkCluster Instance, or creates one 



One flink cluster per jar

Spec:
1) Jar location
2) Program arguments

### Startup

1) Download jar
   To do this, we can start a Job that downloads the Jar from the provided URL and stores it in a PV that gets creatd.
2) Flink job Manager
   Startup the flink job manager with the jar PV mounted at /data/jars
   HA PV at /data/ha
   Snapshots PV at /data/snapshots
3) Start Task Managers
4) Start the job (with Arguments!)


### Update cluster
1) Snapshot and stop job
2) Rollout Jobmanager and Task manager changes
3) restart job from Snapshot




### Upload Jar

```bash
# fail if returns an error
set -e 
#Download the jar
wget https://downloads.mesosphere.com/dcos-demo/flink/flink-job-1.0.jar
# Upload the jar to the jobmanager
filename=`curl -s -X POST \
 -H 'Content-Type: multipart/form-data; boundary=----WebKitFormBoundary' --data-binary $'------WebKitFormBoundary\r\nContent-Disposition: form-data; name="jarfile"; filename="flink-job-1.0.jar"\r\nContent-Type: application/java-archive\r\n\r\n\r\n------WebKitFormBoundary--\r\n' --compressed $JOBMANAGER:8081/jars/upload`
raw=`echo $filename | jq -r .filename`
# Jar ID is just the last part of the filename
jar_id=`basename $raw`
# 
```

curl 'http://localhost:30000/jars/upload' -H 'Referer: http://localhost:30000/' -H 'Origin: http://localhost:30000' -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.75 Safari/537.36' -H 'Content-Type: multipart/form-data; boundary=----WebKitFormBoundaryWXjfk6ihVHVAvLfs' --data-binary $'------WebKitFormBoundaryWXjfk6ihVHVAvLfs\r\nContent-Disposition: form-data; name="jarfile"; filename="flink-job-1.0.jar"\r\nContent-Type: application/java-archive\r\n\r\n\r\n------WebKitFormBoundaryWXjfk6ihVHVAvLfs--\r\n' --compressed

```
flink run -m application-mycluster-jobmanager:8081 -d -p 1 flink-job-1.0.jar --kafka_host=small-kafka-0.small-svc:9093
```


curl -X POST \
-H 'Content-Type: application/java-archive' \
--data-binary @flink-job-1.0.jar \
$JOBMANAGER:8081/jars/upload


Once the jobs submitted we have to save the jobID so its usable by the restart:

1) add a configmap that'll be used to store the jobid
2) in the start job we'll patch the object
K8S=https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_SERVICE_PORT
TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
CACERT=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
NAMESPACE=$(cat /var/run/secrets/kubernetes.io/serviceaccount/namespace)
curl -H "Authorization: Bearer $TOKEN" --cacert $CACERT $K8S/healthz

???
curl  -H "Content-Type: application/merge-patch+json" --cacert $CACERT -H "Authorization: Bearer $TOKEN" -X PATCH $K8S/api/v1/namespaces/$NAMESPACE/configmaps/application -d '{ "data": {"jobid": "NEWVALUE"}}'

3 ) the default SA needs to have admin permission