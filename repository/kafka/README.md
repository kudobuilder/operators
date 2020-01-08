![kudo-kafka](./docs/latest/resources/images/kudo-kafka.png)

# KUDO Kafka Operator

The KUDO Kafka operator creates, configures and manages [Apache Kafka](https://kafka.apache.org/) clusters running on Kubernetes.

### Overview

KUDO Kafka is a Kubernetes operator built on [KUDO](kudo.dev) to manage Apache Kafka in a scalable, repeatable, and standardized way over Kubernetes. Currently KUDO Kafka supports:

- Securing the cluster in various ways: TLS encryption, Kerberos authentication, Kafka AuthZ
- Prometheus metrics right out of the box with example Grafana dashboards
- Kerberos support
- Graceful rolling updates for any cluster configuration changes
- Graceful rolling upgrades when upgrading the operator version
- External access through LB/Nodeports
- Mirror-maker integration

To get more information around KUDO Kafka architecture please take a look on the [KUDO Kafka concepts](./docs/latest/concepts.md) document.

## Getting started

The latest stable version of Kafka operator is `1.1.0`
For more details, please see the [v1.1 docs](./docs/v1.1) folder.


## Version Chart

| KUDO Kafka | Apache Kafka | Minimum KUDO Version |
| ---------- | ------------ | -------------------- |
| 1.0.0      | 2.3.0        | 0.8.0                |
| 1.0.1      | 2.3.1        | 0.8.0                |
| 1.0.2      | 2.3.1        | 0.8.0                |
| **1.1.0**  | **2.4.0**    | **0.9.0**            |
| latest     | 2.4.0        | 0.9.0                |

