# Advanced Custom Configuration

KUDO Kafka is aiming to provide out of the box optimized Kafka clusters on Kubernetes, which can be tuned and configured using the parameters. 

Advanced custom configuration is to empower the advanced users of the Kafka, so they aren't restricted by the parameters we expose in the KUDO Kafka configuration. 

KUDO Kafka allows configuring the custom broker configuration using **CUSTOM_SERVER_PROPERTIES_CM_NAME** and custom metrics reporter configuration using **CUSTOM_METRICS_CM_NAME**

## Custom broker configuration

To use the custom broker configuration, we need to create a configmap with the properties we want to override.

Example custom configuration:

```
apiVersion: v1
kind: ConfigMap
metadata:
  name: custom-configuration
data:
  server.properties: |
    ssl.secure.random.implementation=SHA1PRNG
    connection.failed.authentication.delay.ms=300
```

Create the ConfigMap in the namespace we will have the KUDO Kafka cluster

```
> kubectl create -f custom-configuration.yaml -n kudo-kafka
configmap/custom-configuration created
```

Verify the ConfigMap is created correctly 

```
> kubectl get configmap custom-configuration -n kudo-kafka -o yaml
apiVersion: v1
data:
  server.properties: |
    ssl.secure.random.implementation=SHA1PRNG
    connection.failed.authentication.delay.ms=300
kind: ConfigMap
metadata:
  creationTimestamp: "2019-10-19T12:41:19Z"
  name: custom-configuration
  namespace: kudo-kafka
  resourceVersion: "349819"
  selfLink: /api/v1/namespaces/kudo-kafka/configmaps/custom-configuration
  uid: 8a9f1520-ed3d-4b90-b544-a3e20d20fa5f
```

Now we are ready to start the KUDO Kafka cluster with custom configuration to be used with default tuned configuration. 

```
kubectl kudo install kafka \
    --instance=kafka --namespace=kudo-kafka \
    -p ZOOKEEPER_URI=zk-zookeeper-0.zk-hs:2181,zk-zookeeper-1.zk-hs:2181,zk-zookeeper-2.zk-hs:2181 \
    -p BROKER_COUNT=3 \
    -p CUSTOM_SERVER_PROPERTIES_CM_NAME=custom-configuration 
```

Verify in the logs if the custom configuration is being used in the Apache Kafka brokers and the `KafkaConfig` is correctly using `connection.failed.authentication.delay.ms` with value of `300` 

```
> kubectl logs kafka-kafka-0 -n kudo-kafka
[2019-10-21 13:46:58,325] Appending custom configuration file to the server.properties...
ssl.secure.random.implementation=SHA1PRNG
connection.failed.authentication.delay.ms=300
Starting the kafka broker using broker.id 0...
[ ... lines removed for clarity ...]
	compression.type = producer
	connection.failed.authentication.delay.ms = 300
	connections.max.idle.ms = 600000
	connections.max.reauth.ms = 0
[ ... lines removed for clarity ...]
```
#### Updating the custom configuration

The KUDO Kafka custom configuration ConfigMap isn't watched by the KUDO controller. Therefore any updates done in the custom configuration will need a later rolling restart.

Edit the configmap with changes we want to rollout:

```
> kubectl edit configmap custom-configuration -n kudo-kafka
configmap/custom-configuration edited
```

Perform a rolling restart on the statefulset to reload the configmap.

```
> kubectl rollout restart statefulset kafka-kafka -n kudo-kafka
statefulset.apps/kafka-kafka restarted
```

#### :warning: Excludelist of the custom configuration

Users can update all the broker configuration properties except the `broker.id`, `listeners`,`advertised.listeners`,  `advertised.host.name`,  `listener.security.protocol.map` `log.dirs`
## Custom metrics reporter 

To use the custom metrics reporter configuration we need to create a configmap with the `metrics.yaml` we want to override.

Example of metrics configuration:

```
apiVersion: v1
kind: ConfigMap
metadata:
  name: metrics-config
data:
  metrics.properties: |
    rules:
    # Special cases and very specific rules
    - pattern : kafka.server<type=(.+), name=(.+), clientId=(.+), topic=(.+), partition=(.*)><>Value
      name: kafka_server_$1_$2
      type: GAUGE
      labels:
        clientId: "$3"
        topic: "$4"
        partition: "$5"
```

To have the KUDO Kafka detect correctly the custom metrics reporter configuration `data` should have `metrics.properties` 

Create the ConfigMap in the namespace we will have the KUDO Kafka cluster

```
> kubectl create -f metrics-configuration.yaml -n kudo-kafka
configmap/metrics-config created
```

Verify the ConfigMap is created correctly 

```
> kubectl get configmap metrics-config -n kudo-kafka -o yaml
apiVersion: v1
data:
  metrics.properties: |
    rules:
    # Special cases and very specific rules
    - pattern : kafka.server<type=(.+), name=(.+), clientId=(.+), topic=(.+), partition=(.*)><>Value
      name: kafka_server_$1_$2
      type: GAUGE
      labels:
        clientId: "$3"
        topic: "$4"
        partition: "$5"
kind: ConfigMap
metadata:
  creationTimestamp: "2019-10-21T17:45:41Z"
  name: metrics-config
  namespace: kudo-kafka
  resourceVersion: "74591"
  selfLink: /api/v1/namespaces/kudo-kafka/configmaps/metrics-config
  uid: 70273127-e9d6-4e36-ba9a-0e00c78dfe51
```

Now we are ready to start the KUDO Kafka cluster with custom metrics reporter configuration

```
> kubectl kudo install kafka \
    --instance=kafka --namespace=kudo-kafka \
    -p ZOOKEEPER_URI=zk-zookeeper-0.zk-hs:2181,zk-zookeeper-1.zk-hs:2181,zk-zookeeper-2.zk-hs:2181 \
    -p BROKER_COUNT=3 \
    -p CUSTOM_METRICS_CM_NAME=metrics-config
```

Verify that brokers have the correct metrics reporter configuration

```
> kubectl exec -ti kafka-kafka-0 cat /metrics/metrics.properties
rules:
    # Special cases and very specific rules
    - pattern : kafka.server<type=(.+), name=(.+), clientId=(.+), topic=(.+), partition=(.*)><>Value
      name: kafka_server_$1_$2
      type: GAUGE
      labels:
        clientId: "$3"
        topic: "$4"
        partition: "$5"
```

#### Updating the custom metrics reporter 

Like the custom configuration the custom metrics reporter is also not watched by the KUDO controller. Therefore to any updates done in the custom configuration will need a later rolling restart.

Edit the configmap with changes we want to rollout:

```
> kubectl edit configmap metrics-config -n kudo-kafka
configmap/metrics-config edited
```

Perform a rolling restart on the statefulset to reload the configmap.

```
> kubectl rollout restart statefulset kafka-kafka -n kudo-kafka
statefulset.apps/kafka-kafka restarted
```
