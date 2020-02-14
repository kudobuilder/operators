# Security
---

### Securing Spark RPC communication

Spark supports authentication for RPC channels (protocol between Spark processes), which allows secure 
communication between driver and executors and also adds a possibility to enable network encryption between Spark processes.
For more information refer to the [official Spark documentation](https://spark.apache.org/docs/latest/security.html#encryption).

#### Authentication and encryption

In order to enable RPC authentication:
* set `spark.authenticate` configuration property to `true` 
* mount `SPARK_AUTHENTICATE_SECRET` environment variable from a secret for both the Driver and Executors

To enable encryption for RPC connections, set `spark.network.crypto.enabled` configuration property to `true`.
Spark authentication must be enabled for encryption to work.
Additional configuration properties can be found in Spark documentation.

The example below describes how to set up authentication and encryption for `SparkApplication` on Kubernetes.
 
1) Create a authentication secret, which will be securely mounted to a driver and executor pods.
```bash
$ kubectl create secret generic spark-secret --from-literal secret=my-secret
```
2) Set log level to `DEBUG` as described in [Configuring Logging](submission.md#configuring-logging) section of the documentation.
3) Apply the following `SparkApplication` specification with `kubectl apply -f <application_spec.yaml>` command.

Note: If you are using the block transfer service, you might want to enable "spark.authenticate.enableSaslEncryption" 
property to enable SASL encryption for Spark RPCs.

```yaml
apiVersion: "sparkoperator.k8s.io/v1beta2"
kind: SparkApplication
metadata:
  name: spark-rpc-auth-enctryption-app
  namespace: <namespace>
spec:
  type: Scala
  mode: cluster
  image: "mesosphere/spark:2.4.4-hadoop-2.9-k8s"
  imagePullPolicy: Always
  mainClass: MockTaskRunner
  mainApplicationFile: "https://infinity-artifacts.s3.amazonaws.com/scale-tests/dcos-spark-scala-tests-assembly-2.4.0-20190325.jar"
  arguments:
    - "1"
    - "600"
  sparkConf:
    "spark.scheduler.maxRegisteredResourcesWaitingTime": "2400s"
    "spark.scheduler.minRegisteredResourcesRatio": "1.0"
    "spark.authenticate": "true"
    "spark.network.crypto.enabled": "true"
    "spark.kubernetes.driver.secretKeyRef.SPARK_AUTHENTICATE_SECRET": "spark-secret:secret"
    "spark.kubernetes.executor.secretKeyRef.SPARK_AUTHENTICATE_SECRET": "spark-secret:secret"
  sparkVersion: 2.4.4
  sparkConfigMap: spark-conf-map
  restartPolicy:
    type: Never
  driver:
    cores: 1
    memory: "512m"
    labels:
      version: 2.4.4
    serviceAccount: <service-account>
  executor:
    cores: 1
    instances: 1
    memory: "512m"
    labels:
      version: 2.4.4
    javaOptions: "-Dlog4j.configuration=file:/etc/spark/conf/log4j.properties"
```

This will create a test job, which emulates a long-running task. 
Authentication secrets will be injected into Spark pods via `SPARK_AUTHENTICATE_SECRET` environment variable.

4) Check logs of the running pods:
```bash
$ kubectl logs spark-rpc-auth-enctryption-app-driver -f
``` 
5) The logs should contain auth-related messages similar to the ones in snippets below:
```
(driver logs):
...
20/02/07 16:13:09 DEBUG TransportServer: New connection accepted for remote address /10.244.0.104:46512.
20/02/07 16:13:09 DEBUG AuthRpcHandler: Received new auth challenge for client /10.244.0.104:46512.
20/02/07 16:13:09 DEBUG AuthRpcHandler: Authenticating challenge for app sparkSaslUser.
20/02/07 16:13:10 DEBUG AuthEngine: Generated key with 1024 iterations in 27735 us.
20/02/07 16:13:10 DEBUG AuthEngine: Generated key with 1024 iterations in 8148 us.
20/02/07 16:13:10 DEBUG AuthRpcHandler: Authorization successful for client /10.244.0.104:46512.
...
```
```
(executor logs):
...
20/02/07 16:13:07 DEBUG TransportClientFactory: Creating new connection to spark-rpc-auth-enctryption-app-1581091973687-driver-svc.default.svc/10.244.0.103:7078
20/02/07 16:13:07 DEBUG TransportClientFactory: Connection to spark-rpc-auth-enctryption-app-1581091973687-driver-svc.default.svc/10.244.0.103:7078 successful, running bootstraps...
20/02/07 16:13:07 DEBUG AuthEngine: Generated key with 1024 iterations in 4715 us.
20/02/07 16:13:08 INFO TransportClientFactory: Successfully created connection to spark-rpc-auth-enctryption-app-1581091973687-driver-svc.default.svc/10.244.0.103:7078 after 115 ms (110 ms spent in bootstraps)
20/02/07 16:13:08 INFO CoarseGrainedExecutorBackend: Connecting to driver: spark://CoarseGrainedScheduler@spark-rpc-auth-enctryption-app-1581091973687-driver-svc.default.svc:7078
20/02/07 16:13:08 INFO CoarseGrainedExecutorBackend: Successfully registered with driver
...
```
6) Verify the network encryption:

- Attach to the driver pod:

```bash
$ kubectl exec -it spark-rpc-auth-enctryption-app-driver bash
```
- Use `ngrep` tool to monitor the traffic on `7078` port: 
```bash
$ ngrep port 7078
```
```
interface: eth0 (10.244.0.0/255.255.255.0)
filter: ( port 7078 ) and ((ip || ip6) || (vlan && (ip || ip6)))
#
T 10.244.0.104:46480 -> 10.244.0.103:7078 [AP] #1
  uVx....."....Qn.0....z|.4-..N.+.(E.yU..;.....5.V..e..t_L.....T....9....Zcj/A..;...7.S.....X.7.7+..Nd..x...1.Qg0D.d...vV...P V....7....\._lgi...*.#]..i..8.\...+Tu/.H.Wx*..=o.....I.K.,.....g...@:...8.;...Q...
  .$.D..&...P.@R...I.s.M..`.oAn'.I...g.p..=....$............b.....O.|..v..:X..!H.Fot.....r83.....-Y..,X..W.......PC.....

```

### TLS configuration

Spark allows to configure TLS for Spark web endpoints, such as Spark UI and Spark History Server UI.
To get more information about SSL configuration in Spark, refer to the [Spark documentation](https://spark.apache.org/docs/latest/security.html#ssl-configuration).

Here are the steps required to configure TLS for `SparkApplication`:

**Note:** keystores must be provided in order to proceed with TLS setup. Keystores can be generated
using [keytool](https://docs.oracle.com/javase/10/tools/keytool.htm) program.

1) Create a `Secret` containing all the sensitive data (passwords and key-stores): 
```bash
$ kubectl create secret generic ssl-secrets \
--from-file keystore.jks \
--from-file truststore.jks \
--from-literal key-password=<password for the private key> \
--from-literal keystore-password=<password for the keystore> \
--from-literal truststore-password=<password for the truststore>
```

2) In `SparkApplication`, specify `spark.ssl.*` configuration properties via `sparkConf` and mount the secret 
created in the previous step using `spark.kubernetes.*` properties. `keystore.jks` and `truststore.jks` will be mounted 
to `/tmp/spark/ssl` directory and the passwords will be passed to the driver pod via predefined environment variables.   

```yaml
apiVersion: "sparkoperator.k8s.io/v1beta2"
kind: SparkApplication
metadata: 
  name: <app-name>
  namespace: <namespace>
spec:
  ...
  image: "mesosphere/spark:2.4.4-hadoop-2.9-k8s"
  sparkConf:
    "spark.ssl.enabled":    "true",
    "spark.ssl.keyStore":   "/tmp/spark/ssl/keystore.jks",
    "spark.ssl.protocol":   "TLSv1.2",
    "spark.ssl.trustStore": "/tmp/spark/ssl/truststore.jks",
    "spark.kubernetes.driver.secretKeyRef.SPARK_SSL_KEYPASSWORD":        "ssl-secrets:key-password",
    "spark.kubernetes.driver.secretKeyRef.SPARK_SSL_KEYSTOREPASSWORD":   "ssl-secrets:keystore-password",
    "spark.kubernetes.driver.secretKeyRef.SPARK_SSL_TRUSTSTOREPASSWORD": "ssl-secrets:truststore-password"
    "spark.kubernetes.driver.secrets.ssl-secrets": "/tmp/spark/ssl"
  ...
```

3) Forward a local port to a Spark UI (driver) port (default port for SSL connections is 4440):
```bash
$ kubectl port-forward  <driver-pod-name> 4440
```
4) Spark UI should now be available via [https://localhost:4440](https://localhost:4440/).
