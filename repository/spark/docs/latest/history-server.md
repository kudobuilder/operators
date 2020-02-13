# Spark History Server Configuration

## Prerequisites

Required software:
* K8s cluster
* [KUDO CLI Plugin](https://kudo.dev/docs/#install-kudo-cli) 0.10.1 or higher

## Installing Spark Operator with History Server Enabled

```bash
kubectl kudo install spark --instance=spark-operator \
    -p enableHistoryServer=true \
    -p historyServerFsLogDirectory="<log directory>" \
```
This will deploy a Pod and Service for the `Spark History Server` with the `Spark Event Log` directory configured via the `historyServerFsLogDirectory` parameter. Spark Operator also supports Persistent Volume Claim (PVC) based storage. There is a parameter `historyServerPVCName` to pass the name of the PVC. Make sure that provided PVC should have `ReadWriteMany` [access mode](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#access-modes) supported.

To configure S3 for event log storage it is recommended to store AWS security credentials in a `Secret` in the following way:
1) Create a `Secret` which will contain Spark configuration (file name is important):
```bash
$ cat << 'EOF' >> spark-defaults.conf
spark.hadoop.fs.s3a.access.key <AWS_ACCESS_KEY_ID>
spark.hadoop.fs.s3a.secret.key <AWS_SECRET_ACCESS_KEY>
spark.hadoop.fs.s3a.impl org.apache.hadoop.fs.s3a.S3AFileSystem
EOF
$ kubectl create secret generic spark-conf --from-file spark-defaults.conf --namespace spark
```

2) Install Spark Operator with the following parameters:
```bash
kubectl kudo install spark --instance=spark-operator \
    -p enableHistoryServer=true \
    -p historyServerFsLogDirectory="s3a://<BUCKET_NAME>/<FOLDER>" \
    -p historyServerSparkConfSecret=spark-conf
```

## Creating Spark Application

When Spark History server is enabled, an additional configuration such as security credentials can be required for 
accessing the storage backend being used for event logging. 
The following steps are required for configuring Spark Application event log storage in S3:

1) Create a `Secret` with AWS credentials as described in [Integration with AWS S3](configuration.md#integration-with-aws-s3) Operator documentation.
2) Create a `SparkApplication` configuration with AWS credentials environment variables populated from a `Secret` created at the previous step. Here's an example:
```yaml
apiVersion: "sparkoperator.k8s.io/v1beta2"
kind: SparkApplication
metadata:
  name: spark-app
spec:
  ...
  sparkConf:
    "spark.eventLog.enabled": "true"
    "spark.eventLog.dir": "s3a://<BUCKET_NAME>/<FOLDER>"
    "spark.hadoop.fs.s3a.impl": "org.apache.hadoop.fs.s3a.S3AFileSystem"
  ...
  driver:
    env:
      - name: AWS_ACCESS_KEY_ID
        valueFrom:
          secretKeyRef:
            name: <Name of a Secret with AWS credentials >
            key: AWS_ACCESS_KEY_ID
      - name: AWS_SECRET_ACCESS_KEY
        valueFrom:
          secretKeyRef:
            name: <Name of a Secret with AWS credentials>
            key: AWS_SECRET_ACCESS_KEY
      # in case when Temporary Security Credentials are used
      - name: AWS_SESSION_TOKEN
        valueFrom:
          secretKeyRef:
            name: <Name of a Secret with AWS credentials>
            key: AWS_SESSION_TOKEN
            optional: true
```

If PVC is passed while installing the Spark Operator, make sure these two fields are also added with following values:

```yaml
# Add this under SparkApplicationSpec
volumes:
- name: pvc-storage
  persistentVolumeClaim:
    claimName: <HISTORY_SERVER_PVC_NAME>

# Add this under SparkPodSpec
volumeMounts:
- mountPath: <HISTORY_SERVER_FS_LOG_DIRECTORY>
  name: pvc-storage
```

Make sure that CRD and RBAC for SparkApplication are already created. Now we can run the application as follows:

```bash
kubectl apply -n <NAMESPACE> -f specs/spark-application.yaml
```

## Accessing Spark History Server UI

### Using Port-Forwarding:

You can run this command to expose the UI in your local machine.

```bash
kubectl port-forward <HISTORY_SERVER_POD_NAME> 18080:18080
```

Verify local access using this:

```bash
curl -L localhost:18080
```

### Using LoadBalancer:

Create a Service with type as `LoadBalancer` which will expose the Spark History Server UI. Service specification will be as follows:

```yaml
apiVersion: v1
kind: Service
metadata:
  labels:
    app: history-server-ui-lb
  name: history-server-ui-lb
spec:
  type: LoadBalancer
  selector:
    app.kubernetes.io/name: history-server
  ports:
  - protocol: TCP
    port: 80
    targetPort: 18080
```

Create service with following command:

```bash
kubectl create -f history-server-svc.yaml -n spark
```

Wait for few minutes and verify the access to Spark History Server UI via external address as follows:

```bash
curl -L http://$(kubectl get svc history-server-ui-lb -n spark --output jsonpath='{.status.loadBalancer.ingress[*].hostname}')
```

## List of available parameters for Spark History Server

| Parameter Name               | Default Value |  Description                                                                                                              |
| --------------               | ------------- |  -----------                                                                                                              |
| enableHistoryServer          | false         | Enable Spark History Server                                                                                               |
| historyServerFsLogDirectory  | ""            | Spark EventLog Directory from which to load events for prior Spark job runs (e.g., hdfs://hdfs/ or s3a://path/to/bucket). |
| historyServerCleanerEnabled  | false         | Specifies whether the Spark History Server should periodically clean up event logs from storage.                          |
| historyServerCleanerInterval | 1d            | Frequency the Spark History Server checks for files to delete.                                                            |
| historyServerCleanerMaxAge   | 7d            | History files older than this will be deleted.                                                                            |
| historyServerOpts            | ""            | Extra options to pass to the Spark History Server                                                                         |
| historyServerPVCName         | ""            | External Persistent Volume Claim Name used for Spark event logs storage                                                   |

Note: Values passed as parameters will get priority over values passed as options in the parameter `historyServerOpts`.
