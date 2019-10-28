# Installing the KUDO Kafka Operator

Requirements:

- Install the [KUDO controller](https://kudo.dev/docs/getting-started/)
- Install the [KUDO CLI](https://kudo.dev/docs/cli/)

This guide explains the basic installation of the KUDO Zookeeper and KUDO Kafka. 
To run the production-grade KUDO Kafka clusters please follow the running [KUDO Kafka in production](./production.md)

## Installing the Operator

#### Install Zookeeper 
```
kubectl kudo install zookeeper --instance=zk
```

#### Install Kafka 

Please read the [limitations](./limitations.md) docs before creating the KUDO Kafka cluster. 

```
kubectl kudo install kafka --instance=kafka
```

Verify the if the deploy plan for `--instance=kafka` is complete.
```
kubectl kudo plan status --instance=kafka
Plan(s) for "kafka" in namespace "default":
.
└── kafka (Operator-Version: "kafka-0.1.2" Active-Plan: "kafka-deploy-177524647")
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
