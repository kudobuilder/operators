# KUDO Cassandra Operator

The KUDO Cassandra Operator makes it easy to deploy and manage
[Apache Cassandra](http://cassandra.apache.org/) on Kubernetes.

| Konvoy                                                                                                                                                                                                                                                                                                                                                                                                      |
| ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| <a href="https://teamcity.mesosphere.io/viewType.html?buildTypeId=Frameworks_DataServices_Kudo_Cassandra_Nightly_CassandraNightlyKonvoyKudo&branch_Frameworks_DataServices_Kudo_Cassandra_Nightly=%3Cdefault%3E&tab=buildTypeStatusDiv"><img src="https://teamcity.mesosphere.io/app/rest/builds/buildType:(id:Frameworks_DataServices_Kudo_Cassandra_Nightly_CassandraNightlyKonvoyKudo)/statusIcon"/></a> |

## Getting started

The KUDO Cassandra operator requires [KUDO](https://kudo.dev/)
[0.8.0](https://github.com/kudobuilder/kudo/releases/tag/v0.8.0) and Kubernetes
1.15.0.

To install it run

```bash
kubectl kudo install cassandra
```

## Features

- Configurable `cassandra.yaml` and `jvm.options` parameters
- JVM memory locking out of the box
- Prometheus metrics and Grafana dashboard
- Horizontal scaling
- Rolling parameter updates
- Readiness probe
- Unpriviledged container execution

## Roadmap

- Backup/restore
- TLS
- Rack-awareness
- Node replace
- Inter-pod anti-affinity
- RBAC, pod security policies
- Liveness probe
- Multi-datacenter support
- Diagnostics bundle

## Documentation

- [Installing](/docs/installing.md)
- [Accessing](/docs/accessing.md)
- [Managing](/docs/managing.md)
- [Upgrading](/docs/upgrading.md)
- [Monitoring](/docs/monitoring.md)
- [Parameters reference](/docs/parameters.md)

## Version Chart

| Version                                                                                          | Apache Cassandra version | Operator version | Minimum KUDO Version | Status | Release date |
| ------------------------------------------------------------------------------------------------ | ------------------------ | ---------------- | -------------------- | ------ | ------------ |
| [3.11.5-0.1.1](https://github.com/mesosphere/kudo-cassandra-operator/releases/tag/v3.11.5-0.1.1) | 3.11.5                   | 0.1.1            | 0.8.0                | beta   | 2019-12-12   |
| [3.11.4-0.1.0](https://github.com/mesosphere/kudo-cassandra-operator/releases/tag/v3.11.4-0.1.0) | 3.11.4                   | 0.1.0            | 0.8.0                | beta   | 2019-11-13   |
