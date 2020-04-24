# Runbook: Exposing a KUDO Kafka cluster externally

This runbook explains how to expose a KUDO Kafka cluster to the outside of the Kubernetes cluster, using the `Service` of type `LoadBalancer`

## Pre-conditions

- A Kubernetes cluster with KUDO version >= 0.10.1 installed
- Have a KUDO Kafka cluster version 1.2.0 up and running in the namespace `kudo-kafka`
- Have binaries of `jq` installed in the `$PATH`

## Steps

#### 1. Get the KUDO Kafka Instance object name

`kubectl get instances.kudo.dev -n kudo-kafka`

expected output are the KUDO Instance objects present in the namespace `kudo-kafka`:

```bash
NAME                 AGE
kafka-instance       82m
zookeeper-instance   82m
```

#### 2. Update KUDO Kafka Instance object name

`kubectl kudo update --instance=kafka-instance -n kudo-kafka -p EXTERNAL_ADVERTISED_LISTENER=true -p EXTERNAL_ADVERTISED_LISTENER_TYPE=LoadBalancer`

expected output is the confirmation of the instance being updated.

```
Instance kafka-instance was updated
```

#### 3. Verify the KUDO Kafka Instance external services

`kubectl get service -n kudo-kafka`

The expected output should show the services with external suffix that are used for KUDO Kafka external access. 

```
NAME                              TYPE           CLUSTER-IP    EXTERNAL-IP                                                               PORT(S)                               AGE
kafka-instance-kafka-0-external   LoadBalancer   10.0.2.51     a17e18d9241e14a1aacae2cc2191f04a-926669611.us-west-2.elb.amazonaws.com    9097:30274/TCP                        37s
kafka-instance-kafka-1-external   LoadBalancer   10.0.56.59    a2e70588eba294115a169957afa5f9ef-1559859741.us-west-2.elb.amazonaws.com   9097:31314/TCP                        37s
kafka-instance-kafka-2-external   LoadBalancer   10.0.42.65    a75a77687237d480b90c56f17d42a0c4-911598769.us-west-2.elb.amazonaws.com    9097:31296/TCP                        37s
kafka-instance-svc                ClusterIP      None          <none>                                                                    9093/TCP,9092/TCP,9094/TCP,9096/TCP   81m
zookeeper-instance-cs             ClusterIP      10.0.37.249   <none>                                                                    2181/TCP                              81m
zookeeper-instance-hs             ClusterIP      None          <none>                                                                    2888/TCP,3888/TCP                     81m
```

#### 4. Verify the KUDO Kafka brokers advertised listeners

`kubectl get pods -n kudo-kafka -l "kudo.dev/instance=kafka-instance" -o json | jq -r '.items[].metadata.name' | xargs -I {} kubectl -n kudo-kafka exec {} -c k8skafka sed 's,$,\n,' external.advertised.listeners`

The expected output is the hostnames exactly as present in `EXTERNAL-IP` of the step 3.

```
a17e18d9241e14a1aacae2cc2191f04a-926669611.us-west-2.elb.amazonaws.com:9097
a2e70588eba294115a169957afa5f9ef-1559859741.us-west-2.elb.amazonaws.com:9097
a75a77687237d480b90c56f17d42a0c4-911598769.us-west-2.elb.amazonaws.com:9097
```

The Kafka cluster is now available using those hostnames.