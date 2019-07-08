# Installing KUDO Kafka operator

Requirements:

- [Install KUDO controller](https://kudo.dev/docs/getting-started/)
- [Install KUDO cli](https://kudo.dev/docs/cli/)


## Installing the Operator

#### Install the Zookeeper 
```
kubectl kudo install zookeeper --instance=zk
```

#### Install the Kafka 
```
kubectl kudo install kafka --instance=kafka
```

Verify the if the deploy plan for `--instance=kafka` is complete.
```
kubectl kudo plan status --instance=kafka
Plan(s) for "kafka" in namespace "default":
.
└── kafka (Operator-Version: "kafka-0.1.1" Active-Plan: "kafka-deploy-177524647")
    └── Plan deploy (serial strategy) [COMPLETE]
        └── Phase deploy-kafka (serial strategy) [COMPLETE]
            └── Step deploy (COMPLETE)
```

You can check all [configuration options](./configuration.md)

#### Installing multiple Kafka Clusters

```
kubectl kudo install kafka --instance=kafka-1
kubectl kudo install kafka --instance=kafka-2
kubectl kudo install kafka --instance=kafka-3
```

The above commands will install three kafka clusters using the same zookeeper.