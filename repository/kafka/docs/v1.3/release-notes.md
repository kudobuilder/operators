# Release notes 

## latest

- Apache Kafka upgraded to 2.5.1

## v1.3.1

- Fixed external service plan [pull/268](https://github.com/kudobuilder/operators/pull/268)

## v1.3.0

- Apache Kafka upgraded to 2.5.0

## v1.2.1

- Remove unused collectors from node exporter sidecar
- Introduce new plans to fix the errors when re-running a plan
- Add built-in [Cruise Control integration](./cruise-control.md)
- Add built-in [Kafka Connect integration](./kafka-connect.md)
- Apache Kafka upgraded to 2.4.1

## v1.2.0

- Updated operator.yaml to adopt to KUDO `0.10.0`

## v1.1.0

- Apache Kafka upgraded to 2.4.0

## v1.0.2

- Add parameter `KERBEROS_USE_TCP` to use TCP protocol for KDC connection
- Add parameter `ADD_SERVICE_MONITOR` to create a service monitor for KUDO Kafka cluster.
- Enabled [external KUDO Kafka access](./external-access.md).
- Add parameter `RUN_USER_WORKLOAD` to run some [testing workload over Kafka service](./kudo-kafka-runbook.md).
- Add disk usage [metrics](./monitoring.md)
- Add built-in [mirror-maker integration](./mirrormaker.md)

## v1.0.1

- Apache Kafka upgraded to 2.3.1

## v1.0.0

- Exposed configuration for livenessProbe and readinessProbe
- User can enable advanced service health checks. Option to choose between a simple port-based check and an advanced producer-consumer check based on a custom heartbeat topic
- Support for TLS encryption with custom certificates
- Support for Kerberos authentication
- Support for Kafka AuthZ

## v0.2.0 
July 30th, 2019

- Apache Kafka upgraded to 2.3.0
- livenessProbe and readinessProbes made less aggressive
- Added CPU/Memory limits for the stateful pods
- Updated the default value of Zookeeper URI
- not-allowed plan added to prevent updating storage parameters
