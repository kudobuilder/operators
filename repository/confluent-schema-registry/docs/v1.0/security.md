# Security

The Confluent Schema Registry service supports native transport **encryption**, **authentication**, and **authorization** mechanisms to connect with Kafka’s brokers configured for secured connections. The service provides automation and orchestration to simplify the use of these important features. For more information on Confluent Schema Registry’s security while connecting with Kafka Brokers over secured connections, read the [security](https://docs.confluent.io/current/kafka/encryption.html#sr) section of official Confluent Schema Registry documentation.

## Encryption

By default, KUDO Kafka brokers use the plaintext protocol for its inter-broker communication. It is recommended to enable the TLS encryption, to secure the communication between brokers. The Confluent Schema Registry can be configured to connect with Kafka brokers over a secure connection with an appropriate encryption mechanism.

### Enabling TLS encryption

To connect Confluent Schema Registry with Kafka Brokers configured with TLS, get the TLS certificate and key that is used for Kafka TLS encryptions to create a new Kubernetes TLS secret for Confluent Schema Registry. 

Here, we are assuming that the TLS Certificate file name is `tls.cert` and key name is `tls.key` that is used for Kafka TLS encryptions. We create a new Kubernetes TLS secret for Confluent Schema Registry as:

```
$ kubectl create secret tls confluent-schema-registry-tls --cert=tls.crt --key=tls.key
```

:warning: Make sure to create the certificate in the same namespace where the KUDO Kafka is being installed.

Now, to connect with Kafka Brokers configured with TLS:
- Provide Fully Qualified Domain Name (FQDN) of each Kafka Broker(s) as `bootstrap.servers` parameter to connect with Kafka successfully. Eg. `KAFKA_BOOTSTRAP_SERVERS="SSL://kafka-kafka-0.kafka-svc.default.svc.cluster.local:9095,SSL://kafka-kafka-1.kafka-svc.default.svc.cluster.local:9095,SSL://kafka-kafka-2.kafka-svc.default.svc.cluster.local:9095"`.
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

Confluent Schema Registry service supports connecting with Kafka broker's configured with TLS authentication mechanism. TLS authentication requires TLS encryption to be enabled. 

The configuration of TLS authentication while connecting with Kafka brokers is a superset of the required Kafka Broker's configurations that enables TLS encryption and also TLS authentication. Its not possible to enable only the TLS authentication without enabling the TLS encryption.

### Configuration for KUDO Kafka for TLS Authentication

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

Now, we can connect Confluent Schema Registry with Kafka Brokers using TLS Authentication, similar to the [TLS encryption](#enabling-tls-encryption):

```
$ kubectl kudo install confluent-schema-registry \
    --instance=schema-registry  \
    -p KAFKA_BOOTSTRAP_SERVERS="SSL://kafka-kafka-0.kafka-svc.default.svc.cluster.local:9095,SSL://kafka-kafka-1.kafka-svc.default.svc.cluster.local:9095,SSL://kafka-kafka-2.kafka-svc.default.svc.cluster.local:9095" \
    -p TRANSPORT_ENCRYPTION_ENABLED=true \
    -p TLS_SECRET_NAME=confluent-schema-registry-tls
```

## Authorization

The KUDO Kafka service supports Kafka’s ACL-based authorization system.  To use Kafka’s ACLs with Confluent Schema Registry as a client, TLS authentication must be enabled as detailed [above](#authentication).

### Enable Authorization with TLS

#### Prerequisites

* Completion of TLS authentication as detailed [above](#authentication).

Install the KUDO Kafka service with the following options in addition to your own (remember, TLS authentication must be enabled):

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

NOTE: Here, we need to supply `AUTHORIZATION_SUPER_USERS` parameter as the client name that we provide to our Confluent Schema Registry client. It can be configured by `SSL_AUTHENTICATION_CLIENT_NAME` parameter of Schema Registry and its default value is `SchemaRegistryClient`.

Now, we can connect Confluent Schema Registry with Kafka Brokers using TLS Authentication, similar to the [TLS encryption](#enabling-tls-encryption), by supplying the client name to the `SSL_AUTHENTICATION_CLIENT_NAME` parameter, as configured in Kafka Broker's ACL during KUDO Kafka's deployment:

```
$ kubectl kudo install confluent-schema-registry \
    --instance=schema-registry  \
    -p KAFKA_BOOTSTRAP_SERVERS="SSL://kafka-kafka-0.kafka-svc.default.svc.cluster.local:9095,SSL://kafka-kafka-1.kafka-svc.default.svc.cluster.local:9095,SSL://kafka-kafka-2.kafka-svc.default.svc.cluster.local:9095" \
    -p TRANSPORT_ENCRYPTION_ENABLED=true \
    -p TLS_SECRET_NAME=confluent-schema-registry-tls \
    -p SSL_AUTHENTICATION_CLIENT_NAME=SchemaRegistryClient
```