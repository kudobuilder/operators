# Security

The KUDO Confluent Schema Registry service supports Confluent Schema Registry's native transport **encryption** mechanism to connect with Kafka’s brokers configured for secured connections. The service provides automation and orchestration to simplify the use of these important features. For more information on Confluent Schema Registry’s security, read the [security](https://docs.confluent.io/current/schema-registry/security/index.html) section of official Confluent Schema Registry documentation.

## Encryption

By default, KUDO Kafka brokers use the plaintext protocol for its inter-broker communication. It is recommended to enable the TLS encryption, to secure the communication between brokers. The Confluent Schema Registry can be configured to connect with Kafka brokers over a secure connection with an appropriate encryption mechanism.

### Enabling TLS encryption

To connect KUDO Confluent Schema Registry with Kafka Brokers configured with TLS, the same TLS certificate and key that is used to setup Kafka's transport encryption needs to be used to create a new Kubernetes TLS secret. 

Here, we are assuming that the TLS Certificate file name is `tls.cert` and key name is `tls.key` that is used for Kafka TLS encryptions. We create a new Kubernetes TLS secret for KUDO Confluent Schema Registry as:

```
$ kubectl create secret tls confluent-schema-registry-tls --cert=tls.crt --key=tls.key
```

:warning: Make sure to create the certificate in the same namespace where the KUDO Confluent Schema Registry is being installed.

Now, to connect with Kafka Brokers configured with TLS:
- Assuming we are connecting to a KUDO Kafka instance with [transport encryption enabled](https://github.com/kudobuilder/operators/blob/master/repository/kafka/docs/latest/security.md#enabling--tls-encryption) pass the list of Fully Qualified Domain Name (FQDN) of each Kafka Broker as `bootstrap.servers` parameter.
- Make the `TRANSPORT_ENCRYPTION_ENABLED` parameter value as `true`.
- Supply the secret created before i.e. `confluent-schema-registry-tls` to be passed as parameter `TLS_SECRET_NAME`.

```
$ kubectl kudo install confluent-schema-registry \
    --instance=schema-registry  \
    -p KAFKA_BOOTSTRAP_SERVERS="SSL://kafka-kafka-0.kafka-svc.default.svc.cluster.local:9095,SSL://kafka-kafka-1.kafka-svc.default.svc.cluster.local:9095,SSL://kafka-kafka-2.kafka-svc.default.svc.cluster.local:9095" \
    -p TRANSPORT_ENCRYPTION_ENABLED=true \
    -p TLS_SECRET_NAME=confluent-schema-registry-tls
```

## Authentication

KUDO Confluent Schema Registry service supports connecting with Kafka broker's configured with TLS authentication mechanism. TLS authentication requires TLS encryption to be enabled. 

### Authenticating KUDO Confluent Schema Registry with a secure Kafka Cluster

Follow the steps of [Enabling KUDO Kafka for TLS encryption](https://github.com/kudobuilder/operators/blob/master/repository/kafka/docs/latest/security.md#enabling--tls-encryption) and enable the TLS authentication by setting the parameter `SSL_AUTHENTICATION_ENABLED` to `true` as:

```
$ kubectl kudo install kafka \
  --instance=kafka \
    -p AUTHORIZATION_ENABLED=true \
    -p AUTHORIZATION_ALLOW_EVERYONE_IF_NO_ACL_FOUND=true \
    -p TRANSPORT_ENCRYPTION_ENABLED=true \
    -p TRANSPORT_ENCRYPTION_ALLOW_PLAINTEXT=false \
    -p SSL_AUTHENTICATION_ENABLED=true
```

Now, we can connect KUDO Confluent Schema Registry with Kafka Brokers using TLS Authentication, similar to the [TLS encryption](#enabling-tls-encryption):

```
$ kubectl kudo install confluent-schema-registry \
    --instance=schema-registry  \
    -p KAFKA_BOOTSTRAP_SERVERS="SSL://kafka-kafka-0.kafka-svc.default.svc.cluster.local:9095,SSL://kafka-kafka-1.kafka-svc.default.svc.cluster.local:9095,SSL://kafka-kafka-2.kafka-svc.default.svc.cluster.local:9095" \
    -p TRANSPORT_ENCRYPTION_ENABLED=true \
    -p TLS_SECRET_NAME=confluent-schema-registry-tls
```

## Authorization

KUDO Confluent Schema Registry supports connecting to ACL authorization enabled Apache Kafka brokers.  To use Kafka’s ACLs with Confluent Schema Registry as a client, TLS authentication must be enabled as detailed [above](#authentication).

### Authorizing KUDO Confluent Schema Registry with a secure Kafka Cluster

#### Prerequisites

* Completion of TLS authentication as detailed [above](#authentication).

Install the KUDO Kafka service with [TLS authorization enabled](https://github.com/kudobuilder/operators/blob/master/repository/kafka/docs/latest/security.md#example-with-tls):

```
$ kubectl kudo install kafka \
  --instance=kafka \
    -p ZOOKEEPER_URI=zk-zookeeper-0.zk-hs:2181,zk-zookeeper-1.zk-hs:2181,zk-zookeeper-2.zk-hs:2181 \
    -p BROKER_CPUS=200m \
    -p BROKER_COUNT=3 \
    -p BROKER_MEM=800m \
    -p DISK_SIZE=10Gi \
    -p AUTHORIZATION_ENABLED=true \
    -p AUTHORIZATION_ALLOW_EVERYONE_IF_NO_ACL_FOUND=false \
    -p AUTHORIZATION_SUPER_USERS="User:SchemaRegistryClient" \
    -p TRANSPORT_ENCRYPTION_ENABLED=true \
    -p TRANSPORT_ENCRYPTION_ALLOW_PLAINTEXT=false \
    -p SSL_AUTHENTICATION_ENABLED=true
```

NOTE: To grant super user permission to KUDO Confluent Schema Registry, the client name that is provided to Schema Registry needs to be added to the `AUTHORIZATION_SUPER_USERS` parameter for KUDO Kafka. The client name can be configured using `SSL_AUTHENTICATION_CLIENT_NAME` parameter which has a default value  `SchemaRegistryClient`. 

Example of connecting KUDO Schema Registry with KUDO Kafka using TLS authentication with client name specified as above:
```
$ kubectl kudo install confluent-schema-registry \
    --instance=schema-registry  \
    -p KAFKA_BOOTSTRAP_SERVERS="SSL://kafka-kafka-0.kafka-svc.default.svc.cluster.local:9095,SSL://kafka-kafka-1.kafka-svc.default.svc.cluster.local:9095,SSL://kafka-kafka-2.kafka-svc.default.svc.cluster.local:9095" \
    -p TRANSPORT_ENCRYPTION_ENABLED=true \
    -p TLS_SECRET_NAME=confluent-schema-registry-tls \
    -p SSL_AUTHENTICATION_CLIENT_NAME=SchemaRegistryClient
```