Release Notes
---

## 2.4.4-0.2.0 (latest)
* Spark Operator Docker image based on [apache/spark](https://github.com/apache/spark/) 2.4.4 with Hadoop 2.9.2 support
* Added Python and R support to Spark Operator image
* Added support for automatic installation of monitoring resources
* Added configuration parameters and documentation for HA installation
* Added documentation describing integration with Volcano batch scheduler

## beta1
* Spark Operator Docker image based on [mesosphere/spark](https://github.com/mesosphere/spark/) 2.4.3 with Hadoop 2.9.2 support
* Spark Operator based on version `v1beta2-1.0.1`
* Added Spark History Server support
* Added `ServiceMonitors` for integration with the Prometheus Operator
* Prometheus Java agent updated to version `0.11.0`
* Kubernetes Java client library updated to version `4.4.2`
