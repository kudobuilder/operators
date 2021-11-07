

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
> kubectl kudo update kafka -p DELETE_TOPIC_ENABLE=true 
```

Enable the `auto.create.topics.enable`

```
> kubectl kudo update kafka -p  AUTO_CREATE_TOPICS_ENABLE=true
```

## Scaling the brokers

Users should not configure the HPA or VPA for Kafka brokers. 

It is recommended that users closely monitor and control broker scaling due to the nature of stateful workloads.

#### Horizontally 

To scale horizontally, we can increase the broker count. Lets update the broker count from default `3` to `5`

```
> kubectl kudo update kafka -p BROKER_COUNT=4
```

Check the plan status:

```
> kubectl kudo plan status --instance=kafka
Plan(s) for "kafka" in namespace "default":
.
└── kafka (Operator-Version: "kafka-0.2.0" Active-Plan: "kafka-deploy-351387000")
    └── Plan deploy (serial strategy) [IN_PROGRESS]
        └── Phase deploy-kafka (serial strategy) [IN_PROGRESS]
            └── Step deploy (IN_PROGRESS)
```

Once the plan status is complete

```kubectl kudo plan status --instance=kafka
> kubectl kudo plan status --instance=kafka
Plan(s) for "kafka" in namespace "default":
.
└── kafka (Operator-Version: "kafka-0.2.0" Active-Plan: "kafka-deploy-351387000")
    └── Plan deploy (serial strategy) [COMPLETE]
        └── Phase deploy-kafka (serial strategy) [COMPLETE]
            └── Step deploy (COMPLETE)
```

We can see that we have 5 brokers up and running

```
> kubectl get pods -l app=kafka
NAME            READY   STATUS    RESTARTS   AGE
kafka-kafka-0   1/1     Running   0          7m26s
kafka-kafka-1   1/1     Running   0          8m26s
kafka-kafka-2   1/1     Running   0          8m53s
kafka-kafka-3   1/1     Running   0          10m
kafka-kafka-4   1/1     Running   0          9m21s
```



**Vertically** 

To scale vertically, we can update the broker's statefulset.

```
> kubectl describe statefulset kafka-kafka
[ ... lines removed for clarity ...]
    Requests:
      cpu:      500m
      memory:   2048Mi
[ ... lines removed for clarity ...]
```



Let's increase the cpu request from `500m` to `700m` and double the memory request from `2048Mi` to `4096Mi`. Also important is increasing the limits as they cannot be lower than the requested resources. 

```
kubectl kudo update kafka -p BROKER_CPUS=700m -p BROKER_MEM=4096Mi -p BROKER_CPUS_LIMIT=3000m -p BROKER_MEM_LIMIT=6144Mi
```

This will initiate a rolling upgrade of the pods to a new statefulset.

```
> kubectl describe statefulset kafka-kafka
[ ... lines removed for clarity ...]
    Requests:
      cpu:      700m
      memory:   4096Mi
[ ... lines removed for clarity ...]
```