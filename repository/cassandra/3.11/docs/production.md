# Running KUDO Cassandra in production

Before running KUDO Cassandra in production, please follow this guide to ensure
the reliable stability of your production cluster.

Also, please read about
[Cassandra Anti-Patterns](https://docs.datastax.com/en/dse-planning/doc/planning/planningAntiPatterns.html)
to not to follow any bad practices when running production workload.

## Compute Resources

For production use of KUDO Cassandra we recommend a minimum of 32 GiB of memory
and 16 cores of CPU for guaranteed stability.

Refer to
[Capacity Planning](https://docs.datastax.com/en/dse-planning/doc/planning/capacityPlanning.html)
to learn about capacity planning for a Cassandra installation.

## Storage

Verify that there is a storage class installed in the Kubernetes cluster. In
this example we will use the `aws-ebs-csi-driver` as the storage class
reference.

```
$ kubectl get sc
NAME                             PROVISIONER       AGE
awsebscsiprovisioner (default)   ebs.csi.aws.com   2d
```

### Volume Expansion

Verify that the storage class has the option `AllowVolumeExpansion` set to
`true`.

```
$ kubectl describe sc awsebscsiprovisioner
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

:warning: In case `AllowVolumeExpansion` is `unset` or `false`, make sure to
provision enough disk when bootstrapping the KUDO Cassandra cluster. The disk
size can be configured using the `DISK_SIZE` parameter. By **default, DISK_SIZE
is set to 20Gi** and is **not ideal for production usage**. Users should
increase disk size by as much as they deem necessary for reliable stability.

### ReclaimPolicy

Verify the storage class has the option `ReclaimPolicy` set to `Retain`.

To read more about the `ReclaimPolicy` see the official Kubernetes docs on
[Changing the Reclaim Policy](https://kubernetes.io/docs/tasks/administer-cluster/change-pv-reclaim-policy/)

> PersistentVolumes can have various reclaim policies, including “Retain”,
> “Recycle”, and “Delete”. For dynamically provisioned PersistentVolumes, the
> default reclaim policy is “Delete”. This means that a dynamically provisioned
> volume is automatically deleted when a user deletes the corresponding
> PersistentVolumeClaim. This automatic behavior might be inappropriate if the
> volume contains precious data. In that case, it is more appropriate to use the
> “Retain” policy. With the “Retain” policy, if a user deletes a
> PersistentVolumeClaim, the corresponding PersistentVolume is not be deleted.
> Instead, it is moved to the Released phase, where all of its data can be
> manually recovered.

If the `StorageClass` is to be shared between many users, a common practice is
to leave the default `ReclaimPolicy` as `Delete` and set `ReclaimPolicy: Retain`
in the `PersistentVolume` once the cluster is up and running.

Let's see an example of a 3-broker KUDO Cassandra cluster's `PersistentVolumes`
where the `StorageClass` default `ReclaimPolicy` is `Delete`

```
$ kubectl get pv
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                                                              STORAGECLASS           REASON   AGE
pvc-6a9e69f4-b807-440f-b190-357c109e8ad9   20Gi       RWO            Delete           Bound    default/var-lib-cassandra-cassandra-instance-node-2                                                                 awsebscsiprovisioner            120m
pvc-8602a698-14a0-4c3d-85e6-67eb6da80a5d   20Gi       RWO            Delete           Bound    default/var-lib-cassandra-cassandra-instance-node-1                                                                 awsebscsiprovisioner            121m
pvc-de527673-8bee-4e38-9e6d-399ec07c2728   20Gi       RWO            Delete           Bound    default/var-lib-cassandra-cassandra-instance-node-0                                                                 awsebscsiprovisioner            123m
```

We can patch the `PersistentVolumes` to use the `ReclaimPolicy` of `Retain`

```
$ kubectl patch pv pvc-6a9e69f4-b807-440f-b190-357c109e8ad9 -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}'
$ kubectl patch pv pvc-8602a698-14a0-4c3d-85e6-67eb6da80a5d -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}'
$ kubectl patch pv pvc-de527673-8bee-4e38-9e6d-399ec07c2728 -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}'

persistentvolume/pvc-6a9e69f4-b807-440f-b190-357c109e8ad9 patched
persistentvolume/pvc-8602a698-14a0-4c3d-85e6-67eb6da80a5d patched
persistentvolume/pvc-de527673-8bee-4e38-9e6d-399ec07c2728 patched
```

Verify the `PersistentVolumes` `ReclaimPolicy` has been changed for all brokers:

```
$ kubectl get pv
pvc-6a9e69f4-b807-440f-b190-357c109e8ad9   5Gi        RWO            Retain           Bound    default/var-lib-cassandra-cassandra-instance-node-2                                 awsebscsiprovisioner            18h
pvc-8602a698-14a0-4c3d-85e6-67eb6da80a5d   5Gi        RWO            Retain           Bound    default/var-lib-cassandra-cassandra-instance-node-1                                 awsebscsiprovisioner            18h
pvc-de527673-8bee-4e38-9e6d-399ec07c2728   5Gi        RWO            Retain           Bound    default/var-lib-cassandra-cassandra-instance-node-0                              awsebscsiprovisioner            18h
```
