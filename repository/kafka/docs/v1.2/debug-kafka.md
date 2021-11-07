# Runbook: Debugging a KUDO Kafka cluster 

This runbook explains how to debug a KUDO Kafka cluster.


## Pre-conditions

- Kubernetes cluster with KUDO version >= 0.10.1 installed
- Have a KUDO Kafka cluster version 1.2.0 up and running in the namespace `kudo-kafka`
- Have binary of `jq` installed in the `$PATH`


## Steps

### Verifying if KUDO Kafka plans are COMPLETE

#### Get the KUDO Kafka Instance object name

Verify the KUDO Kafka instance object is present in the expected namespace

`kubectl get instances`

expected output is the KUDO Instance objects present in the namespace `default`:

```bash
NAME                 AGE
kafka-instance       82m
zookeeper-instance   82m
```

#### Verify the KUDO Kafka plans

`kubectl kudo plan status  --instance=kafka-instance`

expected output is the current status of the KUDO Kafka instance plans:

```
Plan(s) for "kafka-instance" in namespace "default":
.
└── kafka-instance (Operator-Version: "kafka-1.2.1" Active-Plan: "deploy")
    ├── Plan cruise-control (serial strategy) [NOT ACTIVE]
    │   └── Phase cruise-addon (serial strategy) [NOT ACTIVE]
    │       └── Step deploy-cruise-control [NOT ACTIVE]
    ├── Plan deploy (serial strategy) [COMPLETE], last updated 2020-04-21 11:31:33
    │   ├── Phase deploy-kafka (serial strategy) [COMPLETE]
    │   │   ├── Step generate-tls-certificates [COMPLETE]
    │   │   ├── Step configuration [COMPLETE]
    │   │   ├── Step service [COMPLETE]
    │   │   └── Step app [COMPLETE]
    │   └── Phase addons (parallel strategy) [COMPLETE]
    │       ├── Step monitoring [COMPLETE]
    │       ├── Step access [COMPLETE]
    │       ├── Step mirror [COMPLETE]
    │       └── Step load [COMPLETE]
    ├── Plan external-access (serial strategy) [NOT ACTIVE]
    │   └── Phase resources (serial strategy) [NOT ACTIVE]
    │       └── Step deploy [NOT ACTIVE]
    ├── Plan kafka-connect (serial strategy) [NOT ACTIVE]
    │   └── Phase deploy-kafka-connect (serial strategy) [NOT ACTIVE]
    │       ├── Step deploy [NOT ACTIVE]
    │       └── Step setup [NOT ACTIVE]
    ├── Plan mirrormaker (serial strategy) [NOT ACTIVE]
    │   └── Phase app (serial strategy) [NOT ACTIVE]
    │       └── Step deploy [NOT ACTIVE]
    ├── Plan not-allowed (serial strategy) [NOT ACTIVE]
    │   └── Phase not-allowed (serial strategy) [NOT ACTIVE]
    │       └── Step not-allowed [NOT ACTIVE]
    ├── Plan service-monitor (serial strategy) [NOT ACTIVE]
    │   └── Phase enable-service-monitor (serial strategy) [NOT ACTIVE]
    │       └── Step deploy [NOT ACTIVE]
    ├── Plan update-instance (serial strategy) [NOT ACTIVE]
    │   └── Phase app (serial strategy) [NOT ACTIVE]
    │       ├── Step conf [NOT ACTIVE]
    │       ├── Step svc [NOT ACTIVE]
    │       └── Step sts [NOT ACTIVE]
    └── Plan user-workload (serial strategy) [NOT ACTIVE]
        └── Phase workload (serial strategy) [NOT ACTIVE]
            └── Step toggle-workload [NOT ACTIVE]
```

#### Get all KUDO Kafka instance pods

We can use the KUDO Kafka instance name to retrieve all pods for KUDO Kafka cluster.

`kubectl get pods -l kudo.dev/instance=kafka-instance`

expected output is the pods list that belong to the current KUDO Kafka instance:
```
NAME                     READY   STATUS    RESTARTS   AGE
kafka-instance-kafka-0   2/2     Running   1          124m
kafka-instance-kafka-1   2/2     Running   0          124m
kafka-instance-kafka-2   2/2     Running   0          123m
```

### Debugging the pods logs

#### Get logs from KUDO Kafka combined pods 

Sometimes we need the combined logs output of all the Kafka pods:
`kubectl logs -l  kudo.dev/instance=kafka-instance -c k8skafka -f`


expected output is the current logs from all the Kafka pods, we can identify to which broker each line belong by the `brokerId` present in log lines:

```
[2020-02-03 12:13:22,030] INFO [GroupMetadataManager brokerId=2] Removed 0 expired offsets in 0 milliseconds. (kafka.coordinator.group.GroupMetadataManager)
[2020-02-03 12:23:22,030] INFO [GroupMetadataManager brokerId=2] Removed 0 expired offsets in 0 milliseconds. (kafka.coordinator.group.GroupMetadataManager)
[2020-02-03 12:33:22,030] INFO [GroupMetadataManager brokerId=2] Removed 0 expired offsets in 0 milliseconds. (kafka.coordinator.group.GroupMetadataManager)
[2020-02-03 11:02:36,834] INFO [GroupMetadataManager brokerId=1] Removed 0 expired offsets in 0 milliseconds. (kafka.coordinator.group.GroupMetadataManager)
[2020-02-03 11:12:36,834] INFO [GroupMetadataManager brokerId=1] Removed 0 expired offsets in 0 milliseconds. (kafka.coordinator.group.GroupMetadataManager)
[2020-02-03 11:22:36,834] INFO [GroupMetadataManager brokerId=1] Removed 0 expired offsets in 0 milliseconds. (kafka.coordinator.group.GroupMetadataManager)
[2020-02-03 11:32:36,834] INFO [GroupMetadataManager brokerId=1] Removed 0 expired offsets in 0 milliseconds. (kafka.coordinator.group.GroupMetadataManager)
[2020-02-03 11:42:36,834] INFO [GroupMetadataManager brokerId=1] Removed 0 expired offsets in 0 milliseconds. (kafka.coordinator.group.GroupMetadataManager)
[2020-02-03 11:52:36,834] INFO [GroupMetadataManager brokerId=1] Removed 0 expired offsets in 0 milliseconds. (kafka.coordinator.group.GroupMetadataManager)
[2020-02-03 12:02:36,834] INFO [GroupMetadataManager brokerId=1] Removed 0 expired offsets in 0 milliseconds. (kafka.coordinator.group.GroupMetadataManager)
[2020-02-03 12:12:36,834] INFO [GroupMetadataManager brokerId=1] Removed 0 expired offsets in 0 milliseconds. (kafka.coordinator.group.GroupMetadataManager)
[2020-02-03 12:22:36,834] INFO [GroupMetadataManager brokerId=1] Removed 0 expired offsets in 0 milliseconds. (kafka.coordinator.group.GroupMetadataManager)
[2020-02-03 12:32:36,834] INFO [GroupMetadataManager brokerId=1] Removed 0 expired offsets in 0 milliseconds. (kafka.coordinator.group.GroupMetadataManager)
[2020-02-03 11:22:09,613] INFO [GroupMetadataManager brokerId=0] Removed 0 expired offsets in 0 milliseconds. (kafka.coordinator.group.GroupMetadataManager)
[2020-02-03 11:32:09,613] INFO [GroupMetadataManager brokerId=0] Removed 0 expired offsets in 0 milliseconds. (kafka.coordinator.group.GroupMetadataManager)
[2020-02-03 11:42:09,613] INFO [GroupMetadataManager brokerId=0] Removed 0 expired offsets in 0 milliseconds. (kafka.coordinator.group.GroupMetadataManager)
[2020-02-03 11:52:09,613] INFO [GroupMetadataManager brokerId=0] Removed 0 expired offsets in 0 milliseconds. (kafka.coordinator.group.GroupMetadataManager)
[2020-02-03 12:02:09,613] INFO [GroupMetadataManager brokerId=0] Removed 0 expired offsets in 0 milliseconds. (kafka.coordinator.group.GroupMetadataManager)
[2020-02-03 12:12:09,613] INFO [GroupMetadataManager brokerId=0] Removed 0 expired offsets in 0 milliseconds. (kafka.coordinator.group.GroupMetadataManager)
[2020-02-03 12:22:09,613] INFO [GroupMetadataManager brokerId=0] Removed 0 expired offsets in 0 milliseconds. (kafka.coordinator.group.GroupMetadataManager)
[2020-02-03 12:32:09,613] INFO [GroupMetadataManager brokerId=0] Removed 0 expired offsets in 0 milliseconds. (kafka.coordinator.group.GroupMetadataManager)
```

#### Get logs from KUDO Kafka individual pod

`kubectl logs kafka-instance-kafka-0 -c k8skafka`

```
[ ... lines removed for clarity ...]
[2020-02-03 11:52:09,613] INFO [GroupMetadataManager brokerId=0] Removed 0 expired offsets in 0 milliseconds. (kafka.coordinator.group.GroupMetadataManager)
[2020-02-03 12:02:09,613] INFO [GroupMetadataManager brokerId=0] Removed 0 expired offsets in 0 milliseconds. (kafka.coordinator.group.GroupMetadataManager)
[2020-02-03 12:12:09,613] INFO [GroupMetadataManager brokerId=0] Removed 0 expired offsets in 0 milliseconds. (kafka.coordinator.group.GroupMetadataManager)
[2020-02-03 12:22:09,613] INFO [GroupMetadataManager brokerId=0] Removed 0 expired offsets in 0 milliseconds. (kafka.coordinator.group.GroupMetadataManager)
[2020-02-03 12:32:09,613] INFO [GroupMetadataManager brokerId=0] Removed 0 expired offsets in 0 milliseconds. (kafka.coordinator.group.GroupMetadataManager)
[ ... lines removed for clarity ...]
```

#### Get logs from KUDO Kafka node exporter container

`kubectl logs kafka-instance-kafka-0 -c kafka-node-exporter`


expected output is the logs from the node exporter container running as a sidecar with the broker 0 of Kafka:
```
time="2020-02-03T10:31:44Z" level=info msg="Starting node_exporter (version=0.18.1, branch=HEAD, revision=3db77732e925c08f675d7404a8c46466b2ece83e)" source="node_exporter.go:156"
time="2020-02-03T10:31:44Z" level=info msg="Build context (go=go1.12.5, user=root@b50852a1acba, date=20190604-16:41:18)" source="node_exporter.go:157"
```

### Debugging service issues

#### Verify the service endpoints

`kubectl get endpoints kafka-instance-svc -o json | jq  -r '.subsets[].addresses[].hostname'`

expected output is the pods name for the brokers:
```
kafka-instance-kafka-2
kafka-instance-kafka-0
kafka-instance-kafka-1
```

#### Verify the service selector labels are matching the ones in pods

Get the labels presents in the Kafka pods

`kubectl get pods -l kudo.dev/instance=kafka-instance -o json | jq -r '.items[].metadata.labels'`

expected output is the list of the labels used in the pods of `kafka-instance` cluster:

```
{
  "app": "kafka",
  "controller-revision-hash": "kafka-instance-kafka-76b8b8559b",
  "kafka": "kafka",
  "kudo.dev/instance": "kafka-instance",
  "statefulset.kubernetes.io/pod-name": "kafka-instance-kafka-0"
}
{
  "app": "kafka",
  "controller-revision-hash": "kafka-instance-kafka-76b8b8559b",
  "kafka": "kafka",
  "kudo.dev/instance": "kafka-instance",
  "statefulset.kubernetes.io/pod-name": "kafka-instance-kafka-1"
}
{
  "app": "kafka",
  "controller-revision-hash": "kafka-instance-kafka-76b8b8559b",
  "kafka": "kafka",
  "kudo.dev/instance": "kafka-instance",
  "statefulset.kubernetes.io/pod-name": "kafka-instance-kafka-2"
}
```

Now we need to verify that the service selector is using a subset of these labels

`kubectl get svc kafka-instance-svc -o json | jq -r '.spec.selector'`

expected output are the two labels the service use to find the Kafka pods: 
```
{
  "app": "kafka",
  "kudo.dev/instance": "kafka-instance"
}
```

### Debugging health of all objects

#### Get list of all objects created by KUDO Kafka Instance

`kubectl api-resources --verbs=get --namespaced -o name \
  | xargs -n 1 kubectl get --show-kind --ignore-not-found -l kudo.dev/instance=kafka-instance`

expected output are all resources which are created by the KUDO Kafka Instance `kafka-instance`. The list can be different based on different features enabled in KUDO Kafka.

```
NAME                                           DATA   AGE
configmap/kafka-instance-bootstrap             1      5h26m
configmap/kafka-instance-enable-tls            1      5h26m
configmap/kafka-instance-health-check-script   1      5h26m
configmap/kafka-instance-jaas-config           1      5h26m
configmap/kafka-instance-krb5-config           1      5h26m
configmap/kafka-instance-metrics-config        1      5h26m
configmap/kafka-instance-serverproperties      1      5h26m
NAME                           ENDPOINTS                                                                AGE
endpoints/kafka-instance-svc   192.168.183.18:9096,192.168.51.87:9096,192.168.65.150:9096 + 9 more...   5h26m
NAME                         READY   STATUS    RESTARTS   AGE
pod/kafka-instance-kafka-0   2/2     Running   1          5h26m
pod/kafka-instance-kafka-1   2/2     Running   0          5h25m
pod/kafka-instance-kafka-2   2/2     Running   0          5h25m
NAME                            SECRETS   AGE
serviceaccount/kafka-instance   1         5h26m
NAME                         TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)                               AGE
service/kafka-instance-svc   ClusterIP   None         <none>        9093/TCP,9092/TCP,9094/TCP,9096/TCP   5h26m
NAME                                                      CONTROLLER                              REVISION   AGE
controllerrevision.apps/kafka-instance-kafka-76b8b8559b   statefulset.apps/kafka-instance-kafka   1          5h26m
NAME                                    READY   AGE
statefulset.apps/kafka-instance-kafka   3/3     5h26m
NAME                                               AGE
podmetrics.metrics.k8s.io/kafka-instance-kafka-1   1s
podmetrics.metrics.k8s.io/kafka-instance-kafka-2   1s
podmetrics.metrics.k8s.io/kafka-instance-kafka-0   1s
NAME                                            MIN AVAILABLE   MAX UNAVAILABLE   ALLOWED DISRUPTIONS   AGE
poddisruptionbudget.policy/kafka-instance-pdb   N/A             1                 1                     5h29m
NAME                                                           AGE
rolebinding.rbac.authorization.k8s.io/kafka-instance-binding   5h29m
NAME                                                 AGE
role.rbac.authorization.k8s.io/kafka-instance-role   5h29m
```

### Debugging deployment issues

#### Pod stuck with Status `ContainerCreating` 

After deploying KUDO Kafka if the pods are stuck in `ContainerCreating` status. It can be caused by several issues caused by resource starvation to storage issues.

To debug the root cause of the `ContainerCreating` issue for KUDO Kafka. For example for the next case:
```
kubectl get pods 
NAME                             READY   STATUS              RESTARTS   AGE
kafka-instance-kafka-0           0/2     ContainerCreating   0          4m17s
```
Run the `pod describe` command and look for the events related to the pod

`kubectl describe pod kafka-instance-kafka-0`

expected output should reveal some reasons that are stopping the scheduling of the pod

```
[ ... lines removed for clarity ...]
Events:
  Type     Reason              Age                  From                                                Message
  ----     ------              ----                 ----                                                -------
  Normal   Scheduled           <unknown>            default-scheduler                                   Successfully assigned default/kafka-instance-kafka-0 to ip-10-0-128-61.us-west-2.compute.internal
  Warning  FailedMount         36s                  kubelet, ip-10-0-128-61.us-west-2.compute.internal  Unable to attach or mount volumes: unmounted volumes=[kafka-instance-datadir], unattached volumes=[config health-check-script metrics kafka-instance-datadir kafka-instance-token-m2d2h bootstrap]: timed out waiting for the condition
[ ... lines removed for clarity ...]
```

Here we can see that the issue was caused by the `FailedMount` event.

To get more details on what is happening we can fetch the events 

`kubectl get events --sort-by='.metadata.creationTimestamp'`

```
[ ... lines removed for clarity ...]
default       54s         Warning   FailedAttachVolume       pod/kafka-instance-kafka-0                                                        AttachVolume.Attach failed for volume "pvc-e949f30a-79d6-46ba-9ec1-5658c8e66c17" : PersistentVolume "pvc-e949f30a-79d6-46ba-9ec1-5658c8e66c17" is marked for deletion
[ ... lines removed for clarity ...]
```

we can see that the root cause of the container being stuck is an issue with the PersistentVolume.

#### Pod stuck with Status `Pending` 

Same debugging can be applied for the pods stuck in other states like `Pending`. 

`kubectl get pods`

expected output is a list of pods with one `Pending` pod:
```
NAME                             READY   STATUS    RESTARTS   AGE
kafka-instance-kafka-0           2/2     Running   0          35m
kafka-instance-kafka-1           2/2     Running   0          35m
kafka-instance-kafka-2           0/2     Pending   0          17s
```

Run the `pod describe` command and look for the events related to the pod

`kubectl describe pod kafka-instance-kafka-2`

expected output should reveal some reasons that are stopping the scheduling of the pod

```
[ ... lines removed for clarity ...]
Events:
  Type     Reason            Age        From               Message
  ----     ------            ----       ----               -------
  Warning  FailedScheduling  <unknown>  default-scheduler  0/7 nodes are available: 7 Insufficient memory.
[ ... lines removed for clarity ...]
```
We can see that pod is in Pending state because of insufficient memory.

Same can be also be retrieved by checking the events
`kubectl get events --sort-by='.metadata.creationTimestamp'`

expected output should reveal that pod `kafka-instance-kafka-2` is stuck due to resource starvation

```
[ ... lines removed for clarity ...]

default     <unknown>   Warning   FailedScheduling         pod/kafka-instance-kafka-2         0/7 nodes are available: 7 Insufficient memory.
[ ... lines removed for clarity ...]
```