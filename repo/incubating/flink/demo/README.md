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

Creates a Flink Cluster.  This creates a Highly avaialble cluster with 1 JobManager and 2 TaskManagers by default.

### Flink Application

Runs an application on a Flink Cluster.  The FlinkInstance Cluster could either be referenced by name (in the same namespace(need to test this)), 
or setting the `DEPLOY_OWN_CLUSTER: "yes"` will deploy a dedicated cluster to use.



### Modification Demo

This has currently only been tested with:
1) A jar that's present on the Flink Image
2) A Cluster deployed as part of the FlinkApplication instance

Install dependencies
```bash
kubectl apply -f repo/incubating/flink/versions/0/flinkcluster-framework.yaml
kubectl apply -f repo/incubating/flink/versions/0/flinkcluster-frameworkversion.yaml
kubectl apply -f repo/incubating/flink/versions/0/flinkapplication-framework.yaml
kubectl apply -f repo/incubating/flink/versions/0/flinkapplication-frameworkversion.yaml
```

Create a Zookeeper 
```bash
$ kubectl apply -f repo/stable/zookeeper/versions/0/
$ kubectl get pods -w
NAME                         READY   STATUS              RESTARTS   AGE
zk-zk-0                      0/1     Running             0          4s
zk-zk-1                      0/1     ContainerCreating   0          4s
zk-zk-2                      0/1     Pending             0          4s
zk-zk-2   0/1   ContainerCreating   0     4s
zk-zk-1   0/1   Running   0     5s
zk-zk-2   0/1   Running   0     7s
zk-zk-0   1/1   Running   0     18s
zk-zk-2   1/1   Running   0     21s
zk-zk-1   1/1   Running   0     23s
```

Create a Kafka cluster 
```bash
$ kubectl apply -f repo/stable/kafka/versions/0/
$ kubectl get pods -w
NAME      READY   STATUS              RESTARTS   AGE
small-kafka-0   0/1   Pending   0     1s
small-kafka-0   0/1   Pending   0     1s
small-kafka-0   0/1   Pending   0     1s
small-kafka-0   0/1   ContainerCreating   0     1s
small-kafka-0   0/1   Running   0     18s
small-kafka-0   1/1   Running   0     26s
small-kafka-1   0/1   Pending   0     1s
small-kafka-1   0/1   Pending   0     1s
small-kafka-1   0/1   Pending   0     1s
small-kafka-1   0/1   ContainerCreating   0     1s
small-kafka-1   0/1   Running   0     3s
small-kafka-1   1/1   Running   0     10s
small-kafka-2   0/1   Pending   0     1s
small-kafka-2   0/1   Pending   0     1s
small-kafka-2   0/1   Pending   0     1s
small-kafka-2   0/1   ContainerCreating   0     1s
small-kafka-2   0/1   Running   0     3s
small-kafka-2   1/1   Running   0     9s
```

and a Flink Application
```bash
$ kubectl apply -f repo/incubating/flink/versions/0/flinkapplication-instance.yaml
$ kubectl get pods -w
NAME                                 READY   STATUS              RESTARTS   AGE
application-mycluster-jobmanager-0   0/1     ContainerCreating   0          2s
zk-zk-0                              1/1     Running             0          72s
zk-zk-1                              1/1     Running             0          72s
zk-zk-2                              1/1     Running             0          72s
application-mycluster-taskmanager-78cf898476-lzhcr   0/1   Pending   0     0s
application-mycluster-taskmanager-78cf898476-lzhcr   0/1   Pending   0     0s
application-mycluster-taskmanager-78cf898476-m6qdh   0/1   Pending   0     0s
application-mycluster-taskmanager-78cf898476-m6qdh   0/1   Pending   0     0s
application-mycluster-taskmanager-78cf898476-lzhcr   0/1   ContainerCreating   0     0s
application-mycluster-taskmanager-78cf898476-m6qdh   0/1   ContainerCreating   0     0s
application-mycluster-jobmanager-0   1/1   Running   0     2s
application-mycluster-taskmanager-78cf898476-lzhcr   1/1   Running   0     3s
application-mycluster-taskmanager-78cf898476-m6qdh   1/1   Running   0     5s
```

The creation of the Job should happen during deployment, but we currently have it separated into a separate plan to allow better control. Yes we know there's a lot of environment variables at the top

```bash
$ kubectl apply -f repo/incubating/flink/demo/scratch/submit.yaml
$ kubectl logs jobs/application-submit-flink-job
+ PARALLELISM=1
+ ls -la /opt/flink/examples/streaming/StateMachineExample.jar
-rw-r--r-- 1 flink flink 1156313 Feb 11 14:47 /opt/flink/examples/streaming/StateMachineExample.jar
+ cp /opt/flink/examples/streaming/StateMachineExample.jar .
++ basename /opt/flink/examples/streaming/StateMachineExample.jar
+ JAR=StateMachineExample.jar
+ echo 'Local jar is StateMachineExample.jar'
+ ls -la StateMachineExample.jar
Local jar is StateMachineExample.jar
-rw-r--r-- 1 root root 1156313 Mar 25 02:18 StateMachineExample.jar
++ curl -X POST -H Expect: -F jarfile=@/opt/flink/examples/streaming/StateMachineExample.jar application-mycluster-jobmanager:8081/jars/upload
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 1129k  100   120  100 1129k   1684  15.4M --:--:-- --:--:-- --:--:-- 15.5M
+ filename='{"filename":"/ha/data/flink-web-upload/fddce157-ec3c-44bf-bdb5-c9a6b5bdf046_StateMachineExample.jar","status":"success"}'
+ echo 'Filename: {"filename":"/ha/data/flink-web-upload/fddce157-ec3c-44bf-bdb5-c9a6b5bdf046_StateMachineExample.jar","status":"success"}'
Filename: {"filename":"/ha/data/flink-web-upload/fddce157-ec3c-44bf-bdb5-c9a6b5bdf046_StateMachineExample.jar","status":"success"}
++ echo '{"filename":"/ha/data/flink-web-upload/fddce157-ec3c-44bf-bdb5-c9a6b5bdf046_StateMachineExample.jar","status":"success"}'
++ jq -r .filename
+ raw=/ha/data/flink-web-upload/fddce157-ec3c-44bf-bdb5-c9a6b5bdf046_StateMachineExample.jar
+ echo 'Raw: /ha/data/flink-web-upload/fddce157-ec3c-44bf-bdb5-c9a6b5bdf046_StateMachineExample.jar'
Raw: /ha/data/flink-web-upload/fddce157-ec3c-44bf-bdb5-c9a6b5bdf046_StateMachineExample.jar
++ basename /ha/data/flink-web-upload/fddce157-ec3c-44bf-bdb5-c9a6b5bdf046_StateMachineExample.jar
JarID: fddce157-ec3c-44bf-bdb5-c9a6b5bdf046_StateMachineExample.jar
+ jar_id=fddce157-ec3c-44bf-bdb5-c9a6b5bdf046_StateMachineExample.jar
+ echo 'JarID: fddce157-ec3c-44bf-bdb5-c9a6b5bdf046_StateMachineExample.jar'
++ curl -s -XPOST -d '{"entryClass":"org.apache.flink.streaming.examples.statemachine.StateMachineExample","programArgs":"--error-rate 0.05 --sleep 50","parallelism":"1","savepointPath":""}' application-mycluster-jobmanager:8081/jars/fddce157-ec3c-44bf-bdb5-c9a6b5bdf046_StateMachineExample.jar/run
+ job_response='{"jobid":"19f12f073433d71d3dd360d93ba74f29"}'
+ echo 'Submitting Job... Response: {"jobid":"19f12f073433d71d3dd360d93ba74f29"}'
Submitting Job... Response: {"jobid":"19f12f073433d71d3dd360d93ba74f29"}
++ echo '{"jobid":"19f12f073433d71d3dd360d93ba74f29"}'
++ jq -r .jobid
+ job_id=19f12f073433d71d3dd360d93ba74f29
+ echo 'JobID: 19f12f073433d71d3dd360d93ba74f29'
+ kubectl patch configmap application-flink -p '{"data": {"jobid": "19f12f073433d71d3dd360d93ba74f29"}}'
JobID: 19f12f073433d71d3dd360d93ba74f29
```

You should be able now to see the job running in your Flink Dashboard. 
You also should be able to see the detected fraud output in your actor logs:

```bash
$ kubectl logs $(kubectl get pod -l app=flink-demo-actor -o jsonpath={.items..metadata.name})
Broker:   small-kafka-0.small-svc:9093
Topic:   fraud

Detected Fraud:   TransactionAggregate {startTimestamp=0, endTimestamp=1553669518000, totalAmount=11392:
Transaction{timestamp=1553669433000, origin=3, target='1', amount=3202}
Transaction{timestamp=1553669518000, origin=3, target='1', amount=8190}}

Detected Fraud:   TransactionAggregate {startTimestamp=0, endTimestamp=1553669512000, totalAmount=15044:
Transaction{timestamp=1553669457000, origin=9, target='8', amount=6819}
Transaction{timestamp=1553669499000, origin=9, target='8', amount=853}
Transaction{timestamp=1553669512000, origin=9, target='8', amount=7372}}
```

While your job was submitted, the config map with the `jobid` to be used elsewhere was also updated:
```bash
$ kubectl get configmap application-flink -o jsonpath="{ .data.jobid }"
2884cf4cfe7f75c1e5ab5de47ec93e50
```

Stop the job with a savepoint
```
$ kubectl apply -f repo/incubating/flink/demo/scratch/stop.yaml
$ kubectl logs -f jobs/application-stop-flink-job
++ kubectl get configmap application-flink -o 'jsonpath={.data.jobid}'
+ job_id=19f12f073433d71d3dd360d93ba74f29
+ echo 'Stopping JobID 19f12f073433d71d3dd360d93ba74f29'
Stopping JobID 19f12f073433d71d3dd360d93ba74f29
++ curl -s application-mycluster-jobmanager:8081/jobs/19f12f073433d71d3dd360d93ba74f29
++ jq .
Job Info:
+ job_info='{
  "jid": "19f12f073433d71d3dd360d93ba74f29",
  "name": "State machine job",
  "isStoppable": false,
  "state": "RUNNING",
  "start-time": 1553480319794,
  "end-time": -1,
  "duration": 32482,
  "now": 1553480352276,
  "timestamps": {
    "RUNNING": 1553480320786,
    "CANCELED": 0,
    "CREATED": 1553480319794,
    "CANCELLING": 0,
    "FAILED": 0,
    "RESTARTING": 0,
    "SUSPENDED": 0,
    "FAILING": 0,
    "SUSPENDING": 0,
    "FINISHED": 0,
    "RECONCILING": 0
  },
  "vertices": [
    {
      "id": "bc764cd8ddf7a0cff126f51c16239658",
      "name": "Source: Custom Source",
      "parallelism": 1,
      "status": "RUNNING",
      "start-time": 1553480323021,
      "end-time": -1,
      "duration": 29255,
      "tasks": {
        "RECONCILING": 0,
        "CREATED": 0,
        "CANCELED": 0,
        "DEPLOYING": 0,
        "FINISHED": 0,
        "CANCELING": 0,
        "SCHEDULED": 0,
        "RUNNING": 1,
        "FAILED": 0
      },
      "metrics": {
        "read-bytes": 0,
        "read-bytes-complete": false,
        "write-bytes": 0,
        "write-bytes-complete": false,
        "read-records": 0,
        "read-records-complete": false,
        "write-records": 0,
        "write-records-complete": false
      }
    },
    {
      "id": "20ba6b65f97481d5570070de90e4e791",
      "name": "Flat Map -> Sink: Print to Std. Out",
      "parallelism": 1,
      "status": "RUNNING",
      "start-time": 1553480323032,
      "end-time": -1,
      "duration": 29244,
      "tasks": {
        "RECONCILING": 0,
        "CREATED": 0,
        "CANCELED": 0,
        "DEPLOYING": 0,
        "FINISHED": 0,
        "CANCELING": 0,
        "SCHEDULED": 0,
        "RUNNING": 1,
        "FAILED": 0
      },
      "metrics": {
        "read-bytes": 0,
        "read-bytes-complete": false,
        "write-bytes": 0,
        "write-bytes-complete": false,
        "read-records": 0,
        "read-records-complete": false,
        "write-records": 0,
        "write-records-complete": false
      }
    }
  ],
  "status-counts": {
    "RECONCILING": 0,
    "CREATED": 0,
    "CANCELED": 0,
    "DEPLOYING": 0,
    "FINISHED": 0,
    "CANCELING": 0,
    "SCHEDULED": 0,
    "RUNNING": 2,
    "FAILED": 0
  },
  "plan": {
    "jid": "19f12f073433d71d3dd360d93ba74f29",
    "name": "State machine job",
    "nodes": [
      {
        "id": "20ba6b65f97481d5570070de90e4e791",
        "parallelism": 1,
        "operator": "",
        "operator_strategy": "",
        "description": "Flat Map -&gt; Sink: Print to Std. Out",
        "inputs": [
          {
            "num": 0,
            "id": "bc764cd8ddf7a0cff126f51c16239658",
            "ship_strategy": "HASH",
            "exchange": "pipelined_bounded"
          }
        ],
        "optimizer_properties": {}
      },
      {
        "id": "bc764cd8ddf7a0cff126f51c16239658",
        "parallelism": 1,
        "operator": "",
        "operator_strategy": "",
        "description": "Source: Custom Source",
        "optimizer_properties": {}
      }
    ]
  }
}'
+ echo 'Job Info:'
+ echo '{
  "jid": "19f12f073433d71d3dd360d93ba74f29",
  "name": "State machine job",
  "isStoppable": false,
  "state": "RUNNING",
  "start-time": 1553480319794,
  "end-time": -1,
  "duration": 32482,
  "now": 1553480352276,
  "timestamps": {
    "RUNNING": 1553480320786,
    "CANCELED": 0,
    "CREATED": 1553480319794,
    "CANCELLING": 0,
    "FAILED": 0,
    "RESTARTING": 0,
    "SUSPENDED": 0,
    "FAILING": 0,
    "SUSPENDING": 0,
    "FINISHED": 0,
    "RECONCILING": 0
  },
  "vertices": [
    {
      "id": "bc764cd8ddf7a0cff126f51c16239658",
      "name": "Source: Custom Source",
      "parallelism": 1,
      "status": "RUNNING",
      "start-time": 1553480323021,
      "end-time": -1,
      "duration": 29255,
      "tasks": {
        "RECONCILING": 0,
        "CREATED": 0,
        "CANCELED": 0,
        "DEPLOYING": 0,
        "FINISHED": 0,
        "CANCELING": 0,
        "SCHEDULED": 0,
        "RUNNING": 1,
        "FAILED": 0
      },
      "metrics": {
        "read-bytes": 0,
        "read-bytes-complete": false,
        "write-bytes": 0,
        "write-bytes-complete": false,
        "read-records": 0,
        "read-records-complete": false,
        "write-records": 0,
        "write-records-complete": false
      }
    },
    {
      "id": "20ba6b65f97481d5570070de90e4e791",
      "name": "Flat Map -> Sink: Print to Std. Out",
      "parallelism": 1,
      "status": "RUNNING",
      "start-time": 1553480323032,
      "end-time": -1,
      "duration": 29244,
      "tasks": {
        "RECONCILING": 0,
        "CREATED": 0,
        "CANCELED": 0,
        "DEPLOYING": 0,
        "FINISHED": 0,
        "CANCELING": 0,
        "SCHEDULED": 0,
        "RUNNING": 1,
        "FAILED": 0
      },
      "metrics": {
        "read-bytes": 0,
        "read-bytes-complete": false,
        "write-bytes": 0,
        "write-bytes-complete": false,
        "read-records": 0,
        "read-records-complete": false,
        "write-records": 0,
        "write-records-complete": false
      }
    }
  ],
  "status-counts": {
    "RECONCILING": 0,
    "CREATED": 0,
    "CANCELED": 0,
    "DEPLOYING": 0,
    "FINISHED": 0,
    "CANCELING": 0,
    "SCHEDULED": 0,
    "RUNNING": 2,
    "FAILED": 0
  },
  "plan": {
    "jid": "19f12f073433d71d3dd360d93ba74f29",
    "name": "State machine job",
    "nodes": [
      {
        "id": "20ba6b65f97481d5570070de90e4e791",
        "parallelism": 1,
        "operator": "",
        "operator_strategy": "",
        "description": "Flat Map -&gt; Sink: Print to Std. Out",
        "inputs": [
          {
{
  "jid": "19f12f073433d71d3dd360d93ba74f29",
  "name": "State machine job",
  "isStoppable": false,
  "state": "RUNNING",
  "start-time": 1553480319794,
  "end-time": -1,
  "duration": 32482,
  "now": 1553480352276,
  "timestamps": {
    "RUNNING": 1553480320786,
    "CANCELED": 0,
    "CREATED": 1553480319794,
    "CANCELLING": 0,
    "FAILED": 0,
    "RESTARTING": 0,
    "SUSPENDED": 0,
    "FAILING": 0,
    "SUSPENDING": 0,
    "FINISHED": 0,
    "RECONCILING": 0
  },
  "vertices": [
    {
      "id": "bc764cd8ddf7a0cff126f51c16239658",
      "name": "Source: Custom Source",
      "parallelism": 1,
      "status": "RUNNING",
      "start-time": 1553480323021,
      "end-time": -1,
      "duration": 29255,
      "tasks": {
        "RECONCILING": 0,
        "CREATED": 0,
        "CANCELED": 0,
        "DEPLOYING": 0,
        "FINISHED": 0,
        "CANCELING": 0,
        "SCHEDULED": 0,
        "RUNNING": 1,
        "FAILED": 0
      },
      "metrics": {
        "read-bytes": 0,
        "read-bytes-complete": false,
        "write-bytes": 0,
        "write-bytes-complete": false,
        "read-records": 0,
        "read-records-complete": false,
        "write-records": 0,
        "write-records-complete": false
      }
    },
    {
      "id": "20ba6b65f97481d5570070de90e4e791",
      "name": "Flat Map -> Sink: Print to Std. Out",
      "parallelism": 1,
      "status": "RUNNING",
      "start-time": 1553480323032,
      "end-time": -1,
      "duration": 29244,
      "tasks": {
        "RECONCILING": 0,
        "CREATED": 0,
        "CANCELED": 0,
        "DEPLOYING": 0,
        "FINISHED": 0,
        "CANCELING": 0,
        "SCHEDULED": 0,
        "RUNNING": 1,
        "FAILED": 0
      },
      "metrics": {
        "read-bytes": 0,
        "read-bytes-complete": false,
        "write-bytes": 0,
        "write-bytes-complete": false,
        "read-records": 0,
        "read-records-complete": false,
        "write-records": 0,
        "write-records-complete": false
      }
    }
  ],
  "status-counts": {
    "RECONCILING": 0,
    "CREATED": 0,
    "CANCELED": 0,
    "DEPLOYING": 0,
    "FINISHED": 0,
    "CANCELING": 0,
    "SCHEDULED": 0,
    "RUNNING": 2,
    "FAILED": 0
  },
  "plan": {
    "jid": "19f12f073433d71d3dd360d93ba74f29",
    "name": "State machine job",
    "nodes": [
      {
        "id": "20ba6b65f97481d5570070de90e4e791",
        "parallelism": 1,
        "operator": "",
        "operator_strategy": "",
        "description": "Flat Map -&gt; Sink: Print to Std. Out",
        "inputs": [
          {
            "num": 0,
            "id": "bc764cd8ddf7a0cff126f51c16239658",
            "ship_strategy": "HASH",
            "exchange": "pipelined_bounded"
          }
        ],
        "optimizer_properties": {}
      },
      {
        "id": "bc764cd8ddf7a0cff126f51c16239658",
        "parallelism": 1,
        "operator": "",
        "operator_strategy": "",
        "description": "Source: Custom Source",
        "optimizer_properties": {}
      }
    ]
  }
}
            "num": 0,
            "id": "bc764cd8ddf7a0cff126f51c16239658",
            "ship_strategy": "HASH",
            "exchange": "pipelined_bounded"
          }
        ],
        "optimizer_properties": {}
      },
      {
        "id": "bc764cd8ddf7a0cff126f51c16239658",
        "parallelism": 1,
        "operator": "",
        "operator_strategy": "",
        "description": "Source: Custom Source",
        "optimizer_properties": {}
      }
    ]
  }
}'
++ echo '{' '"jid":' '"19f12f073433d71d3dd360d93ba74f29",' '"name":' '"State' machine 'job",' '"isStoppable":' false, '"state":' '"RUNNING",' '"start-time":' 1553480319794, '"end-time":' -1, '"duration":' 32482, '"now":' 1553480352276, '"timestamps":' '{' '"RUNNING":' 1553480320786, '"CANCELED":' 0, '"CREATED":' 1553480319794, '"CANCELLING":' 0, '"FAILED":' 0, '"RESTARTING":' 0, '"SUSPENDED":' 0, '"FAILING":' 0, '"SUSPENDING":' 0, '"FINISHED":' 0, '"RECONCILING":' 0 '},' '"vertices":' '[' '{' '"id":' '"bc764cd8ddf7a0cff126f51c16239658",' '"name":' '"Source:' Custom 'Source",' '"parallelism":' 1, '"status":' '"RUNNING",' '"start-time":' 1553480323021, '"end-time":' -1, '"duration":' 29255, '"tasks":' '{' '"RECONCILING":' 0, '"CREATED":' 0, '"CANCELED":' 0, '"DEPLOYING":' 0, '"FINISHED":' 0, '"CANCELING":' 0, '"SCHEDULED":' 0, '"RUNNING":' 1, '"FAILED":' 0 '},' '"metrics":' '{' '"read-bytes":' 0, '"read-bytes-complete":' false, '"write-bytes":' 0, '"write-bytes-complete":' false, '"read-records":' 0, '"read-records-complete":' false, '"write-records":' 0, '"write-records-complete":' false '}' '},' '{' '"id":' '"20ba6b65f97481d5570070de90e4e791",' '"name":' '"Flat' Map '->' Sink: Print to Std. 'Out",' '"parallelism":' 1, '"status":' '"RUNNING",' '"start-time":' 1553480323032, '"end-time":' -1, '"duration":' 29244, '"tasks":' '{' '"RECONCILING":' 0, '"CREATED":' 0, '"CANCELED":' 0, '"DEPLOYING":' 0, '"FINISHED":' 0, '"CANCELING":' 0, '"SCHEDULED":' 0, '"RUNNING":' 1, '"FAILED":' 0 '},' '"metrics":' '{' '"read-bytes":' 0, '"read-bytes-complete":' false, '"write-bytes":' 0, '"write-bytes-complete":' false, '"read-records":' 0, '"read-records-complete":' false, '"write-records":' 0, '"write-records-complete":' false '}' '}' '],' '"status-counts":' '{' '"RECONCILING":' 0, '"CREATED":' 0, '"CANCELED":' 0, '"DEPLOYING":' 0, '"FINISHED":' 0, '"CANCELING":' 0, '"SCHEDULED":' 0, '"RUNNING":' 2, '"FAILED":' 0 '},' '"plan":' '{' '"jid":' '"19f12f073433d71d3dd360d93ba74f29",' '"name":' '"State' machine 'job",' '"nodes":' '[' '{' '"id":' '"20ba6b65f97481d5570070de90e4e791",' '"parallelism":' 1, '"operator":' '"",' '"operator_strategy":' '"",' '"description":' '"Flat' Map '-&gt;' Sink: Print to Std. 'Out",' '"inputs":' '[' '{' '"num":' 0, '"id":' '"bc764cd8ddf7a0cff126f51c16239658",' '"ship_strategy":' '"HASH",' '"exchange":' '"pipelined_bounded"' '}' '],' '"optimizer_properties":' '{}' '},' '{' '"id":' '"bc764cd8ddf7a0cff126f51c16239658",' '"parallelism":' 1, '"operator":' '"",' '"operator_strategy":' '"",' '"description":' '"Source:' Custom 'Source",' '"optimizer_properties":' '{}' '}' ']' '}' '}'
++ jq -r .state
+ state=RUNNING
+ '[' RUNNING '!=' RUNNING ']'
+ echo 'Triggering Savepoint'
Triggering Savepoint
++ curl -s -XPOST -d '{"target-directory":"/ha/savepoints/19f12f073433d71d3dd360d93ba74f29","cancel-job":"true"}' application-mycluster-jobmanager:8081/jobs/19f12f073433d71d3dd360d93ba74f29/savepoints
Savepoint Response:
{"request-id":"120c47e517fdfd1d5713bf232218b49c"}
+ savepoint_response='{"request-id":"120c47e517fdfd1d5713bf232218b49c"}'
+ echo 'Savepoint Response:'
+ echo '{"request-id":"120c47e517fdfd1d5713bf232218b49c"}'
++ echo '{"request-id":"120c47e517fdfd1d5713bf232218b49c"}'
++ jq -r '.["request-id"]'
+ response_id=120c47e517fdfd1d5713bf232218b49c
++ curl -s application-mycluster-jobmanager:8081/jobs/19f12f073433d71d3dd360d93ba74f29/savepoints/120c47e517fdfd1d5713bf232218b49c
+ savepoint='{"status":{"id":"IN_PROGRESS"},"operation":null}'
++ echo '{"status":{"id":"IN_PROGRESS"},"operation":null}'
++ jq -r .status.id
+ '[' IN_PROGRESS '!=' COMPLETED ']'
+ echo 'Shutting down...'
+ sleep 1
Shutting down...
++ curl -s application-mycluster-jobmanager:8081/jobs/19f12f073433d71d3dd360d93ba74f29/savepoints/120c47e517fdfd1d5713bf232218b49c
+ savepoint='{"status":{"id":"COMPLETED"},"operation":{"location":"file:/ha/savepoints/19f12f073433d71d3dd360d93ba74f29/savepoint-19f12f-259c470b04b1"}}'
++ jq -r .status.id
++ echo '{"status":{"id":"COMPLETED"},"operation":{"location":"file:/ha/savepoints/19f12f073433d71d3dd360d93ba74f29/savepoint-19f12f-259c470b04b1"}}'
+ '[' COMPLETED '!=' COMPLETED ']'
++ jq -r .operation.location
++ echo '{"status":{"id":"COMPLETED"},"operation":{"location":"file:/ha/savepoints/19f12f073433d71d3dd360d93ba74f29/savepoint-19f12f-259c470b04b1"}}'
+ location=file:/ha/savepoints/19f12f073433d71d3dd360d93ba74f29/savepoint-19f12f-259c470b04b1
+ '[' file:/ha/savepoints/19f12f073433d71d3dd360d93ba74f29/savepoint-19f12f-259c470b04b1 '!=' '' ']'
+ kubectl patch configmap application-flink -p '{"data": {"location": "file:/ha/savepoints/19f12f073433d71d3dd360d93ba74f29/savepoint-19f12f-259c470b04b1"}}'
configmap/application-flink patched
Savepoint successful made, and job shut down
+ echo 'Savepoint successful made, and job shut down'
```

See the savepoint on the master:
```bash
$ kubectl get configmap application-flink -o jsonpath="{ .data.location }"
file:/ha/savepoints/19f12f073433d71d3dd360d93ba74f29/savepoint-19f12f-259c470b04b1%
$ kubectl exec -it application-mycluster-jobmanager-0 -- ls -la /ha/savepoints/19f12f073433d71d3dd360d93ba74f29/savepoint-19f12f-259c470b04b1
total 16
drwxr-xr-x 2 root root 4096 Mar 25 02:19 .
drwxr-xr-x 3 root root 4096 Mar 25 02:19 ..
-rw-r--r-- 1 root root 7918 Mar 25 02:19 _metadata
```

Start the job back up with the savepoint
```bash
$ kubectl apply -f repo/incubating/flink/demo/scratch/restart.yaml
$ kubectl logs -f jobs/application-restart-flink-job
+ PARALLELISM=1
+ ls -la /opt/flink/examples/streaming/StateMachineExample.jar
-rw-r--r-- 1 flink flink 1156313 Feb 11 14:47 /opt/flink/examples/streaming/StateMachineExample.jar
+ cp /opt/flink/examples/streaming/StateMachineExample.jar .
++ basename /opt/flink/examples/streaming/StateMachineExample.jar
+ JAR=StateMachineExample.jar
+ echo 'Local jar is StateMachineExample.jar'
+ ls -la StateMachineExample.jar
Local jar is StateMachineExample.jar
-rw-r--r-- 1 root root 1156313 Mar 25 02:22 StateMachineExample.jar
++ curl -X POST -H Expect: -F jarfile=@/opt/flink/examples/streaming/StateMachineExample.jar application-mycluster-jobmanager:8081/jars/upload
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 1129k  100   120  100 1129k    749  7054k --:--:-- --:--:-- --:--:-- 7058k
+ filename='{"filename":"/ha/data/flink-web-upload/f7f268b7-7e32-497d-b556-d8ed90b381db_StateMachineExample.jar","status":"success"}'
+ echo 'Filename: {"filename":"/ha/data/flink-web-upload/f7f268b7-7e32-497d-b556-d8ed90b381db_StateMachineExample.jar","status":"success"}'
Filename: {"filename":"/ha/data/flink-web-upload/f7f268b7-7e32-497d-b556-d8ed90b381db_StateMachineExample.jar","status":"success"}
++ jq -r .filename
++ echo '{"filename":"/ha/data/flink-web-upload/f7f268b7-7e32-497d-b556-d8ed90b381db_StateMachineExample.jar","status":"success"}'
+ raw=/ha/data/flink-web-upload/f7f268b7-7e32-497d-b556-d8ed90b381db_StateMachineExample.jar
+ echo 'Raw: /ha/data/flink-web-upload/f7f268b7-7e32-497d-b556-d8ed90b381db_StateMachineExample.jar'
Raw: /ha/data/flink-web-upload/f7f268b7-7e32-497d-b556-d8ed90b381db_StateMachineExample.jar
++ basename /ha/data/flink-web-upload/f7f268b7-7e32-497d-b556-d8ed90b381db_StateMachineExample.jar
+ jar_id=f7f268b7-7e32-497d-b556-d8ed90b381db_StateMachineExample.jar
+ echo 'JarID: f7f268b7-7e32-497d-b556-d8ed90b381db_StateMachineExample.jar'
JarID: f7f268b7-7e32-497d-b556-d8ed90b381db_StateMachineExample.jar
++ curl -s -XPOST -d '{"entryClass":"org.apache.flink.streaming.examples.statemachine.StateMachineExample","programArgs":"--error-rate 0.05 --sleep 50","parallelism":"1","savepointPath":"file:/ha/savepoints/19f12f073433d71d3dd360d93ba74f29/savepoint-19f12f-259c470b04b1"}' application-mycluster-jobmanager:8081/jars/f7f268b7-7e32-497d-b556-d8ed90b381db_StateMachineExample.jar/run
+ job_response='{"jobid":"544898ff367a9f8e272d484f6b2193ee"}'
+ echo 'Submitting Job... Response: {"jobid":"544898ff367a9f8e272d484f6b2193ee"}'
++ jq -r .jobid
Submitting Job... Response: {"jobid":"544898ff367a9f8e272d484f6b2193ee"}
++ echo '{"jobid":"544898ff367a9f8e272d484f6b2193ee"}'
+ job_id=544898ff367a9f8e272d484f6b2193ee
+ echo 'JobID: 544898ff367a9f8e272d484f6b2193ee'
+ kubectl patch configmap application-flink -p '{"data": {"jobid": "544898ff367a9f8e272d484f6b2193ee"}}'
JobID: 544898ff367a9f8e272d484f6b2193ee
configmap/application-flink patched
```

```bash
$ kubectl get configmap application-flink -o jsonpath="{ .data.jobid }"
544898ff367a9f8e272d484f6b2193ee
$ kubectl logs application-mycluster-jobmanager-0| grep /ha/savepoints/19f12f073433d71d3dd360d93ba74f29/savepoint-19f12f-259c470b04b1 | grep 544898ff367a9f8e272d484f6b2193ee
2019-03-25 02:22:16,841 INFO  org.apache.flink.runtime.checkpoint.CheckpointCoordinator     - Starting job 544898ff367a9f8e272d484f6b2193ee from savepoint file:/ha/savepoints/19f12f073433d71d3dd360d93ba74f29/savepoint-19f12f-259c470b04b1 ()
```


### Update cluster
1) Snapshot and stop job
2) Rollout Jobmanager and Task manager changes
3) restart job from Snapshot

### TODO
* Have startup scripts download JARs from URLs
* look at kustomize to use same core Job for interactions