Security
---

### Securing Spark RPC communication

Spark supports authentication for RPC channels (protocol between Spark processes), which allows secure 
communication between driver and executors and also adds a possibility to enable network encryption between Spark processes.
For more information refer to the official Spark documentation: [official Spark documentation](https://spark.apache.org/docs/latest/security.html#encryption)

#### Authentication and encryption
To enable authentication for RPC, the following configuration is required:
```
# enable authentication for internal connections
spark.authenticate  true  

# the secred key, used for authentication. Must be configured on each of the nodes.          
spark.authenticate.secret  spark-secret
```
If you want to setup the encryption for RPC connections, you can enable it by setting `spark.network.crypto.enabled` to `true`.
Spark authentication must be enabled for encryption to work.
Additional configuration properties can be found in Spark documentation.

The example below describes how to setup authentication and encryption for `SparkApplication` on Kubernetes.
Also, it shows how to provide a custom `log4j.properties` to change logging strategy.
 
1) Create a authentication secret, which will be securely mounted to a driver and executor pods.
```bash
$ kubectl create secret generic spark-secret --from-literal secret=my-secret
```
2) Create a `ConfigMap` with `log4j.properties`:
```bash
$ cat <<'EOF'>> log4j.properties2
log4j.rootCategory=DEBUG, console
log4j.appender.console=org.apache.log4j.ConsoleAppender
log4j.appender.console.target=System.err
log4j.appender.console.layout=org.apache.log4j.PatternLayout
log4j.appender.console.layout.ConversionPattern=%d{yy/MM/dd HH:mm:ss} %p %c{1}: %m%n    
EOF
```
```bash
$ kubectl create configmap spark-conf-map --from-file log4j.properties
```
The following file will be mounted to `/etc/spark/conf` and `SPARK_CONF_DIR` will be set to this directory.

3) Submit the following `SparkApplication` specification to Spark Operator with `kubectl apply -f <application_spec.yaml>`

Note: If you are using the block transfer service, you might want to enable "spark.authenticate.enableSaslEncryption" 
property to enable SASL encryption for Spark RPCs.

```yaml
apiVersion: "sparkoperator.k8s.io/v1beta2"
kind: SparkApplication
metadata:
  name: spark-rpc-auth-enctryption-app
  namespace: < Namespace >
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

This will create a test job which emulates a long-running task. 
Secrets are injected to Spark pods via specific environment variables, `SPARK_AUTHENTICATE_SECRET` and `_SPARK_AUTH_SECRET` 
for driver and executor, respectively.

4) Observe the logs for a driver and an executor pods:
```bash
$ kubectl logs spark-rpc-auth-enctryption-app-driver -f
``` 
5) You should see the records similar to the snippets below:
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

- Connect to the driver pod:

```bash
$ kubectl exec -it spark-rpc-auth-enctryption-app-driver bash
```
- Observe the traffic running on 7078 port is encrypted using `ngrep` tool:
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
