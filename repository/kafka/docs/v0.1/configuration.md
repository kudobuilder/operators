# Configuration 

### Resources

By default, KUDO Kafka resource configuration is set to be minimal optimal for the production usage. 
But users can tune the requirements depending on high or low workload of the Kafka cluster.  

##### Tuning the resources for the Kafka Cluster

```
kubectl kudo install kafka --instance=my-kafka-name \
            -p ZOOKEEPER_URI=zk-zk-0.zk-hs:2181,zk-zk-1.zk-hs:2181,zk-zk-2.zk-hs:2181 \
            -p ZOOKEEPER_PATH=/custom-path \
            -p BROKER_CPUS=3000m
            -p BROKER_COUNT=5
            -p BROKER_MEM=4096m
            -p DISK_SIZE=20Gi
            -p MIN_INSYNC_REPLICAS=3
            -p NUM_IO_THREADS=10
            -p NUM_NETWORK_THREADS=5
          
```

##### Storage

By default, the Kafka operator will use the default storage class of the Kubernetes cluster. 

To deploy the Kafka cluster using a storage class that isn't the default, you can use the parameter `STORAGE_CLASS`

```
kubectl kudo install kafka --instance=my-kafka-name -p STORAGE_CLASS=<STORAGE_CLASS_NAME>
```

##### Deploying an ephemeral Kafka cluster without persistence

```
kubectl kudo install kafka --instance=my-kafka-name -p PERSISTENT_STORAGE=false
```

Having `PERSISTENT_STORAGE` value `false` means that any data or logs in broker will be lost after the a pod restart or rescheduling.
Deploying without persistent storage isn't recommended for production usage. 

##### Metrics

By default, the Kafka cluster will have the JMX Exporter enabled. You can check more information around how KUDO Kafka exposes metrics in [monitoring](./monitoring.md) documentation.

##### Zookeeper PATH

By default, the Kafka cluster will try to use a zookeeper path same as the instance name.

User can override the default zk path by using `ZOOKEEPER_PATH` parameter.

```
kubectl kudo install kafka --instance=my-kafka-name -p ZOOKEEPER_URI=zk-zk-0.zk-hs:2181,zk-zk-1.zk-hs:2181,zk-zk-2.zk-hs:2181 -p ZOOKEEPER_PATH=/custom-path
```

