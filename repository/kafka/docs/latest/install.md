# Installing the KUDO Kafka Operator

Requirements:

- Install the [KUDO controller](https://kudo.dev/docs/getting-started/)
- Install the [KUDO CLI](https://kudo.dev/docs/cli/)

This guide explains the basic installation for both KUDO Kafka and KUDO Zookeeper.
To run a production-grade KUDO Kafka cluster, please read [KUDO Kafka in production](./production.md)

## Installing the Operator

#### Install Kafka

Please read the [limitations](./limitations.md) docs before creating the KUDO Kafka cluster. 
From version `1.4.0` KUDO Kafka installs the KUDO Zookeeper as part of the KUDO Kafka Operator.

```
kubectl kudo install kafka
```

Verify the if the deploy plan for `--instance=kafka-instance` is complete.
```
$ kubectl kudo plan status --instance=kafka-instance
Plan(s) for "kafka-instance" in namespace "default":
.
└── kafka-instance (Operator-Version: "kafka-1.4.0" Active-Plan: "deploy")
    ├── Plan cruise-control (serial strategy) [NOT ACTIVE]
    │   └── Phase cruise-addon (serial strategy) [NOT ACTIVE]
    │       └── Step deploy-cruise-control [NOT ACTIVE]
    ├── Plan deploy (serial strategy) [COMPLETE], last updated 2020-07-15 11:10:15
    │   ├── Phase deploy-kafka (serial strategy) [COMPLETE]
    │   │   ├── Step zookeeper-instance [COMPLETE]
    │   │   ├── Step generate-tls-certificates [COMPLETE]
    │   │   ├── Step configuration [COMPLETE]
    │   │   ├── Step service [COMPLETE]
    │   │   └── Step app [COMPLETE]
    │   └── Phase addons (parallel strategy) [COMPLETE]
    │       ├── Step monitoring [COMPLETE]
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
    ├── Plan update-zk (serial strategy) [NOT ACTIVE]
    │   └── Phase zookeeper (serial strategy) [NOT ACTIVE]
    │       └── Step deploy [NOT ACTIVE]
    └── Plan user-workload (serial strategy) [NOT ACTIVE]
        └── Phase workload (serial strategy) [NOT ACTIVE]
            └── Step toggle-workload [NOT ACTIVE]
```

You can view all configuration options [here](./configuration.md)

#### Installing multiple Kafka Clusters

```
kubectl kudo install kafka --instance=kafka-1
kubectl kudo install kafka --instance=kafka-2
kubectl kudo install kafka --instance=kafka-3
```

The above commands will install three kafka clusters in the `default` namespace,
all using the same zookeeper instance (also running in the `default` namespace).

#### Installing Kafka clusters in a custom namespace

You can specify which namespace to install KUDO Kafka in using the `--namespace` flag
or its short equivalent, `-n`.

First, create a new namespace:

```bash
kubectl create ns hip-project
kubectl kudo install kafka --instance=kafka-dev -n hip-project
```

Next, install a kafka cluster for QA. This example shows how to point KUDO kafka at a Zookeeper instance
that is running in a different namespace (`default` in this case)

```bash
kubectl kudo install kafka --instance=kafka-qa -n hip-project
```
