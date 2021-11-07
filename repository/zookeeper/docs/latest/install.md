# Installing the KUDO Zookeeper Operator

Requirements:

- Install the [KUDO controller](https://kudo.dev/docs/getting-started/)
- Install the [KUDO CLI](https://kudo.dev/docs/cli/)


## Installing the Operator

#### Install Zookeeper 

Please read the [limitations](./limitations.md) docs before creating the KUDO Zookeeper cluster.

```
kubectl kudo install zookeeper
```

Verify the if the deploy plan for `--instance=zookeeper-instance`, default instance name, is complete.
```
kubectl kudo plan status --instance=zookeeper-instance
Plan(s) for "zookeeper-instance" in namespace "default":
.
└── zookeeper-instance (Operator-Version: "zookeeper-0.3.0" Active-Plan: "deploy")
    ├── Plan deploy (serial strategy) [COMPLETE]
    │   ├── Phase zookeeper [COMPLETE]
    │   │   └── Step deploy (COMPLETE)
    │   └── Phase validation [COMPLETE]
    │       └── Step validation (COMPLETE)
    └── Plan validation (serial strategy) [NOT ACTIVE]
        └── Phase connection (parallel strategy) [NOT ACTIVE]
            └── Step connection (parallel strategy) [NOT ACTIVE]
                └── connection [NOT ACTIVE]
```

You can view all configuration options [here](./configuration.md)

#### Installing multiple Zookeeper Clusters

```
kubectl kudo install zookeeper --instance=zk-1
kubectl kudo install zookeeper --instance=zk-2
kubectl kudo install zookeeper --instance=zk-3
```

The above commands will install three zookeeper clusters.
