# Securing KUDO Cassandra Operator instances

The KUDO Cassandra operator supports Cassandra’s native transport **encryption**
mechanism. The service provides automation and orchestration to simplify the use
of these important features. For more information on Apache Cassandra’s
security, read the
[security](https://docs.datastax.com/en/cassandra-oss/3.0/cassandra/configuration/secureTOC.html)
section of official Apache Cassandra documentation.

## Encryption

By default, KUDO Cassandra nodes use the plaintext protocol for its
[Node-to-node](https://docs.datastax.com/en/cassandra-oss/3.0/cassandra/configuration/secureSSLNodeToNode.html)
and
[Client-to-node](https://docs.datastax.com/en/cassandra-oss/3.0/cassandra/configuration/secureSSLClientToNode.html)
communication. It is recommended to enable the TLS encryption, to secure the
communication between nodes and client.

### Enabling TLS encryption

Create the TLS certificate to be used for Cassandra TLS encryptions

```bash
openssl req -x509 -newkey rsa:4096 -sha256 -nodes -keyout tls.key -out tls.crt -subj "/CN=CassandraCA" -days 365
```

Create a kubernetes TLS secret using the certificate created in previous step

```bash
kubectl create secret tls cassandra-tls -n kudo-cassandra --cert=tls.crt --key=tls.key
```

:warning: Make sure to create the certificate in the same namespace where the
KUDO Cassandra is being installed.

#### Enabling only Node-to-node communication

```bash
kubectl kudo install cassandra \
    --instance=cassandra \
    --namespace=kudo-cassandra \
    -p TRANSPORT_ENCRYPTION_ENABLED=true \
    -p TLS_SECRET_NAME=cassandra-tls
```

#### Enabling both Node-to-node and Client-to-node communication

```bash
kubectl kudo install cassandra \
    --instance=cassandra \
    --namespace=kudo-cassandra \
    -p TRANSPORT_ENCRYPTION_ENABLED=true \
    -p TRANSPORT_ENCRYPTION_CLIENT_ENABLED=true \
    -p TLS_SECRET_NAME=cassandra-tls
```

The operator also allows you to allow plaintext communication along with
encrypted traffic in Client-to-node communication.

```bash
kubectl kudo install cassandra \
    --instance=cassandra \
    --namespace=kudo-cassandra \
    -p TRANSPORT_ENCRYPTION_ENABLED=true \
    -p TRANSPORT_ENCRYPTION_CLIENT_ENABLED=true \
    -p TRANSPORT_ENCRYPTION_CLIENT_ALLOW_PLAINTEXT=true \
    -p TLS_SECRET_NAME=cassandra-tls
```

#### Enabling only for JMX communication

By default, KUDO Cassandra nodes only allow JMX connections from localhost. To
enable remote JMX with encryption set `JMX_LOCAL_ONLY` to `false`.

```bash
kubectl kudo install cassandra \
    --instance=cassandra \
    --namespace=kudo-cassandra \
    -p TLS_SECRET_NAME=cassandra-tls \
    -p JMX_LOCAL_ONLY=false
```

Check out the [parameters reference](./parameters.md) for a complete list of all
configurable settings available for KUDO Cassandra security.

## Authentication and Authorization

The KUDO Cassandra operator can be configured to authenticate and authorize
access to the Cassandra cluster. The `AUTHENTICATOR` parameter sets the
[authenticator](http://cassandra.apache.org/doc/3.11/operating/security.html#authentication),
the `AUTHORIZER` parameter sets the
[authorizer](http://cassandra.apache.org/doc/3.11/operating/security.html#authorization).

### Authentication credentials

Some functionality of the operator use `nodetool`, thus these calls need to be
authenticated as well. With enabled password authentication, create a
[secret](https://kubernetes.io/docs/concepts/configuration/secret/) that
contains the credentials of the user the operator should use and set the
`AUTHENTICATION_SECRET_NAME` parameter accordingly.

Here's an example of a secret that uses the default cassandra/cassandra
credentials:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: cassandra-credential
type: Opaque
data:
  username: Y2Fzc2FuZHJh
  password: Y2Fzc2FuZHJh
```

Reference this when installing the Cassandra operator with authentication.

```bash
kubectl kudo install cassandra \
    --instance=cassandra \
    --namespace=kudo-cassandra \
    -p AUTHENTICATOR=PasswordAuthenticator \
    -p AUTHENTICATION_SECRET_NAME=cassandra-credential
```
