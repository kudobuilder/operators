# Security

## Authentication

KUDO Kafka currently supports Kerberos authentication.

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
<service primary>/kafka-kafka-<broker index>.kafka-svc.<namespace>.svc.cluster.local@<service realm>
```
with:
* ```service primary = KERBEROS_PRIMARY```
* ```broker index = 0 up to BROKER_COUNT - 1```
* ```namespace = kubernetes namespace```
* ```service realm = KERBEROS_REALM```

For example, if installing with these options:
```
kubectl kudo install kafka \
  --instance=kafka --namespace=kudo-kafka \
    -p ZOOKEEPER_URI=zk-zookeeper-0.zk-hs:2181,zk-zookeeper-1.zk-hs:2181,zk-zookeeper-2.zk-hs:2181 \
    -p KERBEROS_ENABLED=true \
    -p KERBEROS_DEBUG=false\
    -p KERBEROS_PRIMARY=kafka\
    -p KERBEROS_REALM=LOCAL\
    -p KERBEROS_KDC_HOSTNAME=kdc-service.kudo-kafka.svc.cluster.local \
    -p KERBEROS_KDC_PORT=2500 \
    -p KERBEROS_KEYTAB_SECRET="base64-kafka-keytab-secret"
```
then the principals to create would be:
```
kafka/kafka-kafka-0.kafka-svc.kudo-kafka.svc.cluster.local@LOCAL
kafka/kafka-kafka-1.kafka-svc.kudo-kafka.svc.cluster.local@LOCAL
kafka/kafka-kafka-2.kafka-svc.kudo-kafka.svc.cluster.local@LOCAL
```
#### Place Service Keytab in Kubernetes Secret Store

The KUDO Kafka service uses a keytab containing all node principals (service keytab). After creating the principals above, generate the service keytab making sure to include all the node principals. This should be stored as a secret in the Kubernetes Secret Store using `base64` encoding.

## Authorization

The KUDO Kafka service supports Kafka’s ACL-based authorization system. To use Kafka’s ACLs, Kerberos authentication must be enabled as detailed above.

### Enable Authorization

#### Prerequisites

* Completion of Kerberos authentication above.

### Install the Service

Install the KUDO Kafka service with the following options in addition to your own (remember, Kerberos must be enabled):

```
kubectl kudo install kafka \
  --instance=kafka --namespace=kudo-kafka \
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

The format of the list is User:user1;User:user2;.... Using Kerberos authentication, the “user” value is the Kerberos primary. The Kafka brokers themselves are automatically designated as super users.

>NOTE: It is possible to enable Authorization after initial installation, but the service may be unavailable during the transition. Additionally, Kafka clients may fail to function if they do not have the correct ACLs assigned to their principals. During the transition `AUTHORIZATION_ALLOW_EVERYONE_IF_NO_ACL_FOUND` can be set to `true` to prevent clients from being failing until their ACLs can be set correctly. After the transition, `AUTHORIZATION_ALLOW_EVERYONE_IF_NO_ACL_FOUND` should be reversed to `false`
