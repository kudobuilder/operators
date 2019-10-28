![kudo-kafka](./resources/images/kudo-kafka.png)

# Running KUDO Kafka in production



## Checklist

- Verify the storage class features
- Broker configuration
- Run the KUDO Kafka with tuned parameters

This document gives preference to the **data durability over the performance**.

## Storage Class features

Verify if there is a storage class installed in the kubernetes cluster. In this example we will use the `aws-ebs-csi-driver` as storage class reference.

```
> kubectl get sc
NAME                             PROVISIONER       AGE
awsebscsiprovisioner (default)   ebs.csi.aws.com   2d
```

### Volume Expansion

Verify if  the storage class has the option `AllowVolumeExpansion` to `true` 

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

:warning: In case it's `unset` or `false`, make sure to provision enough disk when bootstrapping the KUDO Kafka cluster. The disk size can be configured using the `DISK_SIZE` parameter. By **default, its 5Gi** and **not ideal for production usage**. Extend it as much as you consider your Kafka cluster needs to have reliable stability.​ 

### ReclaimPolicy

Verify if the storage class has the option `ReclaimPolicy` set to `Retain`

To read more about the `ReclaimPolicy` check the Kubernetes official docs around [Changing Reclaim Policy](https://kubernetes.io/docs/tasks/administer-cluster/change-pv-reclaim-policy/)

```
PersistentVolumes can have various reclaim policies, including “Retain”, “Recycle”, and “Delete”. For dynamically provisioned PersistentVolumes, the default reclaim policy is “Delete”. This means that a dynamically provisioned volume is automatically deleted when a user deletes the corresponding PersistentVolumeClaim. This automatic behavior might be inappropriate if the volume contains precious data. In that case, it is more appropriate to use the “Retain” policy. With the “Retain” policy, if a user deletes a PersistentVolumeClaim, the corresponding PersistentVolume is not be deleted. Instead, it is moved to the Released phase, where all of its data can be manually recovered.
```

If the `StorageClass` is shared between many users, its a common practice to keep the default `ReclaimPolicy` as `Delete` and the alternative is to change the `ReclaimPolicy` in the `PersistentVolume` once the cluster is up and running. 

Lets see an example of KUDO Kafka 3 brokers cluster's `PersistentVolumes` where the `StorageClass` default `ReclaimPolicy` is `Delete` 

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

Verify that `ReclaimPolicy` has been changed for the broker `PersistentVolumes`

```
> kubectl get pv
pvc-6a9e69f4-b807-440f-b190-357c109e8ad9   5Gi        RWO            Retain           Bound    default/kafka-datadir-kafka-kafka-0                                awsebscsiprovisioner            18h
pvc-8602a698-14a0-4c3d-85e6-67eb6da80a5d   5Gi        RWO            Retain           Bound    default/kafka-datadir-kafka-kafka-2                                awsebscsiprovisioner            18h
pvc-de527673-8bee-4e38-9e6d-399ec07c2728   5Gi        RWO            Retain           Bound    default/kafka-datadir-kafka-kafka-1                                awsebscsiprovisioner            18h
```



## Broker configuration

#### Replication Factor

Change the default replication factor from the default 1 to 3

```
DEFAULT_REPLICATION_FACTOR=3
```

#### Minimum Insync Replicas

When a producer sets acks to `all` (or `-1`) `MIN_INSYNC_REPLICAS` is the minimum number of replicas that must acknowledge a write for the write to be considered successful.
When used together, `min.insync.replicas` and `acks` allow Apache Kafka users to enforce greater durability guarantees.

To guarantee the messages durability a recommended practice would be to create a topic with a replication factor of `3`, set `MIN_INSYNC_REPLICAS` to `2`, and produce messages with acks of `all`.

```
MIN_INSYNC_REPLICAS=2
```

#### Number of partitions

The number of partitions should be higher than `1` for reliability reasons, by default this option is set to `3`

More partitions lead to higher throughput performance but affect latency and availability. In KUDO Kafka we can set this trade-off of throughput vs. availability by setting the default partition number.

```
NUM_PARTITIONS=3
```

#### Graceful rolling restarts

KUDO Kafka enables by default the option `CONTROLLED_SHUTDOWN_ENABLE` to true. To ensure a faster flush during shutdown and faster recovery during the bootstrap `num.recovery.threads.per.data.dir` can be increased from default `1` thread.

```
NUM_RECOVERY_THREADS_PER_DATA_DIR=3
```

#### Network Threads

If the Kafka cluster will have a lot of income requests, then you might need to change from the default value of `3` threads. This is necessary for clusters where a lot of different producers are connecting and writing messages.

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

