# Monitoring

KUDO Kafka operator comes by default the JMX Exporter agent enabled. 

When Kafka operator deployed with parameter `METRICS_ENABLED=true` (which defaults to `true`) then:

- Each broker bootstraps with [JMX Exporter](https://github.com/prometheus/jmx_exporter) java agent exposing the metrics at `9094/metrics`
- Adds a port named `metrics` to the Kafka Service
- Adds a label `kubeaddons.mesosphere.io/servicemonitor: "true"` for the service monitor discovery. 


```
kubectl describe svc kafka-svc
...
Port:              metrics  9094/TCP
TargetPort:        9094/TCP
...
```

### Using Prometheus Service Monitor

To use the prometheus service monitor, its necessary to have installed the prometheus operator previously in the cluster.

If the Kafka Cluster Service in the default namespace, we can use the next example of the service-monitor. The `service-monitor.yaml` file referenced below is available ![here](https://raw.githubusercontent.com/kudobuilder/operators/master/repository/kafka/docs/v0.1/resources/service-monitor.yaml).
```
kubectl create -f resources/service-monitor.yaml
```

Install the [grafana dashboard](./resources/grafana-dashboard.json), and we should be able to see the Kafka dashaboard.

![Grafana Dashboards](./resources/grafana-capture.png)

### Disable JMX Exporter

 ```
kubectl kudo install kafka --instance=kafka --parameter METRICS_ENABLED=false
 ```

