# Installing the KUDO Kafka Operator

Requirements:

- Install the [KUDO controller](https://kudo.dev/docs/getting-started/)
- Install the [KUDO CLI](https://kudo.dev/docs/cli/)

This guide explains the basic installation for both KUDO Kafka and KUDO Zookeeper.
To run a production-grade KUDO Kafka cluster, please read [KUDO Kafka in production](./production.md)

## Installing the Operator

#### Install Zookeeper 
```
kubectl kudo install zookeeper --instance=zk
```

#### Install Kafka 

Please read the [limitations](./limitations.md) docs before creating the KUDO Kafka cluster. 

```
kubectl kudo install kafka
```

Verify the if the deploy plan for `--instance=kafka` is complete.
```
kubectl kudo plan status --instance=kafka
Plan(s) for "kafka" in namespace "default":
.
└── kafka (Operator-Version: "kafka-1.1.0" Active-Plan: "kafka-deploy-177524647")
    └── Plan deploy (serial strategy) [COMPLETE]
        └── Phase deploy-kafka (serial strategy) [COMPLETE]
            └── Step deploy (COMPLETE)
```

You can view all configuration options [here](./configuration.md)

#### Installing multiple Kafka Clusters

```
kubectl kudo install kafka --instance=kafka-1
kubectl kudo install kafka --instance=kafka-2
kubectl kudo install kafka --instance=kafka-3
```

The above commands will install three kafka clusters using the same zookeeper.
