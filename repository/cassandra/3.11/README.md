# KUDO Cassandra Operator

The KUDO Cassandra Operator makes it easy to deploy and manage
[Apache Cassandra](http://cassandra.apache.org/) on Kubernetes.

| Konvoy                                                                                                                                                                                                                                                                                                                                                                                                      |
| ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| <a href="https://teamcity.mesosphere.io/viewType.html?buildTypeId=Frameworks_DataServices_Kudo_Cassandra_Nightly_CassandraNightlyKonvoyKudo&branch_Frameworks_DataServices_Kudo_Cassandra_Nightly=%3Cdefault%3E&tab=buildTypeStatusDiv"><img src="https://teamcity.mesosphere.io/app/rest/builds/buildType:(id:Frameworks_DataServices_Kudo_Cassandra_Nightly_CassandraNightlyKonvoyKudo)/statusIcon"/></a> |

## Getting started

The KUDO Cassandra operator requires [KUDO](https://kudo.dev/) and Kubernetes
versions as specified in [`operator.yaml`](operator/operator.yaml#L4-L5).

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
- Node-to-Node and Node-to-Client communication encryption

## Roadmap

- Backup/restore
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
- [Backup & Restore](/docs/backup.md)
- [Security](/docs/security.md)
- [Multi Datacenter](/docs/multidatacenter.md)
- [Parameters reference](/docs/parameters.md)

## Version Chart

| Version                                                                                          | Apache Cassandra version | Operator version | Minimum KUDO Version | Status | Release date |
| ------------------------------------------------------------------------------------------------ | ------------------------ | ---------------- | -------------------- | ------ | ------------ |
| [3.11.6-1.0.0](https://github.com/mesosphere/kudo-cassandra-operator/releases/tag/v3.11.6-1.0.0) | 3.11.6                   | 1.0.0            | 0.13.0               | GA     | 2020-06-04   |
| [3.11.5-0.1.2](https://github.com/mesosphere/kudo-cassandra-operator/releases/tag/v3.11.5-0.1.2) | 3.11.5                   | 0.1.2            | 0.10.0               | beta   | 2020-01-22   |
| [3.11.5-0.1.1](https://github.com/mesosphere/kudo-cassandra-operator/releases/tag/v3.11.5-0.1.1) | 3.11.5                   | 0.1.1            | 0.8.0                | beta   | 2019-12-12   |
| [3.11.4-0.1.0](https://github.com/mesosphere/kudo-cassandra-operator/releases/tag/v3.11.4-0.1.0) | 3.11.4                   | 0.1.0            | 0.8.0                | beta   | 2019-11-13   |
