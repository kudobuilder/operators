# Security

The KUDO Kafka service supports Kafka’s native transport **encryption**, **authentication**, and **authorization** mechanisms. The service provides automation and orchestration to simplify the use of these important features. For more information on Kafka’s security, read the [security](http://kafka.apache.org/documentation/#security) section of official Apache Kafka documentation.

## Encryption

By default, KUDO Kafka brokers use the plaintext protocol for its inter-broker communication. It is recommended to enable the TLS encryption, to secure the communication between brokers. 

### Enabling  TLS encryption

#### Manually generating certificate

Create the TLS certificate to be used for Kafka TLS encryptions

```
$ openssl req -x509 -newkey rsa:4096 -sha256 -nodes -keyout tls.key -out tls.crt -subj "/CN=Kafka" -days 365
```

Create a kubernetes TLS secret using the certificate created in previous step 

```
$ kubectl create secret tls kafka-tls -n kudo-kafka --cert=tls.crt --key=tls.key
```

:warning: Make sure to create the certificate in the same namespace where the KUDO Kafka is being installed.

```
$ kubectl kudo install kafka \
    --instance=kafka-instance --namespace=kudo-kafka \
    -p TRANSPORT_ENCRYPTION_ENABLED=true \
    -p TRANSPORT_ENCRYPTION_ALLOW_PLAINTEXT=false \
    -p SSL_AUTHENTICATION_ENABLED=false \
    -p TLS_SECRET_NAME=kafka-tls
```

#### Using Auto certificate generation

KUDO Kafka can automatically generate a CA certificate and create secrets which are then used by the brokers to set up Kafka transport encryption. 

```
kubectl kudo install kafka \
    --instance=kafka --namespace=kudo-kafka \
    -p TRANSPORT_ENCRYPTION_ENABLED=true \
    -p TRANSPORT_ENCRYPTION_ALLOW_PLAINTEXT=false \
    -p SSL_AUTHENTICATION_ENABLED=false \
    -p USE_AUTO_TLS_CERTIFICATE=true
```

:warning: If both `USE_AUTO_TLS_CERTIFICATE` and `TLS_SECRET_NAME` is provided, the operator will give precedence to Auto TLS certificates over the user provided TLS secret.

## Authentication

KUDO Kafka supports two authentication mechanisms, TLS and Kerberos. The two are supported independently and may not be combined. If both TLS and Kerberos authentication are enabled, the service will use Kerberos authentication

### TLS Authentication

TLS authentication requires TLS encryption to be enabled. The configuration of TLS authentication is a superset of the required configurations that enables TLS encryption and also TLS authentication. Its not possible to enable only the TLS authentication without enabling the TLS encryption.

Follow the steps of creating the TLS secret for the [TLS encryption](#enabling-tls-encryption) 

And enable the TLS encryption and also set the parameter `SSL_AUTHENTICATION_ENABLED` to `true`

```
$ kubectl kudo install kafka \
  --instance=kafka-instance --namespace=kudo-kafka \
    -p AUTHORIZATION_ENABLED=true \
    -p AUTHORIZATION_ALLOW_EVERYONE_IF_NO_ACL_FOUND=false \
    -p AUTHORIZATION_SUPER_USERS="User:User1" \
    -p TRANSPORT_ENCRYPTION_ENABLED=true \
    -p TRANSPORT_ENCRYPTION_ALLOW_PLAINTEXT=false \
    -p SSL_AUTHENTICATION_ENABLED=true
```



### Kerberos Authentication

Kerberos authentication relies on a central authority to verify that Kafka clients (be it broker, consumer, or producer) are who they say they are. KUDO Kafka integrates with your existing Kerberos infrastructure to verify the identity of clients.

#### Prerequisites

* The hostname and port of a KDC reachable from the inside of k8s cluster
* Sufficient access to the KDC to create Kerberos principals
* Sufficient access to the KDC to retrieve a keytab for the generated principals
* `kubectl` installed

#### Configure Kerberos Authentication

##### Create principals

The KUDO Kafka service requires a Kerberos principal for each broker to be deployed. Each principal must be of the form
```
<service primary>/kafka-instance-kafka-<broker index>.kafka-svc.<namespace>.svc.cluster.local@<service realm>
```
with:
* ```service primary = KERBEROS_PRIMARY```
* ```broker index = 0 up to BROKER_COUNT - 1```
* ```namespace = kubernetes namespace```
* ```service realm = KERBEROS_REALM```

For example, if installing with these options:
```
$ kubectl kudo install kafka \
  --instance=kafka-instance --namespace=kudo-kafka \
    -p ZOOKEEPER_URI=zk-zookeeper-0.zk-hs:2181,zk-zookeeper-1.zk-hs:2181,zk-zookeeper-2.zk-hs:2181 \
    -p KERBEROS_ENABLED=true \
    -p KERBEROS_DEBUG=false\
    -p KERBEROS_PRIMARY=kafka\
    -p KERBEROS_REALM=LOCAL\
    -p KERBEROS_KDC_HOSTNAME=kdc-service.kudo-kafka.svc.cluster.local \
    -p KERBEROS_KDC_PORT=2500 \
    -p KERBEROS_KEYTAB_SECRET="base64-kafka-keytab-secret" \
    -p KERBEROS_USE_TCP=true
```
then the principals to create would be:
```
kafka/kafka-instance-kafka-0.kafka-svc.kudo-kafka.svc.cluster.local@LOCAL
kafka/kafka-instance-kafka-1.kafka-svc.kudo-kafka.svc.cluster.local@LOCAL
kafka/kafka-instance-kafka-2.kafka-svc.kudo-kafka.svc.cluster.local@LOCAL
```

Use `KERBEROS_USE_TCP=true` parameter to use `TCP` protocol for KDC. By default it will try to use UDP. 
#### Place Service Keytab in Kubernetes Secret Store

The KUDO Kafka service uses a keytab containing all node principals (service keytab). After creating the principals above, generate the service keytab making sure to include all the node principals. This should be stored as a secret in the Kubernetes Secret Store using `base64` encoding.

```
kubectl create secret generic kdc --from-file=./kafka.keytab
```
:warning: The KUDO Kafka assume the key in the secret to be `kafka.keytab`

## Authorization

The KUDO Kafka service supports Kafka’s ACL-based authorization system.  To use Kafka’s ACLs, either TLS or Kerberos authentication must be enabled as detailed above.

### Enable Authorization

#### Prerequisites

* Completion of Kerberos authentication or TLS authentication as detailed above.

### Example with Kerberos

Install the KUDO Kafka service with the following options in addition to your own (remember, Kerberos must be enabled):

```
$ kubectl kudo install kafka \
  --instance=kafka-instance --namespace=kudo-kafka \
    -p ZOOKEEPER_URI=zk-zookeeper-0.zk-hs:2181,zk-zookeeper-1.zk-hs:2181,zk-zookeeper-2.zk-hs:2181 \
    -p BROKER_COUNT=3 \
    -p KERBEROS_ENABLED=true \
    -p KERBEROS_DEBUG=false \
    -p KERBEROS_PRIMARY=kafka\
    -p KERBEROS_REALM=LOCAL\
    -p KERBEROS_KEYTAB_SECRET="base64-kafka-keytab-secret"
    -p AUTHORIZATION_ENABLED=<true|false default false> \
    -p AUTHORIZATION_ALLOW_EVERYONE_IF_NO_ACL_FOUND=<true|false default false> \
    -p AUTHORIZATION_SUPER_USERS="User:User1"
```

The format of the list is `User:user1;User:user2;....` Using Kerberos authentication, the “user” value is the Kerberos primary. The Kafka brokers themselves are automatically designated as super users.

### Example with TLS

Install the KUDO Kafka service with the following options in addition to your own (remember, TLS authentication must be enabled):

```
$ kubectl kudo install kafka \
  --instance=kafka-instance --namespace=kudo-kafka \
    -p ZOOKEEPER_URI=zk-zookeeper-0.zk-hs:2181,zk-zookeeper-1.zk-hs:2181,zk-zookeeper-2.zk-hs:2181 \
    -p BROKER_CPUS=200m \
    -p BROKER_COUNT=3 \
    -p BROKER_MEM=800m \
    -p DISK_SIZE=10Gi \
    -p AUTHORIZATION_ENABLED=true \
    -p AUTHORIZATION_ALLOW_EVERYONE_IF_NO_ACL_FOUND=false \
    -p AUTHORIZATION_SUPER_USERS="User:User1" \
    -p TRANSPORT_ENCRYPTION_ENABLED=true \
    -p TRANSPORT_ENCRYPTION_ALLOW_PLAINTEXT=false \
    -p SSL_AUTHENTICATION_ENABLED=true
```

NOTE: It is possible to enable Authorization after initial installation but the service may become unavailable during the transition. Additionally, Kafka clients may fail to function if they do not have the correct ACLs assigned to their principals. During the transition `AUTHORIZATION_ALLOW_EVERYONE_IF_NO_ACL_FOUND` can be set to `true` to prevent clients from failing until their ACLs can be set correctly. After the transition, `AUTHORIZATION_ALLOW_EVERYONE_IF_NO_ACL_FOUND` should be reset back to `false`.