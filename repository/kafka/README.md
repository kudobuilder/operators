![kudo-kafka](./docs/latest/resources/images/kudo-kafka.png)

# KUDO Kafka Operator

The KUDO Kafka operator creates, configures and manages [Apache Kafka](https://kafka.apache.org/) clusters running on Kubernetes.

### Overview

KUDO Kafka is a Kubernetes operator built on [KUDO](kudo.dev) to manage Apache Kafka in a scalable, repeatable, and standardized way over Kubernetes. Currently KUDO Kafka supports:

- Secure Apache Kafka Clusters, support for **TLS  encryption** and **authentication**.
- Metrics out of the box using **Prometheus**, and **Grafana** dashboard.
- **Kerberos** support.
- Graceful **rolling upgrades** for the cluster configuration and operator version.

To get more information around KUDO Kafka architecture please take a look on the [KUDO Kafka concepts](./docs/latest/concepts.md) document.

## Getting started

The latest stable version of Kafka operator is `1.0.0`
For more details, please see the [docs](./docs/v1.0) folder.

For the latest master branch you can check  [docs](./docs/latest) docs 


## Version Chart

| KUDO Kafka Version | Apache Kafka Version | Status |
| ------------------ | -------------------- | ------ |
| 0.1.2              | 2.2.1                | beta   |
| 0.2.0              | 2.3.0                | beta   |
| **1.0.0**          | **2.3.0**            | **GA** |
| latest             | 2.3.0                | beta   |