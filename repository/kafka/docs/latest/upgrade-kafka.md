# Runbook: Upgrade KUDO Kafka 

This runbook explains how to upgrade a running KUDO Kafka to a newer version of KUDO Kafka.

## Pre-conditions

- Kubernetes cluster with KUDO version >= 0.11.0 installed
- Have a KUDO Kafka cluster version 1.2.0 up and running in the namespace `kudo-kafka`
- Have binaries of `jq` and `grep` installed in the `$PATH`

## Steps

### Verifying if KUDO Kafka is ready for the upgrade

#### 1. Get the KUDO Kafka Instance object name

Verify the KUDO Kafka instance object is present in the expected namespace

`kubectl get instances -n kudo-kafka`

expected output are the KUDO Instance objects present in the namespace `kudo-kafka`:

```bash
NAME    AGE
kafka   71m
zk      130m
```

#### 2. Verify the KUDO Kafka instance plans are COMPLETE 

`kubectl kudo plan status --instance=kafka -n kudo-kafka`

expected output is the plan status for instance `kafka`:

```
Plan(s) for "kafka" in namespace "kudo-kafka":
.
└── kafka (Operator-Version: "kafka-1.2.0" Active-Plan: "deploy")
    ├── Plan deploy (serial strategy) [COMPLETE], last updated 2020-04-23 13:13:30
    │   └── Phase deploy-kafka (serial strategy) [COMPLETE]
    │       └── Step deploy [COMPLETE]
    ├── Plan mirrormaker (serial strategy) [NOT ACTIVE]
    │   └── Phase deploy-mirror-maker (serial strategy) [NOT ACTIVE]
    │       └── Step deploy [NOT ACTIVE]
    └── Plan not-allowed (serial strategy) [NOT ACTIVE]
        └── Phase not-allowed (serial strategy) [NOT ACTIVE]
            └── Step not-allowed [NOT ACTIVE]
```
￼
#### 3. Get the Operator Version of KUDO Kafka Instance


 From step 1 we know the name of KUDO Kafka instance is `kafka`. We can get the Operator Version of the KUDO Kafka Instance.
`kubectl get instance kafka -n kudo-kafka -o json | jq -r '.spec.operatorVersion.name'`

expected output is the operator version
```bash
kafka-1.2.0
```

#### 4. Get the installed operator versions of KUDO Kafka

`kubectl get operatorversions -n kudo-kafka`

expected output is the list the operator versions installed in the namespace `kudo-kafka`

```
NAME              AGE
kafka-1.2.0       4m51s
zookeeper-0.3.0   5m39s
```

### Preparing for the upgrade

#### 5. Verify the inter.broker.protocol.version is matching the current OperatorVersion

Get the `inter.broker.protocol.version` version in the instance.

`kubectl exec -ti kafka-kafka-2 -n kudo-kafka -c k8skafka -- cat /opt/kafka/server.properties  | grep inter.broker.protocol.version`

expected output is the `inter.broker.protocol.version`
```
inter.broker.protocol.version=2.1
```

The `inter.broker.protocol.version` should match with the app minor version

`kubectl get operatorversion -n kudo-kafka kafka-1.2.0 -o json | jq -r '.spec.appVersion'`
in this case the expected output is the Kafka version

```
2.4.0
```

If `inter.broker.protocol.version` already matches the app version, skip to step 7.


#### 6. Update the inter.broker.protocol.version to match the current version


`kubectl kudo update -n kudo-kafka --instance=kafka -p INTER_BROKER_PROTOCOL_VERSION=2.4`

expected output is confirmation that instance has been updated.
```
Instance kafka was updated.
```

Repeat the step 5 to confirm that now the `inter.broker.protocol.version` is matching app version.

#### 7. Install the new OperatorVersion using --skip-instance

Install the OperatorVersion to what we are upgrading using the `skip-instance` flag. If the new OperatorVersion is already installed you can skip to the step 7.

`kubectl kudo install kafka -n kudo-kafka --operator-version=1.2.1 --skip-instance`

expected output is the CRDs installed for the OperatorVersion

```
operatorversion.kudo.dev/v1beta1/kafka-1.2.1 created
```

#### 8. Verify the new OperatorVersion is installed correctly

`kubectl get operatorversions -n kudo-kafka`

expected output is the list the operator versions installed in the namespace `kudo-kafka`

```
NAME              AGE
kafka-1.2.0       13m
kafka-1.2.1       42s
zookeeper-0.3.0   13m
```
### Upgrade the KUDO Kafka Instance

#### 9. Upgrade the KUDO Kafka Instance

`kubectl kudo upgrade kafka --instance=kafka --operator-version=1.2.1 -n kudo-kafka`

expected output is the confirmation that instance kafka has been updated

```
instance.kudo.dev/v1beta1/kafka updated
```

check the plan status

`kubectl kudo plan status --instance=kafka -n kudo-kafka`

expected output should show `deploy` in progress and the `Operator-Version` to be `kafka-1.2.1`

```
Plan(s) for "kafka" in namespace "kudo-kafka":
.
└── kafka (Operator-Version: "kafka-1.2.1" Active-Plan: "deploy")
    ├── Plan cruise-control (serial strategy) [NOT ACTIVE]
    │   └── Phase cruise-addon (serial strategy) [NOT ACTIVE]
    │       └── Step deploy-cruise-control [NOT ACTIVE]
    ├── Plan deploy (serial strategy) [IN_PROGRESS], last updated 2020-04-23 13:26:47
    │   ├── Phase deploy-kafka (serial strategy) [IN_PROGRESS]
    │   │   ├── Step generate-tls-certificates [COMPLETE]
    │   │   ├── Step configuration [COMPLETE]
    │   │   ├── Step service [COMPLETE]
    │   │   └── Step app [IN_PROGRESS]
    │   └── Phase addons (parallel strategy) [PENDING]
    │       ├── Step monitoring [PENDING]
    │       ├── Step access [PENDING]
    │       ├── Step mirror [PENDING]
    │       └── Step load [PENDING]
    ├── Plan external-access (serial strategy) [NOT ACTIVE]
    │   └── Phase resources (serial strategy) [NOT ACTIVE]
    │       └── Step deploy [NOT ACTIVE]
    ├── Plan kafka-connect (serial strategy) [NOT ACTIVE]
    │   └── Phase deploy-kafka-connect (serial strategy) [NOT ACTIVE]
    │       ├── Step deploy [NOT ACTIVE]
    │       └── Step setup [NOT ACTIVE]
    ├── Plan mirrormaker (serial strategy) [NOT ACTIVE]
    │   └── Phase app (serial strategy) [NOT ACTIVE]
    │       └── Step deploy [NOT ACTIVE]
    ├── Plan not-allowed (serial strategy) [NOT ACTIVE]
    │   └── Phase not-allowed (serial strategy) [NOT ACTIVE]
    │       └── Step not-allowed [NOT ACTIVE]
    ├── Plan service-monitor (serial strategy) [NOT ACTIVE]
    │   └── Phase enable-service-monitor (serial strategy) [NOT ACTIVE]
    │       └── Step deploy [NOT ACTIVE]
    ├── Plan update-instance (serial strategy) [NOT ACTIVE]
    │   └── Phase app (serial strategy) [NOT ACTIVE]
    │       ├── Step conf [NOT ACTIVE]
    │       ├── Step svc [NOT ACTIVE]
    │       └── Step sts [NOT ACTIVE]
    └── Plan user-workload (serial strategy) [NOT ACTIVE]
        └── Phase workload (serial strategy) [NOT ACTIVE]
            └── Step toggle-workload [NOT ACTIVE]
```

Once the pods are ready, which can be checked using next command
`kubectl get pods -n kudo-kafka`
the expected output is the list of the pods

```
NAME                    READY   STATUS    RESTARTS   AGE
kafka-kafka-0    2/2     Running   0          2m47s
kafka-kafka-1    2/2     Running   0          3m28s
kafka-kafka-2    2/2     Running   0          4m14s
```

Once the are passing the both readiness and liveness checks the plan should be complete
`kubectl kudo plan status --instance=kafka -n kudo-kafka`

expected output should show the `deploy` plan complete and the `Operator-Version` to be `kafka-1.2.0`

```
Plan(s) for "kafka" in namespace "kudo-kafka":
.
└── kafka (Operator-Version: "kafka-1.2.1" Active-Plan: "deploy")
    ├── Plan cruise-control (serial strategy) [NOT ACTIVE]
    │   └── Phase cruise-addon (serial strategy) [NOT ACTIVE]
    │       └── Step deploy-cruise-control [NOT ACTIVE]
    ├── Plan deploy (serial strategy) [COMPLETE], last updated 2020-04-23 13:28:12
    │   ├── Phase deploy-kafka (serial strategy) [COMPLETE]
    │   │   ├── Step generate-tls-certificates [COMPLETE]
    │   │   ├── Step configuration [COMPLETE]
    │   │   ├── Step service [COMPLETE]
    │   │   └── Step app [COMPLETE]
    │   └── Phase addons (parallel strategy) [COMPLETE]
    │       ├── Step monitoring [COMPLETE]
    │       ├── Step access [COMPLETE]
    │       ├── Step mirror [COMPLETE]
    │       └── Step load [COMPLETE]
    ├── Plan external-access (serial strategy) [NOT ACTIVE]
    │   └── Phase resources (serial strategy) [NOT ACTIVE]
    │       └── Step deploy [NOT ACTIVE]
    ├── Plan kafka-connect (serial strategy) [NOT ACTIVE]
    │   └── Phase deploy-kafka-connect (serial strategy) [NOT ACTIVE]
    │       ├── Step deploy [NOT ACTIVE]
    │       └── Step setup [NOT ACTIVE]
    ├── Plan mirrormaker (serial strategy) [NOT ACTIVE]
    │   └── Phase app (serial strategy) [NOT ACTIVE]
    │       └── Step deploy [NOT ACTIVE]
    ├── Plan not-allowed (serial strategy) [NOT ACTIVE]
    │   └── Phase not-allowed (serial strategy) [NOT ACTIVE]
    │       └── Step not-allowed [NOT ACTIVE]
    ├── Plan service-monitor (serial strategy) [NOT ACTIVE]
    │   └── Phase enable-service-monitor (serial strategy) [NOT ACTIVE]
    │       └── Step deploy [NOT ACTIVE]
    ├── Plan update-instance (serial strategy) [NOT ACTIVE]
    │   └── Phase app (serial strategy) [NOT ACTIVE]
    │       ├── Step conf [NOT ACTIVE]
    │       ├── Step svc [NOT ACTIVE]
    │       └── Step sts [NOT ACTIVE]
    └── Plan user-workload (serial strategy) [NOT ACTIVE]
        └── Phase workload (serial strategy) [NOT ACTIVE]
            └── Step toggle-workload [NOT ACTIVE]
```

#### 10. Verify the Kafka version through the pod logs
`kubectl logs kafka-kafka-0 -c k8skafka -n kudo-kafka | grep "Kafka version:"`

The expected output is the Kafka version and that should be the upgraded version `2.4.1`

```
[2020-04-23 07:58:00,246] INFO Kafka version: 2.4.1 (org.apache.kafka.common.utils.AppInfoParser)
```

#### 11. Verify the Kafka version through the container version

`kubectl get pods kafka-kafka-0 -n kudo-kafka -o json | jq -r '.spec.containers[].image'`

The expected output will show the container images used by the KUDO Kafka pods. The `mesosphere/kafka` image should be the upgraded version `2.4.1-1.2.1`

```
quay.io/prometheus/node-exporter:v0.18.1
mesosphere/kafka:2.4.1-1.2.1
```

#### 12. Verify the Kafka version through the app version of the installed KUDO Instance

`kubectl get instances.kudo.dev kafka -n kudo-kafka -o json | jq -r .spec.operatorVersion.name | xargs kubectl get operatorversion -n kudo-kafka -o json | jq -r .spec.appVersion`

The expected output should be the app version specified in the operator version of the instance

```
2.4.1
```

#### 13. (Optional) Bump the `inter.broker.protocol.version` to upgraded version

`kubectl kudo update --instance=kafka -n kudo-kafka -p INTER_BROKER_PROTOCOL_VERSION=2.4`

## Future improvements

Custom upgrade plans by KUDO would help to automate steps of verifying the `inter.broker.protocol.version` and bumping it to match the current version.