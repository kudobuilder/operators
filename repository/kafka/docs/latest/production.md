![kudo-kafka](./resources/images/kudo-kafka.png)

# Running KUDO Kafka in production



## Checklist

- Verify the storage class features
- Broker configuration
- Run the KUDO Kafka with tuned parameters

This document optimizes for **data durability over performance**. 

## Storage Class features

Verify if there is a storage class installed in the Kubernetes cluster. In this example we will use the `aws-ebs-csi-driver` as the storage class reference.

```
> kubectl get sc
NAME                             PROVISIONER       AGE
awsebscsiprovisioner (default)   ebs.csi.aws.com   2d
```

### Volume Expansion

Verify if the storage class has the option `AllowVolumeExpansion` and is set to `true`.

```
> kubectl describe sc awsebscsiprovisioner
Name:                  awsebscsiprovisioner
IsDefaultClass:        Yes
Annotations:           kubernetes.io/description=AWS EBS CSI provisioner StorageClass,storageclass.kubernetes.io/is-default-class=true
Provisioner:           ebs.csi.aws.com
Parameters:            type=gp2
AllowVolumeExpansion:  true
MountOptions:          <none>
ReclaimPolicy:         Delete
VolumeBindingMode:     WaitForFirstConsumer
Events:                <none>
```

:warning: In case `AllowVolumeExpansion` is `unset` or `false`, make sure to provision enough disk when bootstrapping the KUDO Kafka cluster. The disk size can be configured using the `DISK_SIZE` parameter. By **default, DISK_SIZE is set to 5Gi** and is **not ideal for production usage**. Users should Increase disk size by as much as they deem necessary for reliable stability.

### ReclaimPolicy

Verify the storage class has the option `ReclaimPolicy` and is set to `Retain`.

To read more about the `ReclaimPolicy` read the official Kubernetes docs on [Changing the Reclaim Policy](https://kubernetes.io/docs/tasks/administer-cluster/change-pv-reclaim-policy/)

```
> PersistentVolumes can have various reclaim policies, including “Retain”, “Recycle”, and “Delete”. For dynamically provisioned PersistentVolumes, the default reclaim policy is “Delete”. This means that a dynamically provisioned volume is automatically deleted when a user deletes the corresponding PersistentVolumeClaim. This automatic behavior might be inappropriate if the volume contains precious data. In that case, it is more appropriate to use the “Retain” policy. With the “Retain” policy, if a user deletes a PersistentVolumeClaim, the corresponding PersistentVolume is not be deleted. Instead, it is moved to the Released phase, where all of its data can be manually recovered.
```

If the `StorageClass` is to be shared between many users, a common practice is to leave the default `ReclaimPolicy` as `Delete` and set `ReclaimPolicy: Retain` in the `PersistentVolume` once the cluster is up and running. 

Let's see an example of a 3-broker KUDO Kafka cluster's `PersistentVolumes` where the `StorageClass` default `ReclaimPolicy` is `Delete` 

```
> kubectl get pv
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                                                              STORAGECLASS           REASON   AGE
pvc-6a9e69f4-b807-440f-b190-357c109e8ad9   5Gi        RWO            Delete           Bound    default/kafka-datadir-kafka-kafka-0                                awsebscsiprovisioner            18h
pvc-8602a698-14a0-4c3d-85e6-67eb6da80a5d   5Gi        RWO            Delete           Bound    default/kafka-datadir-kafka-kafka-2                                awsebscsiprovisioner            18h
pvc-de527673-8bee-4e38-9e6d-399ec07c2728   5Gi        RWO            Delete           Bound    default/kafka-datadir-kafka-kafka-1                                awsebscsiprovisioner            18h
```

We can patch the `PersistentVolumes` to use the `ReclaimPolicy` of `Retain`

```
kubectl patch pv pvc-6a9e69f4-b807-440f-b190-357c109e8ad9 -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}'
kubectl patch pv pvc-8602a698-14a0-4c3d-85e6-67eb6da80a5d -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}'
kubectl patch pv pvc-de527673-8bee-4e38-9e6d-399ec07c2728 -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}'

persistentvolume/pvc-6a9e69f4-b807-440f-b190-357c109e8ad9 patched
persistentvolume/pvc-8602a698-14a0-4c3d-85e6-67eb6da80a5d patched
persistentvolume/pvc-de527673-8bee-4e38-9e6d-399ec07c2728 patched
```

Verify the `PersistentVolumes` `ReclaimPolicy` has been changed for all brokers:

```
> kubectl get pv
pvc-6a9e69f4-b807-440f-b190-357c109e8ad9   5Gi        RWO            Retain           Bound    default/kafka-datadir-kafka-kafka-0                                awsebscsiprovisioner            18h
pvc-8602a698-14a0-4c3d-85e6-67eb6da80a5d   5Gi        RWO            Retain           Bound    default/kafka-datadir-kafka-kafka-2                                awsebscsiprovisioner            18h
pvc-de527673-8bee-4e38-9e6d-399ec07c2728   5Gi        RWO            Retain           Bound    default/kafka-datadir-kafka-kafka-1                                awsebscsiprovisioner            18h
```



## Broker configuration

#### Replication Factor

Change the default replication factor from the default `1` to `3`.

```
DEFAULT_REPLICATION_FACTOR=3
```

#### Minimum Insync Replicas

`MIN_INSYNC_REPLICAS` is the minimum number of replicas that must acknowledge a write for the write to be considered successful. To enforce greater durability guarantees, Kafka users should use `MIN_INSYNC_REPLICAS` in conjunction with producer `acks`.

To guarantee message durability, a recommended practice is to create a topic with a replication factor of `3`, set `MIN_INSYNC_REPLICAS` to `2`, and produce messages with acks of `all`.

```
MIN_INSYNC_REPLICAS=2
```

#### Number of partitions

The number of partitions should be higher than `1` for reliability reasons. By default, this option is set to `3`.

More partitions lead to higher throughput performance but affect latency and availability. In KUDO Kafka we can balance this trade-off of throughput vs. availability by configuring the default partition number.

```
NUM_PARTITIONS=3
```

#### Graceful rolling restarts

By default, KUDO Kafka sets `CONTROLLED_SHUTDOWN_ENABLE` to `true`. Which means whenever the pods are restarted the broker does a controlled shutdown. That process includes a log flush. During these controlled shutdown and bootstrap periods Apache Kafka's LogManager uses a Threadpool. To ensure a faster flush during shutdown, and faster recovery during bootstrap, we can configure the threads in the LogManager Threadpool using the property `num.recovery.threads.per.data.dir`. Which can be increased from the default value of `1` thread.

```
NUM_RECOVERY_THREADS_PER_DATA_DIR=3
```

#### Network Threads

If users expect the Kafka cluster to receive a high number of incoming requests, then users may need to increase the the number of network threads from its default value of of `3`. This is important for clusters where a lot of different producers are connecting and writing messages.

```
NUM_NETWORK_THREADS=10
```

#### Max Queued Requests

The number of queued requests allowed before blocking the network threads. The default 500 is sufficient for normal workloads. In case you have sharp peaks of workload where, for a short time, much load is thrown towards the Kafka cluster, you might need to tweak this value accordingly to not block any incoming requests during those peaks.

```
QUEUED_MAX_REQUESTS=<USER_CUSTOM_VALUE>
```

#### Background threads

The threads that are doing background jobs for the Kafka cluster, including compaction of log files, triggering leader election, and leader rebalance jobs. The default number of threads of 10 should be sufficient. 

```
BACKGROUND_THREADS=10
```

### Run the KUDO Kafka with tuned parameters

```
kubectl kudo install kafka \
    --instance=kafka --namespace=kudo-kafka -p ZOOKEEPER_URI=$ZOOKEEPER_URI \
    -p BROKER_CPUS=2000m \
    -p BROKER_COUNT=5 \
    -p BROKER_MEM=4096m \
    -p DISK_SIZE=100Gi \
    -p NUM_RECOVERY_THREADS_PER_DATA_DIR=3 \
    -p DEFAULT_REPLICATION_FACTOR=3 \
    -p MIN_INSYNC_REPLICAS=2 \
    -p NUM_NETWORK_THREADS=10 \
    -p NUM_PARTITIONS=3 \
    -p QUEUED_MAX_REQUESTS=1000 
```

