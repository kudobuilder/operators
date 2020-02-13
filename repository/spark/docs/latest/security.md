# Security
---

### Securing Spark RPC communication

Spark supports authentication for RPC channels (protocol between Spark processes), which allows secure 
communication between driver and executors and also adds a possibility to enable network encryption between Spark processes.
For more information refer to the [official Spark documentation](https://spark.apache.org/docs/latest/security.html#encryption).

#### Authentication and encryption
To enable authentication for RPC, the following configuration is required:
```
# enable authentication for internal connections
spark.authenticate  true  

# the secret key, used for authentication. Must be configured on each of the nodes.          
spark.authenticate.secret  spark-secret
```
To enable encryption for RPC connections, `spark.network.crypto.enabled` configuration property should be set to `true`.
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
    "spark.executorEnv.JAVA_TOOL_OPTIONS": >-
      -Dspark.authenticate=true
      -Dspark.network.crypto.enabled=true
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
    env:
      - name: SPARK_AUTHENTICATE_SECRET
        valueFrom:
          secretKeyRef:
            key: secret
            name: spark-secret
  executor:
    cores: 1
    instances: 1
    memory: "512m"
    labels:
      version: 2.4.4
    env:
      - name: _SPARK_AUTH_SECRET
        valueFrom:
          secretKeyRef:
            key: secret
            name: spark-secret
    javaOptions: "-Dlog4j.configuration=file:/etc/spark/conf/log4j.properties"
```

This will create a test job, which emulates a long-running task. 
Secrets are injected into Spark pods via specific environment variables: `SPARK_AUTHENTICATE_SECRET` and `_SPARK_AUTH_SECRET` 
for driver and executor, respectively.

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
20/02/07 16:13:08 DEBUG AuthEngine: Generated key with 1024 iterations in 2144 us.
20/02/07 16:13:08 INFO TransportClientFactory: Successfully created connection to spark-rpc-auth-enctryption-app-1581091973687-driver-svc.default.svc/10.244.0.103:7078 after 115 ms (110 ms spent in bootstraps)
20/02/07 16:13:08 INFO DiskBlockManager: Created local directory at /var/data/spark-bf7a16fc-7b43-41e2-a76f-bf9ea101afc1/blockmgr-20a055fa-ac87-4eaa-a101-e1174f642e69
20/02/07 16:13:08 DEBUG DiskBlockManager: Adding shutdown hook
20/02/07 16:13:08 DEBUG ShutdownHookManager: Adding shutdown hook
20/02/07 16:13:08 INFO MemoryStore: MemoryStore started with capacity 117.0 MB
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
  .$.D..&...P.@R...I.s.M..`.oAn'.I...g.p..=....$............b.....O.|..v..:X..!H.Fot.....r83.....-Y..,X..W.......PC..................._O.s..B2..PG...04.*..A..}.....\..6xM..G8.E......Re2.|m.W... Lt..).X..~....
  X..$)...M......b.G. j...B..tY7.b!.#y....\.5.'.e:C{.7 ..(0..4..|.d8fy\dj.M..IWt,...m..._..\q..!.Q.&.e.g...%j....#p..D.m..1.C.yS..........$."..A.........GS.Nn.2Vg....m."F.x8...,....1.l.......KG:...(G.#y.\.6..
  @w....x..1za...N.;Ae..6.B.s....$....^or..).q)../...l......I.......~s..>...a .......K.O..%....?.s.=F.].L.b...o........|..{.A..y.....g..C..ypX}SZ....hD.$....?..........U...2P.=B.h.}Zg...Q...J...*Oeq.ge ..3T..
  ..i.......S.K..r....c$..ZZ...O..(..zt.t...-Q.S.wT...".....z.5..f.k.....J.A;...z......`.K..NH].....r....^....q.5........#...+..1..+;dbb...;..?A.%.B...9K....C^.-6@..ym6.2e..B...K..1..f3..T....0Y~.R.H....P....
  sL.........KR..x.f=..B...."k.H.i>+fa8$.t..R.A.....^../u.T....>.e@..X.......R.....d..{.l.....]*.c..Pg.r%.,.../=_..j..f...U&..\.."........ZI>..<-E....<.o.[Q..D..5......?.u.-zB.-E.X......t..l.I...H..H........U
  . h3...R....I...O>........?t+."..@g7......P......<._.'....Gp.6c...%..J!.{.vT.*.2..{0..B......;..`.L=.......;..H.c;.d..R*0...]Q%.....N...l....a.n...].M.G.g.L..R.`N/uw..g...y.....Za..S\..dI...l.O...@.......oe
  Z...WFR....x,$;DP.rKp...~....f..a.:"....r'U..........`/..b.... p....O.....y&`...`....R. ..R.......s.8.Q..{......TZZ...Z......,C5..._X..^O...."....\..X...rq.;.E.3.>,.4.i..s.....a8./S.........lQ.+..d.u.......
  ....?..Y4"U....2^.q...F.r...+.u...m.Y......DF>=J......w.M.4....O3..G.@...sa$).F.Q,0}w.Jk...u ..L(OYY|.v..I.n.4.l....@.7.........,.S..A........ .^...L}......%.Et\eq,.....).....a... .j...X....q.O^... .C...;ub
  ..F...n'p.<.y.?..c|7...$sg...w....~h..@p.#a..>\rx......R......TJc.....a.yXr..j.d.oJ.eIT.8.&.,....6......:.(K.07B..#CI}..,.:.t......F..j.2..`[D.73... .w.M......V...f..2.b....G.5%.....;.....P.9..}....?61:....
  .e..C............+..(..Rc9...V...D#R.k....D.%....5."...DT........LdkI.....b8..k....h.].T.}EL...M.|e...K....9..E.mfR.0.....-..2..5.....pFN..o....}.U%:..oG_4...D.e.U.us...&...g.Q...U.?..~h..(V...-.g.....R....
  .xOe.?..V.!....8s.........H.L..6_`..*j.n..5.y.$cv.[ 6K..F....D0.e....+..:v.*....."......k"..R.E.Ha;......1...GS.j.Cl].Hm.q..l...x)`.d.{....-#.A.7...1...J.p.,....Tik.U$-..Y..O.*.MK.......:.R...5..)..{EK..r..
  ..3..L.T.,>#...g.$..P...@..y.-.&.f.<7...:i..M.....)....S..y...z....vm ..R....S..<..........g{......B&.......]-..m                                                                                             
##
T 10.244.0.103:7078 -> 10.244.0.104:46480 [AP] #3
  ..<-.I2.p...I.B?e..`>.1..?5...&j.<......q...2o..r}.9.h.3.....V.G@TUI...Oty....b.'......e:...O.L.YK....                                                                                                        
##
```

### TLS configuration

Spark allows to configure TLS for Spark web endpoints, such as Spark UI and Spark History Server UI.
To get more information about SSL configuration in Spark , refer to the [Spark documentation](https://spark.apache.org/docs/latest/security.html#ssl-configuration).

Here are the steps required to configure TLS for `SparkApplication`:

1) Create a `Secret` containing all the sensitive data (passwords and key-stores):
```bash
$ kubectl create secret generic ssl-secrets \
--from-file keystore.jks \
--from-file truststore.jks \
--from-literal key-password=<password for the private key > \
--from-literal keystore-password=<password for the keystore> \
--from-literal truststore-password=<password for the truststore>
```

2) In `SparkApplication`, specify `spark.ssl.*` configuration properties via `sparkConf` and mount the secret 
created in the previous step using `secrets` and `env` sections. `keystore.jks` and `truststore.jks` will be placed 
to `secrets.path` directory and the passwords will be passed to the driver pod via predefined environment variables.   

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
  driver:
    ...
    secrets:
      - name: ssl-secrets
        path: "/tmp/spark/ssl"
        secretType: Generic
    env:
      - name: SPARK_SSL_KEYPASSWORD
        valueFrom:
          secretKeyRef:
            key: key-password
            name: ssl-secrets
      - name: SPARK_SSL_KEYSTOREPASSWORD
        valueFrom:
          secretKeyRef:
            key: keystore-password
            name: ssl-secrets
      - name: SPARK_SSL_TRUSTSTOREPASSWORD
        valueFrom:
          secretKeyRef:
            key: truststore-password
            name: ssl-secrets
```

3) Forward a local port to a Spark UI (driver) port (default port for SSL connections is 4440):
```bash
$ kubectl port-forward  <driver-pod-name> 4440
```
4) Spark UI should now be available via [https://localhost:4440](https://localhost:4440/).
