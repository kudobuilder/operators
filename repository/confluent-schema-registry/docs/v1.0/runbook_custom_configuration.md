# Running Confluent Schema Registry with Custom Configuration

For customization as per the usage, there are various configurable properties for Confluent Schema Registry. We can find the description of available configurable properties at [Official Schema Registry Configuration Options](https://docs.confluent.io/current/schema-registry/installation/config.html#sr-configuration-options). Some configuration properties are mandatory to be declared to run the schema registry service successfully (Eg. `SCHEMA_REGISTRY_KAFKASTORE_BOOTSTRAP_SERVERS`). At some point in time, the user may need to declare properties that are not exposed as environment variables yet. So, to facilitate with such a request, we offer an option to supply custom configuration in Confluent Schema Registry properties.

To supply with desired configuration properties, the user first needs to create a ConfigMap stating the properties in a file. For example, let us consider a properties file `sr.properties` containing configuration properties values as:
```
prop.property1=value1
prop.property2=value2
```

To create a ConfigMap using this properties file, please refer the command:
```
kubectl create configmap conf-sr --from-file=./sr.properties
```
Before deploying Confluent Schema Registry service, please check that Kafka and Zookeeper service should be up and running in a healthy state.

We can pass the ConfigMap by specifying its name to parameter CUSTOM_SR_PROPERTIES_CM_NAME as:

```
kubectl kudo install confluent-schema-registry --instance=<instance-name>  -p CUSTOM_SR_PROPERTIES_CM_NAME=<ConfigMap-name>
```

In this case, we have:
```
kubectl kudo install confluent-schema-registry --instance=schema-registry -p CUSTOM_SR_PROPERTIES_CM_NAME=conf-sr
```
We can check the status of our service deployment by getting the list of available pods using `kubectl get pods`:
```
$ kubectl get pods
NAME                              READY   STATUS    RESTARTS   AGE
kafka-kafka-0                     2/2     Running   0          32m
kafka-kafka-1                     2/2     Running   0          32m
kafka-kafka-2                     2/2     Running   0          31m
schema-registry-random-pod-name   1/1     Running   0          9m52s
zk-zookeeper-0                    1/1     Running   0          4h8m
zk-zookeeper-1                    1/1     Running   0          4h8m
zk-zookeeper-2                    1/1     Running   0          4h8m
```


The Schema Registry pod deployment will show the addition of custom configs in pod logs:

```
$ kubectl logs schema-registry-random-pod-name
[2020-01-17 15:01:41,294] Appending custom configuration file /custom-configuration/sr.properties to the schema-registry.properties...
prop.property1=value1 prop.property2=value2
===> ENV Variables ...
```

Bash into pod to see the actual properties file which contains all added custom configuration properties. To bash into pod, use command `kubectl exec -ti <pod-name> bash`, For example:

```
$ kubectl exec -ti schema-registry-random-pod-name bash
root@schema-registry-random-pod-name:/# cat /etc/schema-registry/schema-registry.properties 
host.name=confluent-schema-registry
kafkastore.bootstrap.servers=kafka-kafka-0.kafka-svc:9093,kafka-kafka-1.kafka-svc:9093,kafka-kafka-2.kafka-svc:9093
prop.property1=value1
prop.property2=value2
```