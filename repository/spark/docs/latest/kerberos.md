# Kerberos

### Overview

Kerberos is an authentication system that allows Spark to retrieve and write data securely to a Kerberos-enabled HDFS
cluster. Spark versions 2.4.5 and before, do not support retrieval, distribution, and renewal of delegation tokens
(authentication credentials) on Kubernetes and require the delegation token to be provided via `Secret`. Starting from
version 3.0 Spark provides full support for Kerberos authentication and delegation token handling. Detailed
information about delegation token handling in Spark is available in the
[official documentation](https://github.com/apache/spark/blob/master/core/src/main/scala/org/apache/spark/deploy/security/README.md).

This section assumes you have previously set up a Kerberos-enabled HDFS cluster and have an access to it to execute CLI commands.

### Retrieving delegation tokens
To provide Spark Application and Spark History Server with a delegation token:

1) Retrieve a delegation token from HDFS cluster. This can be done using HDFS CLI, e.g.:
```bash
hdfs fetchdt --renewer hdfs /var/keytabs/hadoop.token
```
This command wil fetch delegation token and save it to file `/var/keytabs/hadoop.token`.

2) Create a file-based secret using the delegation token retrieved at the previous step:
```bash
kubectl create secret generic hadoop-token --from-file hadoop.token
```
**Note:** Spark Operator assumes the delegation token file name to be `hadoop.token`, so if token file has a different name,
it should be renamed to `hadoop.token`.

### Configuring access to a Kerberos-enabled HDFS cluster for Spark Applications

To provide Spark Application with access to Kerberos-enabled HDFS cluster, use the secret containing delegation token
named `hadoop.token`. To retrieve a delegation token and store it in a secret, check "Retrieving delegation tokens"
section of this document.

To provide Spark Application with Hadoop Delegation token, mount the secret with the token and set its type to
`HadoopDelegationToken` in corresponding spec sections in `SparkApplication` for both the Driver and Executors, e.g.:
```yaml
apiVersion: "sparkoperator.k8s.io/v1beta2"
kind: SparkApplication
metadata:
  name: <app-name>
  namespace: <namespace>
spec:
...
  hadoopConfigMap: hadoop-config
  driver:
    serviceAccount: spark-instance-spark-service-account
    secrets:
      - name: hadoop-token
        path: /mnt/secrets
        secretType: HadoopDelegationToken
  executor:
    secrets:
      - name: hadoop-token
        path: /mnt/secrets
        secretType: HadoopDelegationToken
```

Once specified, the delegation token from `hadoop-token` secret will be used to authenticate with Kerberos-enabled HDFS cluster.

**Note** To provide Hadoop configuration files such as `core-site.xml` and `hdfs-site.xml` use `hadoopConfigMap` field in
`SparkApplication` spec to specify the name of the ConfigMap containing them. The operator will mount the ConfigMap onto
path `/etc/hadoop/conf` and ets the environment variable `HADOOP_CONF_DIR` to point to it in both the Driver and Executors.

### Configuring Spark History Server to use a Kerberos-enabled HDFS cluster for storage

To provide Spark History Server with access to Kerberos-enabled HDFS cluster for storing Spark Applications historical data,
use the secret containing delegation token named `hadoop.token`. To retrieve a delegation token and store it in a secret,
check "Retrieving delegation tokens" section of this document.

1) To install Spark History Server with Kerberos enabled, install the Operator with the following parameters:
```bash
kubectl kudo install spark --namespace=<namespace> \
  -p enableHistoryServer=true \
  -p historyServerFsLogDirectory=hdfs://namenode.hdfs-kerberos.svc.cluster.local:9000/history \
  -p delegationTokenSecret=hadoop-token
```

Here, `delegationTokenSecret` parameter specifies the name of the secret containing delegation token, and
`historyServerFsLogDirectory` contains an HDFS path for storage in a Kerberos-enabled cluster.

2) To make Spark Application logs available in the History Server HDFS location, enable event log collection and specify
event log dir pointing to the History Server HDFS location. Hadoop delegation tokens must be provided to Spark Applications
to access to Kerberos-enabled HDFS cluster:
```yaml
apiVersion: "sparkoperator.k8s.io/v1beta2"
kind: SparkApplication
metadata:
  name: <app-name>
  namespace: <namespace>
spec:
...
  sparkConf:
    "spark.eventLog.enabled": "true"
    "spark.eventLog.dir": "hdfs://namenode.hdfs-kerberos.svc.cluster.local:9000/history"
  driver:
    serviceAccount: spark-instance-spark-service-account
    secrets:
      - name: hadoop-token
        path: /mnt/secrets
        secretType: HadoopDelegationToken
  executor:
    secrets:
      - name: hadoop-token
        path: /mnt/secrets
        secretType: HadoopDelegationToken
```
