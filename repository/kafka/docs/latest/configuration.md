# Configuration 

### Resources

By default, KUDO Kafka resource configuration is set to the minimum recommended values for production usage. 
But users can and should tune the configurations based on the workload requirements of their Kafka cluster.  

##### Tuning the resources for the Kafka Cluster

```
kubectl kudo install kafka --instance=my-kafka-name \
            -p ZOOKEEPER_URI=zk-zookeeper-0.zk-hs:2181,zk-zookeeper-1.zk-hs:2181,zk-zookeeper-2.zk-hs:2181 \
            -p ZOOKEEPER_PATH=/custom-path \
            -p BROKER_CPUS=3000m \
            -p BROKER_COUNT=5 \
            -p BROKER_MEM=4096m \
            -p DISK_SIZE=20Gi \
            -p MIN_INSYNC_REPLICAS=3 \
            -p NUM_IO_THREADS=10 \
            -p NUM_NETWORK_THREADS=5 
          
```

##### Health Checks

By default, the Kafka operator will use `livenessProbe` of type `tcpSocket` to check the broker port. This is a simple port based health check.

For using a more robust health check based on broker functionality you can set the parameter `LIVENESS_METHOD` to `FUNCTIONAL`. 
This check is a producer-consumer check based on a custom heartbeat topic which you can set using the parameter `LIVENESS_TOPIC_PREFIX`.

```
kubectl kudo install kafka --instance=my-kafka-name -p LIVENESS_METHOD=FUNCTIONAL -p LIVENESS_TOPIC_PREFIX=MyHealthCheckTopic
```

##### Storage

By default, the Kafka operator will use the default storage class of the Kubernetes cluster. 

To deploy Kafka using a different storage class, you can use the parameter `STORAGE_CLASS`

```
kubectl kudo install kafka --instance=my-kafka-name -p STORAGE_CLASS=<STORAGE_CLASS_NAME>
```

##### Deploying an ephemeral Kafka cluster without persistence

```
kubectl kudo install kafka --instance=my-kafka-name -p PERSISTENT_STORAGE=false
```

Having `PERSISTENT_STORAGE` value `false` means that any data or logs inside the brokers will be lost after a pod restart or rescheduling.
Deploying without persistent storage isn't recommended for production usage. 

##### Metrics

By default, the Kafka cluster will have the JMX Exporter enabled. You can check more information around how KUDO Kafka exposes metrics in [monitoring](./monitoring.md).

##### Zookeeper Configuration

KUDO Kafka requires a running ZooKeeper cluster to perform its own internal accounting and persist cluster topology. And connectivity to the Zookeeper.
You can install the KUDO Zookeeper or you can use any other Zookeeper cluster you're running inside or outside kubernetes to use with KUDO Kafka. 

###### Configuring the Zookeeper connection:

You can configure KUDO Kafka to use Zookeeper using the parameter `ZOOKEEPER_URI`
Let's see this with an example:
```
kubectl kudo install kafka --instance=my-kafka-cluster \
  -p ZOOKEEPER_URI=zk-zookeeper-0.zk-hs:2181,zk-zookeeper-1.zk-hs:2181,zk-zookeeper-2.zk-hs:2181 \
```
In the above example KUDO Kafka cluster will connect to the Zookeeper cluster available via following DNS names `zk-zookeeper-0.zk-hs:2181,zk-zookeeper-1.zk-hs:2181,zk-zookeeper-2.zk-hs:2181`

The Kafka cluster topology is persisted in a Zookeeper node. Every node in Zookeeper's namespace is identified by a path.   

Two Kafka clusters can share the same Zookeeper but sharing the same path can lead to a corrupt state for both Kafka clusters. 
To avoid this to happen, KUDO Kafka persists its cluster topology in zk node with same name as KUDO Kafka instance.

Let's for example see what will the zk path look like in the above example where we just configured `ZOOKEEPER_URI`:
```
kubectl kudo install kafka --instance=my-kafka-cluster \
  -p ZOOKEEPER_URI=zk-zookeeper-0.zk-hs:2181,zk-zookeeper-1.zk-hs:2181,zk-zookeeper-2.zk-hs:2181 \
```

In the above example KUDO Kafka will connect the Zookeeper present in `zk-zookeeper-0.zk-hs:2181,zk-zookeeper-1.zk-hs:2181,zk-zookeeper-2.zk-hs:2181` and 
will create a Zookeeper node in path `/my-kafka-cluster`.  

###### Using a custom Zookeeper node path:

You can also decide to chose a custom Zookeeper node path, using the KUDO Kafka parameter `ZOOKEEPER_PATH`
Let's see this with an example:
```
kubectl kudo install kafka --instance=my-kafka-name \
  -p ZOOKEEPER_URI=zk-zookeeper-0.zk-hs:2181,zk-zookeeper-1.zk-hs:2181,zk-zookeeper-2.zk-hs:2181 \
  -p ZOOKEEPER_PATH=/custom-path
```
In the above example KUDO Kafka will connect the Zookeeper present in `zk-zookeeper-0.zk-hs:2181,zk-zookeeper-1.zk-hs:2181,zk-zookeeper-2.zk-hs:2181` and 
will create a Zookeeper node in path `/custom-path`. 

##### Docker image

The Dockerfile used to build the KUDO Kafka operator is hosted in the [dcos-kafka-service](https://github.com/mesosphere/dcos-kafka-service/blob/master/images/Dockerfile) repo
