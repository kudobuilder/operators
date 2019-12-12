
# Kafka MirrorMaker

KUDO Kafka operator comes with builtin integration of [Kafka MirrorMaker](https://cwiki.apache.org/confluence/pages/viewpage.action?pageId=27846330).
MirrorMaker is a tool to mirror a source Kafka cluster into a target (mirror) Kafka cluster. The tool uses a Kafka consumer to consume messages from the
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
kubectl kudo update --instance=kafka -p MIRROR_MAKER_REPLICA_COUNT=0
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
enabled in the Kafka instance (external included). Future releases of KUDO Kafka will provide enhancements to
address this limitation through a MirrorMaker operator.
