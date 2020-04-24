# Update the Kafka cluster

#### Tuning the configuration 

Check the [limitations](./limitations.md) to see which parameters can only be set during bootstrap time. 

## Changing the configuration

There is a vast number of configuration parameters that can be tuned once the KUDO Kafka cluster is up and running. 
You can check the full list in the [parameters](https://github.com/kudobuilder/operators/blob/master/repository/kafka/operator/params.yaml).

There are a few constraints related to storage. These constraints are documented in the [limitations](./limitations.md) doc.

#### Examples

Enable the `delete.topic.enable`

```
$ kubectl kudo update kafka -p DELETE_TOPIC_ENABLE=true 
```

Enable the `auto.create.topics.enable`

```
$ kubectl kudo update kafka -p  AUTO_CREATE_TOPICS_ENABLE=true
```

## Scaling the brokers

Users should not configure the HPA or VPA for Kafka brokers. 

It is recommended that users closely monitor and control broker scaling due to the nature of stateful workloads.

#### Horizontally 

To scale horizontally, we can increase the broker count. Lets update the broker count from default `3` to `5`

```
$ kubectl kudo update kafka -p BROKER_COUNT=5
```

Check the plan status:

```
$ kubectl kudo plan status --instance=kafka-instance
Plan(s) for "kafka-instance" in namespace "default":
.
└── kafka-instance (Operator-Version: "kafka-1.2.1" Active-Plan: "update-instance")
    ├── Plan cruise-control (serial strategy) [NOT ACTIVE]
    │   └── Phase cruise-addon (serial strategy) [NOT ACTIVE]
    │       └── Step deploy-cruise-control [NOT ACTIVE]
    ├── Plan deploy (serial strategy) [NOT ACTIVE]
    │   ├── Phase deploy-kafka (serial strategy) [NOT ACTIVE]
    │   │   ├── Step generate-tls-certificates [NOT ACTIVE]
    │   │   ├── Step configuration [NOT ACTIVE]
    │   │   ├── Step service [NOT ACTIVE]
    │   │   └── Step app [NOT ACTIVE]
    │   └── Phase addons (parallel strategy) [NOT ACTIVE]
    │       ├── Step monitoring [NOT ACTIVE]
    │       ├── Step access [NOT ACTIVE]
    │       ├── Step mirror [NOT ACTIVE]
    │       └── Step load [NOT ACTIVE]
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
    ├── Plan update-instance (serial strategy) [IN_PROGRESS], last updated 2020-04-23 16:16:23
    │   └── Phase app (serial strategy) [IN_PROGRESS]
    │       ├── Step conf [COMPLETE]
    │       ├── Step svc [COMPLETE]
    │       └── Step sts [IN_PROGRESS]
    └── Plan user-workload (serial strategy) [NOT ACTIVE]
        └── Phase workload (serial strategy) [NOT ACTIVE]
            └── Step toggle-workload [NOT ACTIVE]
```

Once the plan status is complete

```
$ kubectl kudo plan status --instance=kafka-instance
Plan(s) for "kafka-instance" in namespace "default":
.
└── kafka-instance (Operator-Version: "kafka-1.2.1" Active-Plan: "update-instance")
    ├── Plan cruise-control (serial strategy) [NOT ACTIVE]
    │   └── Phase cruise-addon (serial strategy) [NOT ACTIVE]
    │       └── Step deploy-cruise-control [NOT ACTIVE]
    ├── Plan deploy (serial strategy) [NOT ACTIVE]
    │   ├── Phase deploy-kafka (serial strategy) [NOT ACTIVE]
    │   │   ├── Step generate-tls-certificates [NOT ACTIVE]
    │   │   ├── Step configuration [NOT ACTIVE]
    │   │   ├── Step service [NOT ACTIVE]
    │   │   └── Step app [NOT ACTIVE]
    │   └── Phase addons (parallel strategy) [NOT ACTIVE]
    │       ├── Step monitoring [NOT ACTIVE]
    │       ├── Step access [NOT ACTIVE]
    │       ├── Step mirror [NOT ACTIVE]
    │       └── Step load [NOT ACTIVE]
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
    ├── Plan update-instance (serial strategy) [COMPLETE], last updated 2020-04-23 16:19:05
    │   └── Phase app (serial strategy) [COMPLETE]
    │       ├── Step conf [COMPLETE]
    │       ├── Step svc [COMPLETE]
    │       └── Step sts [COMPLETE]
    └── Plan user-workload (serial strategy) [NOT ACTIVE]
        └── Phase workload (serial strategy) [NOT ACTIVE]
            └── Step toggle-workload [NOT ACTIVE]
```

We can see that we have 5 brokers up and running

```
$ kubectl get pods -l app=kafka
NAME                     READY   STATUS    RESTARTS   AGE
kafka-instance-kafka-0   2/2     Running   0          3h12m
kafka-instance-kafka-1   2/2     Running   0          3h13m
kafka-instance-kafka-2   2/2     Running   0          3h13m
kafka-instance-kafka-3   2/2     Running   0          3h14m
kafka-instance-kafka-4   2/2     Running   0          3h14m
```



**Vertically** 

To scale vertically, we can update the broker's statefulset.

```
$ kubectl describe statefulset kafka-kafka
[ ... lines removed for clarity ...]
    Requests:
      cpu:      500m
      memory:   2048Mi
[ ... lines removed for clarity ...]
```



Let's increase the cpu request from `500m` to `700m` and double the memory request from `2048Mi` to `4096Mi`. Also important is increasing the limits as they cannot be lower than the requested resources. 

```
$ kubectl kudo update kafka -p BROKER_CPUS=700m -p BROKER_MEM=4096Mi -p BROKER_CPUS_LIMIT=3000m -p BROKER_MEM_LIMIT=6144Mi
```

This will initiate a rolling upgrade of the pods to a new statefulset.

```
$ kubectl describe statefulset kafka-kafka
[ ... lines removed for clarity ...]
    Requests:
      cpu:      700m
      memory:   4096Mi
[ ... lines removed for clarity ...]
```