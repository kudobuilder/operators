KUDO Spark Operator Monitoring
---

Out of the box, the `kudo-spark-operator` has enabled metrics reporting. 
By default, it supports integration with the [Prometheus operator](https://github.com/coreos/prometheus-operator).

Prometheus Operator relies on `ServiceMonitor` kind which describes the set of targets to be monitored. 
KUDO Spark Operator configures `ServiceMonitor`s for both the Operator and submitted Spark Applications automatically 
when monitoring is enabled.

#### Exporting Spark Operator and Spark Application metrics to Prometheus

##### Prerequisites
* KUDO v0.10.0 or later
* The *`prometheus-operator`*.
If you don't already have the `prometheus-operator` installed on your Kubernetes cluster, you can do so by following
the [quick start guide](https://github.com/coreos/prometheus-operator#quickstart).

##### Metrics configuration
Metrics reporting is enabled by default. Service endpoints and ServiceMonitor resources are configured to work with Prometheus Operator
out of the box.

Full list of metrics configuration parameters and defaults is available in KUDO Spark [params.yaml](../../operator/params.yaml).

##### Running Spark Application with metrics enabled
1) Composing your Spark Application yaml:
   - use the following Spark image which includes the `JMXPrometheus` exporter jar: `mesosphere/spark:spark-2.4.3-hadoop-2.9-k8s`
   - enable Driver and Executors metrics reporting by adding the following configuration into `SparkApplication` `spec` section:
     ```yaml
       monitoring:
         exposeDriverMetrics: true
         exposeExecutorMetrics: true
         prometheus:
           jmxExporterJar: "/prometheus/jmx_prometheus_javaagent-0.11.0.jar"
           port: 8090
     ```  
     `spec.momitoring.prometheus.port` value should be the same for all submitted Spark Applications in order for metrics to be scraped.
   - if it's necessary to expose the metrics endpoint on a port other than `8090`, do the following:
     - specify desired port when installing the `kudo-spark-operator`:  
 
     ```
     kubectl kudo install <operator> -p appMetricsPort=<desired_port>
     ```
     - change the `port` value in the `SparkApplication` yaml definition (`spec.monitoring.prometheus.port`)    
   - Mark `driver` and/or `executor` with the label `metrics-exposed: "true"` -
     ```yaml
     spec:
       driver:
         labels:
            metrics-exposed: "true"
       executor:
         labels:
           metrics-exposed: "true"
     ```
   - Install the SparkApplication:
     ```
     kubectl apply -f <path_to_the_application_yaml>   
     ```
   Full application configuration example is available in [spark-application-with-metrics.yaml](resources/monitoring/spark-application-with-metrics.yaml)
1) Now, go to the prometheus dashboard (e.g. `<kubernetes_endpoint_url>/ops/portal/prometheus/graph`) and search for metrics 
starting with 'spark'. The Prometheus URI might be different depending on how you configured and installed the `prometheus-operator`. 

#### Dashboards
 * [Spark Applications Dashboard](resources/dashboards/grafana_spark_applications.json) 
 * [Spark Operator Dashboard](resources/dashboards/grafana_spark_operator.json)
 
 Dashboard installation : 
1) Open the Grafana site (e.g. `<kubernetes_endpoint_url>/ops/portal/grafana`).  
1) Press + button and pick `Import` item from the menu.  
1) Copy content of the dashboard json file and paste it to the textarea on importing form. 

For more information visit Grafana documentation: [Importing a dashboard guide](https://grafana.com/docs/reference/export_import/#importing-a-dashboard). 
