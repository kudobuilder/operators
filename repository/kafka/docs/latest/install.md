# Installing the KUDO Kafka Operator

Requirements:

- Install the [KUDO controller](https://kudo.dev/docs/getting-started/)
- Install the [KUDO CLI](https://kudo.dev/docs/cli/)

This guide explains the basic installation for both KUDO Kafka and KUDO Zookeeper.
To run a production-grade KUDO Kafka cluster, please read [KUDO Kafka in production](./production.md)

## Installing the Operator

#### Install Zookeeper 
```
kubectl kudo install zookeeper
```

#### Install Kafka 

Please read the [limitations](./limitations.md) docs before creating the KUDO Kafka cluster. 

```
kubectl kudo install kafka
```

Verify the if the deploy plan for `--instance=kafka-instance` is complete.
```
$ kubectl kudo plan status --instance=kafka-instance
Plan(s) for "kafka-instance" in namespace "default":
.
└── kafka-instance (Operator-Version: "kafka-1.2.1" Active-Plan: "deploy")
    ├── Plan deploy (serial strategy) [COMPLETE]
    │   └── Phase deploy-kafka (serial strategy) [COMPLETE]
    │       ├── Step configuration [COMPLETE]
    │       ├── Step service [COMPLETE]
    │       ├── Step app [COMPLETE]
    │       └── Step addons [COMPLETE]
    ├── Plan external-access (serial strategy) [NOT ACTIVE]
    │   └── Phase external-access-resources (serial strategy) [NOT ACTIVE]
    │       └── Step external [NOT ACTIVE]
    ├── Plan mirrormaker (serial strategy) [NOT ACTIVE]
    │   └── Phase deploy-mirror-maker (serial strategy) [NOT ACTIVE]
    │       └── Step deploy [NOT ACTIVE]
    ├── Plan not-allowed (serial strategy) [NOT ACTIVE]
    │   └── Phase not-allowed (serial strategy) [NOT ACTIVE]
    │       └── Step not-allowed [NOT ACTIVE]
    └── Plan service-monitor (serial strategy) [NOT ACTIVE]
        └── Phase enable-service-monitor (serial strategy) [NOT ACTIVE]
            └── Step add-service-monitor [NOT ACTIVE]
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

First, create a new namespace and install a Zookeeper ensemble there:

```bash
kubectl create ns hip-project
kubectl kudo install zookeeper --instance=zk-dev -n hip-project
```

Then, install a kafka cluster for developers pointing it at this Zookeeper.
You need to override the `ZOOKEEPER_URI` parameter to match the custom Zookeeper instance name.

```bash
kubectl kudo install kafka --instance=kafka-dev -n hip-project \
  -p ZOOKEEPER_URI="zk-dev-zookeeper-0.zk-dev-hs:2181,zk-dev-zookeeper-1.zk-dev-hs:2181,zk-dev-zookeeper-2.zk-dev-hs:2181"
```

Next, install a kafka cluster for QA. This example shows how to point KUDO kafka at a Zookeeper instance
that is running in a different namespace (`default` in this case)

```bash
kubectl kudo install kafka --instance=kafka-qa -n hip-project \
  -p ZOOKEEPER_URI="zookeeper-instance-zookeeper-0.zookeeper-instance-hs.default:2181,zookeeper-instance-zookeeper-1.zookeeper-instance-hs.default:2181,zookeeper-instance-zookeeper-2.zookeeper-instance-hs.default:2181"
```
