# Running Confluent Rest Proxy with Custom Configuration

For customization as per the usage, there are various configurable properties for Confluent Rest Proxy. We can find the description of available configurable properties at [Official Rest Proxy Configuration Options](https://docs.confluent.io/current/kafka-rest/config.html#crest-configuration-options). Some configuration properties are mandatory to be declared to run the rest proxy service successfully (Eg. `KAFKA_REST_BOOTSTRAP_SERVERS`). At some point in time, the user may need to declare properties that are not exposed as environment variables yet. So, to facilitate with such a request, we offer an option to supply custom configuration in Confluent Rest Proxy properties.

To supply with desired configuration properties, the user first needs to create a ConfigMap stating the properties in a file. For example, let us consider a properties file `rp.properties` containing configuration properties values as:
```
prop.property1=value1
prop.property2=value2
```

To create a ConfigMap using this properties file, please refer the command:
```
kubectl create configmap conf-rp --from-file=./rp.properties
```
Before deploying Confluent Rest Proxy service, please check that Kafka and Zookeeper service should be up and running in a healthy state.

We can pass the ConfigMap by specifying its name to parameter CUSTOM_RP_PROPERTIES_CM_NAME as:

```
kubectl kudo install confluent-rest-proxy --instance=<instance-name>  -p CUSTOM_RP_PROPERTIES_CM_NAME=<ConfigMap-name>
```

In this case, we have:
```
kubectl kudo install confluent-rest-proxy --instance=rest-proxy -p CUSTOM_RP_PROPERTIES_CM_NAME=conf-rp
```
We can check the status of our service deployment by getting the list of available pods using `kubectl get pods`:
```
$ kubectl get pods
NAME                              READY   STATUS    RESTARTS   AGE
kafka-kafka-0                     2/2     Running   0          32m
kafka-kafka-1                     2/2     Running   0          32m
kafka-kafka-2                     2/2     Running   0          31m
rest-proxy-random-pod-name        1/1     Running   0          9m52s
zk-zookeeper-0                    1/1     Running   0          4h8m
zk-zookeeper-1                    1/1     Running   0          4h8m
zk-zookeeper-2                    1/1     Running   0          4h8m
```


The Rest Proxy pod deployment will show the addition of custom configs in pod logs:

```
$ kubectl logs rest-proxy-random-pod-name
[2020-01-17 15:01:41,294] Appending custom configuration file /custom-configuration/rp.properties to the kafka-rest.properties...
prop.property1=value1 prop.property2=value2
===> ENV Variables ...
```

Bash into pod to see the actual properties file which contains all added custom configuration properties. To bash into pod, use command `kubectl exec -ti <pod-name> bash`, For example:

```
$ kubectl exec -ti rest-proxy-random-pod-name bash
root@rest-proxy-random-pod-name:/# cat /etc/kafka-rest/kafka-rest.properties 
host.name=confluent-rest-proxy
kafkastore.bootstrap.servers=kafka-kafka-0.kafka-svc:9093,kafka-kafka-1.kafka-svc:9093,kafka-kafka-2.kafka-svc:9093
prop.property1=value1
prop.property2=value2
```