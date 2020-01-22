# Kafka MirrorMaker

## Overview

KUDO Kafka operator comes with builtin integration of [Kafka MirrorMaker](https://cwiki.apache.org/confluence/pages/viewpage.action?pageId=27846330).

MirrorMaker is a tool to mirror a source Kafka cluster into a target (mirror) Kafka cluster.
This tool uses a Kafka consumer and a Kafka producer.
The consumer consumes messages from the source cluster.
The producer re-publishes those messages to the target cluster.

MirrorMaker integration is disabled by default.

This guide shows how to establish a mirror of a kafka instance using the integration
provided by the operator.

## Pre-conditions

The following are necessary for this runbook:
- Two running kafka clusters.
 
  At least one of them must be a KUDO Kafka instance, and it will host the mirror maker process. 
  This runbook refers to the instance as `this`, and to the other instance as `other`.

## Steps

### Preparation

### 1. Set the shell variables

The examples below assume the following shell variables. With this assumptions met, you should be able to copy-paste the commands easily.

```bash
this_instance_name=kafka-qa
this_namespace_name=qa
```

You also need the list of bootstrap servers of the `other` instance.

**If the `other` instance is also a KUDO Kafka instance running in the same kubernetes
cluster:**
 
You can generate the list using the following commands:
```bash
other_instance_name=kafka-prod
other_namespace_name=production
other_port=$(kubectl get svc ${other_instance_name}-svc -n $other_namespace_name \
  --template='{{ range .spec.ports }}{{if eq .name "client" }}{{ .port }}{{ end }}{{ end }}')
other_bootstrap_servers=$(kubectl get pods -l app=kafka,kafka=kafka,kudo.dev/instance=$other_instance_name -n $other_namespace_name \
  --template="{{ range .items }}{{ .spec.hostname }}.{{ .spec.subdomain }}.{{ .metadata.namespace }}.svc.cluster.local:$other_port{{ \"\\n\" }}{{end}}" \
  | head -n 3 | paste -d, -s)
echo $other_bootstrap_servers 
```

Example output:
```
kafka-prod-kafka-0.kafka-prod-svc.production.svc.cluster.local:9092,kafka-prod-kafka-1.kafka-prod-svc.production.svc.cluster.local:9092,kafka-prod-kafka-2.kafka-prod-svc.production.svc.cluster.local:9092
```

**Otherwise:**

Please refer to its documentation about how to retrieve a list of bootstrap servers.
These need to be reachable from `this` instance.

```bash
other_bootstrap_servers=other-server-1.example.com,other-server-2.example.com
```

## Starting MirrorMaker

Run the following command to start MirrorMaker alongside `this` instance:

```sh
kubectl kudo update --instance=$this_instance_name --namespace=$this_namespace_name \
  -p MIRROR_MAKER_ENABLED=true \
  -p MIRROR_MAKER_EXTERNAL_BOOTSTRAP_SERVERS=$other_bootstrap_servers \
  -p MIRROR_MAKER_EXTERNAL_CLUSTER_TYPE=DESTINATION
```

:information_source: Note that these `-p` options can also be specified when installing
the instance.

Parameter `MIRROR_MAKER_EXTERNAL_CLUSTER_TYPE` takes one of two values:

1. `SOURCE`:

   MirrorMaker will consume topics from the Kafka cluster defined by `MIRROR_MAKER_EXTERNAL_BOOTSTRAP_SERVERS`.
   It will then produce those to `this` cluster.

2. `DESTINATION`:
 
   MirrorMaker will consume topics from `this` cluster.
   It will then produce those to the cluster defined by `MIRROR_MAKER_EXTERNAL_BOOTSTRAP_SERVERS`.


### Disable MirrorMaker

To disable MirrorMaker, scale the
pod count to 0, using the following command:

```sh
kubectl kudo update --instance=$this_instance_name --namespace=$this_namespace_name \
 -p MIRROR_MAKER_REPLICA_COUNT=0
``` 

### Advanced Options

|Parameter|Description|Example|
|--|--|--|
| MIRROR_MAKER_TOPIC_WHITELIST | Whitelist of topics to mirror |<ul> <li> ".*" for all topics (default) <li>"topic1"</li> <li> "topic5,topic6"</li></ul> |
|MIRROR_MAKER_NUM_STREAMS|Number of consumer streams|<ul><li>"1" (default)</li></ul>|
|MIRROR_MAKER_OFFSET_COMMIT_INTERVAL|Offset commit interval in ms|<ul><li>"60000" for 1 min (default)</li></ui>|
|MIRROR_MAKER_ABORT_ON_SEND_FAILURE| Stop the entire mirror maker when a send failure occurs |<ul><li>"true" (default)</li><li>"false"</li></ul>|

### Limitations

Currently MirrorMaker works with Kafka protocol `PLAINTEXT` only. It will not work if Kerberos and or TLS is
enabled in the Kafka instance (external included). Future releases of KUDO Kafka will
address this limitation through a MirrorMaker operator.
