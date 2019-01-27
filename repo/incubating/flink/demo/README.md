# Flink

## Flink Demo

This demo follows the outline provided by [DCOS's](https://github.com/dcos/demos/tree/master/flink-k8s/1.11) demo

### Architecture

We should modify the demo image to have everything run on K8s

## Prerequisites

If you run on Minikube run first:

`minikube ssh 'sudo ip link set docker0 promisc on'`

Install all required frameworks:

- `kubectl apply -f https://raw.githubusercontent.com/maestrosdk/frameworks/master/repo/stable/zookeeper/versions/0/zookeeper-framework.yaml`
- `kubectl apply -f https://raw.githubusercontent.com/maestrosdk/frameworks/master/repo/stable/zookeeper/versions/0/zookeeper-frameworkversion.yaml`
- `kubectl apply -f https://raw.githubusercontent.com/maestrosdk/frameworks/master/repo/stable/kafka/versions/0/kafka-framework.yaml`
- `kubectl apply -f https://raw.githubusercontent.com/maestrosdk/frameworks/master/repo/stable/kafka/versions/0/kafka-frameworkversion.yaml`
- `kubectl apply -f https://raw.githubusercontent.com/maestrosdk/frameworks/master/repo/incubating/flink/versions/0/flink-framework.yaml`
- `kubectl apply -f https://raw.githubusercontent.com/maestrosdk/frameworks/master/repo/incubating/flink/versions/0/flink-frameworkversion.yaml`

## Getting Started

Install the `flink-financial-demo` via:

`kubectl apply -f https://raw.githubusercontent.com/maestrosdk/frameworks/master/repo/incubating/flink/demo/flink-demo.yaml`

To see if Flink is working properly run:

`kubectl proxy` and access in your web-browser: http://127.0.0.1:8001/api/v1/namespaces/default/services/demo-flink-jobmanager:ui/proxy/#/overview

Wait until Zookeeper, Kafka and Flink are healthy and running.
Once everything is up, start the job:

### Deploy Upload Plan

```bash
cat <<EOF | kubectl apply -f -
apiVersion: maestro.k8s.io/v1alpha1
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