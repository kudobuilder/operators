
# Kafka MirrorMaker

KUDO Kafka operator comes with [Kafka MirrorMaker](https://cwiki.apache.org/confluence/pages/viewpage.action?pageId=27846330) included. MirrorMaker is a tool to mirror a source Kafka 
cluster into a target (mirror) Kafka cluster. The tool uses a Kafka consumer to consume messages from the
source cluster, and re-publishes those messages to the (target) cluster using an embedded Kafka producer.

### Using the MirrorMaker

To start MirrorMaker install the Kafka operator with the following options:

```sh
kubectl kudo install kafka --instance=kafka \
  -p MIRROR_MAKER_ENABLED=true \
  -p MIRROR_MAKER_EXTERNAL_BOOTSTRAP_SERVERS=<external-kafka-cluster-address>\
  -p MIRROR_MAKER_EXTERNAL_CLUSTER_TYPE=SOURCE
```

Parameter `MIRROR_MAKER_EXTERNAL_CLUSTER_TYPE` takes one of two values:

1. `SOURCE`: The Kafka cluster defined by `MIRROR_MAKER_EXTERNAL_BOOTSTRAP_SERVERS` will be
   used as a source cluster from which MirrorMaker will consume all the topics and produce those
   to our `kafka` cluster instance.

2. `DESTINATION`: MirrorMaker will consume topics from `kafka` cluster instance and produce those
   to the cluster defined by `MIRROR_MAKER_EXTERNAL_BOOTSTRAP_SERVERS`.


### Disable MirrorMaker

If MirrorMaker is running in a Kafka operator instance then to disable that scale the MirrorMaker
pod count to 0, using the following command:

```sh
kubectl kudo update --instance=kafkao -p MIRROR_MAKER_REPLICA_COUNT=0
``` 

### Advanced Options

|Parameter|Description|
|--|--|
| MIRROR_MAKER_TOPIC_WHITELIST | Whitelist of topics to mirror |
|MIRROR_MAKER_NUM_STREAMS|Number of consumer streams|
|MIRROR_MAKER_OFFSET_COMMIT_INTERVAL|Offset commit interval in ms|
|MIRROR_MAKER_ABORT_ON_SEND_FAILURE| Stop the entire mirror maker when a send failure occurs |
