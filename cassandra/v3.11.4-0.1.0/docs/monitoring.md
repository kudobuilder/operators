# Monitoring

The KUDO Cassandra operator will by default export metrics to Prometheus via a
Prometheus exporter based on the
[criteo/cassandra_exporter](https://github.com/criteo/cassandra_exporter).

A running Prometheus service is required for the Prometheus exporter to work.

When the KUDO Cassandra operator is deployed with the
`PROMETHEUS_EXPORTER_ENABLED` parameter set to `true` (the default):

- A `prometheus-exporter` container will run in the same pod as every Cassandra
  `node` container and listen for connections at `PROMETHEUS_EXPORTER_PORT`,
  which is set to `7200` by default.
- A `prometheus-exporter-port` will be added to the KUDO Cassandra operator
  [Service](https://kubernetes.io/docs/concepts/services-networking/service/).
- A
  [ServiceMonitor](https://coreos.com/operators/prometheus/docs/latest/user-guides/cluster-monitoring.html)
  will periodically fetch the
  [Service](https://kubernetes.io/docs/concepts/services-networking/service/)'s
  `prometheus-exporter-port` for metrics.
