# Security

KUDO Confluent REST Proxy service supports Confluent REST Proxy's native security features, including:

1. SSL for securing communication between REST clients and the REST Proxy (HTTPS)
2. SSL encryption between the REST Proxy and a secure Kafka cluster
3. SSL authentication between the REST Proxy and a secure Kafka Cluster

The service provides automation and orchestration to simplify the use of these important features. For more information on Confluent REST Proxy's security, read the [security](https://docs.confluent.io/current/kafka-rest/security.html) section of official Confluent REST Proxy documentation.

## Encryption

By default, KUDO Confluent REST Proxy use the http protocol for its communication with REST Proxy clients and Kafka `PLAINTEXT` protocol to communicate with Kafka Brokers. It is recommended to enable the TLS encryption to secure the communication with its clients and also the kafka brokers. 

### Enabling  TLS encryption

#### Manually generating certificate

Create the TLS certificate to be used for REST Proxy TLS encryptions

```
$ openssl req -x509 -newkey rsa:4096 -sha256 -nodes -keyout tls.key -out tls.crt -subj "/CN=Kafka" -days 365
```

Create a kubernetes TLS secret using the certificate created in previous step 

```
$ kubectl create secret tls kafka-tls -n kudo-kafka --cert=tls.crt --key=tls.key
```

:warning: Make sure to create the certificate in the same namespace where the KUDO Confluent REST Proxy is being installed.

:warning: Make sure to create the TLS secret (`TLS_SECRET_NAME`) from the same CA certs used by Kafka for enabling TLS.

:information_source: KUDO Confluent REST Proxy accepts two seperate CA certificates, one for encrypting communucation with the REST Proxy clients (`TLS_CLIENT_SECRET_NAME`) and the other for securing communication with Kafka Brokers (`TLS_SECRET_NAME`). In development environments the same TLS Secret can be used for both purposes, but it is recommended to use seperate secrets e.g "kafka-tls" and "rest-proxy-client-tls" for production environments.

#### Configuring KUDO Confluent REST Proxy with TLS enabled KUDO Kafka

Start KUDO Kafka operator with [TLS enabled](https://github.com/kudobuilder/operators/blob/master/repository/kafka/docs/latest/security.md#enabling--tls-encryption).

```
$ kubectl kudo install kafka \
    --instance=kafka-instance --namespace=kudo-kafka \
    -p TRANSPORT_ENCRYPTION_ENABLED=true \
    -p TRANSPORT_ENCRYPTION_ALLOW_PLAINTEXT=false \
    -p SSL_AUTHENTICATION_ENABLED=false \
    -p TLS_SECRET_NAME=kafka-tls
```

Start KUDO Confluent REST Proxy with `TRANSPORT_ENCRYPTION_ENABLED` enabled to connect to TLS enabled Kafka, and `TRANSPORT_ENCRYPTION_CLIENT_ENABLED` enabled to secure http communication with REST Proxy clients.

```
$ kubectl kudo install confluent-rest-proxy \
  --instance=confluent-rest-proxy --namespace=kudo-kafka \
  -p KAFKA_BOOTSTRAP_SERVERS="SSL://kafka-kafka-0.kafka-svc.kudo-kafka.svc.cluster.local:9095,SSL://kafka-kafka-1.kafka-svc.kudo-kafka.svc.cluster.local:9095,SSL://kafka-kafka-2.kafka-svc.kudo-kafka.svc.cluster.local:9095" \
  -p TLS_SECRET_NAME="kafka-tls" \
  -p TLS_CLIENT_SECRET_NAME="kafka-tls" \
  -p TRANSPORT_ENCRYPTION_ENABLED=true \
  -p TRANSPORT_ENCRYPTION_CLIENT_ENABLED=true
```

:information_source: `KAFKA_BOOTSTRAP_SERVERS` can be a list of any Apache Kafka brokers.

## Authentication

KUDO Confluent REST Proxy supports connecting to SSL authentication enabled Apache Kafka brokers.

### SSL authentication between the REST Proxy and a secure Kafka Cluster

SSL authentication requires TLS encryption to be enabled. The configuration of TLS authentication is a superset of the required configurations that enables TLS encryption and also TLS authentication. Its not possible to enable only the TLS authentication without enabling the TLS encryption.

Follow the steps of creating the TLS secret for the [TLS encryption](#enabling-tls-encryption) 

And enable the TLS encryption and also set the parameter `SSL_AUTHENTICATION_KAFKA_CLIENT_NAME` to the Kafka authenticated user name. This value is used by the operator to create a TLS certficate with the Common Name (CN) as the provided client name.

To use this feature with KUDO Kafka follow the steps of enabling [SSL authentication](https://github.com/kudobuilder/operators/blob/master/repository/kafka/docs/latest/security.md#tls-authentication).

```
$ kubectl kudo install confluent-rest-proxy \
  --instance=confluent-rest-proxy --namespace=kudo-kafka \
  -p KAFKA_BOOTSTRAP_SERVERS="SSL://kafka-kafka-0.kafka-svc.kudo-kafka.svc.cluster.local:9095,SSL://kafka-kafka-1.kafka-svc.kudo-kafka.svc.cluster.local:9095,SSL://kafka-kafka-2.kafka-svc.kudo-kafka.svc.cluster.local:9095" \
  -p TLS_SECRET_NAME="kafka-tls" \
  -p TRANSPORT_ENCRYPTION_ENABLED=true \
  -p SSL_AUTHENTICATION_KAFKA_CLIENT_NAME=RestProxyClient
```

### SSL authentication between the REST Proxy and REST Proxt clients

SSL authentication for REST Proxy client requires TLS client encryption to be enabled. The configuration of TLS client authentication is a superset of the required configurations that enables TLS client encryption and also TLS client authentication. Its not possible to enable only the TLS client authentication without enabling the TLS client encryption.

Follow the steps of creating the TLS secret for the [TLS encryption](#enabling-tls-encryption)

```
$ kubectl kudo install confluent-rest-proxy \
  --instance=confluent-rest-proxy --namespace=kudo-kafka \
  -p KAFKA_BOOTSTRAP_SERVERS="SSL://kafka-kafka-0.kafka-svc.kudo-kafka.svc.cluster.local:9095,SSL://kafka-kafka-1.kafka-svc.kudo-kafka.svc.cluster.local:9095,SSL://kafka-kafka-2.kafka-svc.kudo-kafka.svc.cluster.local:9095" \
  -p TLS_SECRET_NAME="kafka-tls" \
  -p TRANSPORT_ENCRYPTION_CLIENT_ENABLED=true \
  -p SSL_AUTHENTICATION_CLIENT_ENABLED=true
```
