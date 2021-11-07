# Backup & Restore KUDO Cassandra

This guide explains how to configure backup and restore for KUDO Cassandra.

## Pre-conditions

- AWS S3 bucket for storing backups
- AWS CLI for local checks (not required for the actual operator)
- A `cqlsh` binary should be in the path

## Steps

### Preparation

#### 1. Verify that the S3 bucket is accessible

```bash
aws s3 ls
```

This should return a list of buckets accessible with your current AWS
credentials

#### Setup environment variables

The examples below assume that the instance and namespace names are stored in
the following shell variables. With this assumptions met, you should be able to
copy-paste the commands easily and it prevents typos in reused values.

```text
INSTANCE_NAME=cassandra
NAMESPACE=backup-test
SECRET_NAME=aws-credentials
BACKUP_BUCKET_NAME=<my-aws-s3-bucket>
BACKUP_PREFIX=cluster1
BACKUP_NAME=Backup1
```

#### Create a secret with your AWS credentials

```bash
cat <<EOF > aws-credentials.yaml
kind: Secret
apiVersion: v1
metadata:
  name: ${SECRET_NAME}
  namespace: ${NAMESPACE}
stringData:
  access-key: <YOUR AWS ACCESS KEY>
  secret-key: <YOUR AWS SECRET KEY>
EOF
```

Replace the values for access-key and secret key with the actual values for your
AWS account.

If you are using temporary AWS credentials with a security token, the file
should look like this:

```bash
cat <<EOF > aws-credentials.yaml
kind: Secret
apiVersion: v1
metadata:
  name: ${SECRET_NAME}
  namespace: ${NAMESPACE}
stringData:
  access-key: <YOUR AWS ACCESS KEY>
  secret-key: <YOUR AWS SECRET ACCESS KEY>
  security-token: <YOUR AWS SECURITY TOKEN>
EOF
```

You can find these values by looking at `~/.aws/credentials`:

```bash
cat ~/.aws/credentials
```

Apply the secret to your Kubernets cluster:

```bash
kubectl apply --namespace $NAMESPACE -f aws-credentials.yaml
```

#### 1. Install KUDO Cassandra with backups enabled

To allow the backup plan to run, the cluster must be set up with a specific
configuration:

- `BACKUP_RESTORE_ENABLED` This enables the backup functionality in general
- `BACKUP_AWS_CREDENTIALS_SECRET` Allows the instances to access the AWS
  credentials without storing them in the operator itself
- `BACKUP_AWS_S3_BUCKET_NAME` Defines the AWS S3 bucket where the backup will be
  stored
- `BACKUP_PREFIX` Prepends a prefix to the backups in the S3 buckets and allows
  multiple KUDO Cassandra clusters to reside in the same bucket
- `EXTERNAL_NATIVE_TRANSPORT` Setting this to true is not required for the
  backup, but allows us to access the cluster with `cqlsh` from the local
  machine

```bash
kubectl kudo install cassandra \
        --instance $INSTANCE_NAME \
        --namespace $NAMESPACE \
        -p EXTERNAL_NATIVE_TRANSPORT=true \
        -p BACKUP_RESTORE_ENABLED=true \
        -p BACKUP_AWS_CREDENTIALS_SECRET=$SECRET_NAME \
        -p BACKUP_AWS_S3_BUCKET_NAME=$BACKUP_BUCKET_NAME \
        -p BACKUP_PREFIX=$BACKUP_PREFIX
```

### Verify the state of the KUDO Cassandra instance

```bash
kubectl kudo plan status --instance=$INSTANCE_NAME -n $NAMESPACE
```

In the output note if:

- the current `Operator-Version` matches your expectation, and
- deploy plan is `COMPLETE` (this may take a couple minutes)

Example output:

```text
Plan(s) for "cassandra" in namespace "default":
.
└── cassandra (Operator-Version: "cassandra-1.0.0" Active-Plan: "deploy")
    ├── Plan deploy (serial strategy) [COMPLETE]
    │   └── Phase nodes (parallel strategy) [COMPLETE]
    │       └── Step node [COMPLETE]
    ├── Plan upgrade (serial strategy) [NOT ACTIVE]
    │   ├── Phase cleanup (serial strategy) [NOT ACTIVE]
    │   │   └── Step cleanup-stateful-set [NOT ACTIVE]
    │   └── Phase reinstall (serial strategy) [NOT ACTIVE]
    │       └── Step node [NOT ACTIVE]
    └── Plan backup (serial strategy) [NOT ACTIVE]
        └── Phase backup (serial strategy) [NOT ACTIVE]
            ├── Step cleanup [NOT ACTIVE]
            └── Step backup [NOT ACTIVE]

```

Save the DNS of the external service of the cluster:

```bash
CASSANDRA_CLUSTER=`kubectl get service --namespace $NAMESPACE --field-selector metadata.name=$INSTANCE_NAME-svc-external -o jsonpath='{.items[*].status.loadBalancer.ingress[*].hostname}'`

echo "Cassandra Cluster DNS: $CASSANDRA_CLUSTER"
```

#### Write data to the cluster

```bash
cqlsh $CASSANDRA_CLUSTER <<EOF
CREATE SCHEMA schema1 WITH replication = { 'class' : 'SimpleStrategy', 'replication_factor' : 1 };
USE schema1;
CREATE TABLE users (user_id varchar PRIMARY KEY,first varchar,last varchar,age int);
INSERT INTO users (user_id, first, last, age) VALUES ('jsmith', 'John', 'Smith', 42);
EOF
```

### Verification

Verify that the data was written correctly:

```bash
cqlsh $CASSANDRA_CLUSTER -e "USE schema1; SELECT * FROM users;"
```

Expected output should show:

```text
 user_id | age | first | last
---------+-----+-------+-------
  jsmith |  42 |  John | Smith

(1 rows)
```

#### Create a backup

TODO: Use plan trigger in KUDO v0.11

The following command will trigger the creation of the backup with the name
"Backup1"

```bash
kubectl kudo update --instance=$INSTANCE_NAME -n $NAMESPACE -p BACKUP_NAME=$BACKUP_NAME -p BACKUP_TRIGGER=3
```

### Verify backup progress

First, get a list of running jobs:

```bash
kubectl get jobs --namespace=$NAMESPACE
```

This should produce a list of the started backup jobs, one for each active node:

```text
NAME            COMPLETIONS   DURATION   AGE
backup-node-0   1/1           25s        33s
backup-node-1   1/1           21s        33s
backup-node-2   1/1           23s        33s
```

Next, lets view a list of all the pods:

```bash
kubectl get pods --namespace=$NAMESPACE
```

This shows us the cassandra nodes and the temporary backup-pods, created by the
jobs:

```text
NAME                  READY   STATUS      RESTARTS   AGE
backup-node-0-bq228   0/1     Completed   0          83s
backup-node-1-fm7dq   0/1     Completed   0          83s
backup-node-2-tdzfm   0/1     Completed   0          83s
cassandra-node-0      3/3     Running     0          27m
cassandra-node-1      3/3     Running     0          27m
cassandra-node-2      3/3     Running     0          27m
```

The backup-pods will stay there when they are completed, but they will get
cleaned up before the next backup job starts.

Let's have a look at the logs at one of the backup pods:

```bash
FIRST_BACKUP_POD_NAME=`kubectl get pods --namespace=$NAMESPACE | awk '{ if(NR==2) print $1}'`
echo "Name of first backup pod is $FIRST_BACKUP_POD_NAME"
kubectl logs $FIRST_BACKUP_POD_NAME --namespace=$NAMESPACE
```

This should show the logs of the backup job:

```text
Starting medusa: python3 /usr/local/bin/medusa backup --backup-name Backup1
[2020-03-06 12:00:22,036] INFO: Monitoring provider is noop
[2020-03-06 12:00:23,605] WARNING: is ccm : 0
[2020-03-06 12:00:23,889] INFO: Creating snapshot
[2020-03-06 12:00:23,889] INFO: Saving tokenmap and schema
[2020-03-06 12:00:25,349] INFO: Node cassandra-node-0.cassandra-svc.backup-test.svc.cluster.local does not have latest backup
[2020-03-06 12:00:25,349] INFO: Starting backup
[2020-03-06 12:00:28,406] INFO: Uploading /var/lib/cassandra/data/system_auth/roles-5bc52802de2535edaeab188eecebb090/snapshots/medusa-58cc941f-7d94-4f65-8d51-0a253bafb147/md-1-big-TOC.txt (92.000B)
[2020-03-06 12:00:28,456] INFO: Uploading /var/lib/cassandra/data/system_auth/roles-5bc52802de2535edaeab188eecebb090/snapshots/medusa-58cc941f-7d94-4f65-8d51-0a253bafb147/md-1-big-Summary.db (71.000B)
[2020-03-06 12:00:28,472] INFO: Uploading /var/lib/cassandra/data/system_auth/roles-5bc52802de2535edaeab188eecebb090/snapshots/medusa-58cc941f-7d94-4f65-8d51-0a253bafb147/md-1-big-Data.db (102.000B)
...
[2020-03-06 12:00:37,783] INFO: Uploading /var/lib/cassandra/data/system/peers-37f71aca7dc2383ba70672528af04d4f/snapshots/medusa-58cc941f-7d94-4f65-8d51-0a253bafb147/md-1-big-Filter.db (16.000B)
[2020-03-06 12:00:37,804] INFO: Uploading /var/lib/cassandra/data/system/peers-37f71aca7dc2383ba70672528af04d4f/snapshots/medusa-58cc941f-7d94-4f65-8d51-0a253bafb147/md-2-big-Data.db (69.000B)
[2020-03-06 12:00:40,304] INFO: Updating backup index
[2020-03-06 12:00:41,352] INFO: Backup done
[2020-03-06 12:00:41,352] INFO: - Started: 2020-03-06 12:00:22
                        - Started extracting data: 2020-03-06 12:00:25
                        - Finished: 2020-03-06 12:00:41
[2020-03-06 12:00:41,352] INFO: - Real duration: 0:00:16.095052 (excludes time waiting for other nodes)
[2020-03-06 12:00:41,353] INFO: - 281 files, 291.20 KB
[2020-03-06 12:00:41,353] INFO: - 281 files copied from host
Done: 0
```

These files should now show up in the S3 bucket as well:

```bash
aws s3 ls $BACKUP_BUCKET_NAME/$BACKUP_PREFIX --recursive
```

```text
2020-03-06 13:00:25         12 cluster1/cassandra-node-0.cassandra-svc.backup-test.svc.cluster.local/Backup1/meta/differential
2020-03-06 13:00:41      65831 cluster1/cassandra-node-0.cassandra-svc.backup-test.svc.cluster.local/Backup1/meta/manifest.json
2020-03-06 13:00:24      35214 cluster1/cassandra-node-0.cassandra-svc.backup-test.svc.cluster.local/Backup1/meta/schema.cql
2020-03-06 13:00:25      16677 cluster1/cassandra-node-0.cassandra-svc.backup-test.svc.cluster.local/Backup1/meta/tokenmap.json
2020-03-06 13:00:29         43 cluster1/cassandra-node-0.cassandra-svc.backup-test.svc.cluster.local/data/schema1/users-edfe97c05fa111eab6374b40d92765b8/md-1-big-CompressionInfo.db
2020-03-06 13:00:29         50 cluster1/cassandra-node-0.cassandra-svc.backup-test.svc.cluster.local/data/schema1/users-edfe97c05fa111eab6374b40d92765b8/md-1-big-Data.db
...
2020-03-06 13:00:38          7 cluster1/index/latest_backup/cassandra-node-1.cassandra-svc.backup-test.svc.cluster.local/backup_name.txt
2020-03-06 13:00:38      16677 cluster1/index/latest_backup/cassandra-node-1.cassandra-svc.backup-test.svc.cluster.local/tokenmap.json
2020-03-06 13:00:39          7 cluster1/index/latest_backup/cassandra-node-2.cassandra-svc.backup-test.svc.cluster.local/backup_name.txt
2020-03-06 13:00:39      16677 cluster1/index/latest_backup/cassandra-node-2.cassandra-svc.backup-test.svc.cluster.local/tokenmap.json
```

#### Restore the backup into a new cluster

KUDO Cassandra currently only supports a full restore into a new cluster.

### Remove the old KUDO Cassandra instance (optional)

This step is not required, but may help if your cluster does not have enough
resources to run two Cassandra clusters at the same time.

```bash
kubectl kudo uninstall --instance $INSTANCE_NAME --namespace $NAMESPACE
```

You may have noticed that the uninstall of the operator does not delete the
persistent volume claims:

```bash
kubectl get pvc --namespace $NAMESPACE
```

```text
NAME                                 STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS           AGE
var-lib-cassandra-cassandra-node-0   Bound    pvc-f4048fa7-23da-4410-b7b0-b7c82729fc7d   20Gi       RWO            awsebscsiprovisioner   64m
var-lib-cassandra-cassandra-node-1   Bound    pvc-2c85752f-6438-4c8d-8e87-9f4c91df6452   20Gi       RWO            awsebscsiprovisioner   64m
var-lib-cassandra-cassandra-node-2   Bound    pvc-56123519-50c8-4ef7-83ab-302655101497   20Gi       RWO            awsebscsiprovisioner   64m
```

This is intentional, so that in case of an accidental deletion of the KUDO
operator the data can still be accessed. In this case we don't need them, so to
make sure to delete them before reinstalling the cluster with the S3 backup:

```bash
kubectl delete pvc --all --namespace $NAMESPACE
```

```text
persistentvolumeclaim "var-lib-cassandra-cassandra-node-0" deleted
persistentvolumeclaim "var-lib-cassandra-cassandra-node-1" deleted
persistentvolumeclaim "var-lib-cassandra-cassandra-node-2" deleted
```

Now we have a clean namespace and can start the restore process

### Install KUDO Cassandra with an existing backup

To create a full restore, the operator needs to create a new cluster.

_Important_: At the moment, only a restore with the very same settings are
supported, this is especially true for:

- NODE_COUNT: A different node count will fail to create a successful restore.
- NUM_TOKENS: This setting will be ignored on the restored cluster, as it will
  take over the tokens from the backup

Namespace and instance name can differ, but the namespace and instance name from
the backed up cluster is important.

Additional to the backup parameters used in the installation for the first
cluster, these new parameters are used:

- RESTORE_FLAG: If true, an initContainer is created that restores a backup
  before the cluster is started
- RESTORE_OLD_NAMESPACE: The Namespace of the cluster that was backed up
- RESTORE_OLD_NAME: The instance name of the cluster that was backed up. Both
  parameters need to be set so the operator can identify the correct data to
  restore
- BACKUP_NAME: The name of the backup to restore

```bash
kubectl kudo install cassandra \
        --instance $INSTANCE_NAME \
        --namespace $NAMESPACE \
        -p EXTERNAL_NATIVE_TRANSPORT=true \
        -p BACKUP_RESTORE_ENABLED=true \
        -p BACKUP_AWS_CREDENTIALS_SECRET=$SECRET_NAME \
        -p BACKUP_AWS_S3_BUCKET_NAME=$BACKUP_BUCKET_NAME \
        -p BACKUP_PREFIX=$BACKUP_PREFIX \
        -p RESTORE_FLAG=true \
        -p RESTORE_OLD_NAMESPACE=$NAMESPACE \
        -p RESTORE_OLD_NAME=$INSTANCE_NAME \
        -p BACKUP_NAME=$BACKUP_NAME
```

Again, we should check if the plan is executed correctly and no ERRORS show up:

```bash
kubectl kudo plan status --instance=$INSTANCE_NAME -n $NAMESPACE
```

```text
Plan(s) for "cassandra" in namespace "default":
.
└── cassandra (Operator-Version: "cassandra-1.0.0" Active-Plan: "deploy")
    ├── Plan deploy (serial strategy) [IN_PROGRESS]
    │   └── Phase nodes (parallel strategy) [IN_PROGRESS]
    │       └── Step node [IN_PROGRESS]
    ├── Plan upgrade (serial strategy) [NOT ACTIVE]
    │   ├── Phase cleanup (serial strategy) [NOT ACTIVE]
    │   │   └── Step cleanup-stateful-set [NOT ACTIVE]
    │   └── Phase reinstall (serial strategy) [NOT ACTIVE]
    │       └── Step node [NOT ACTIVE]
    └── Plan backup (serial strategy) [NOT ACTIVE]
        └── Phase backup (serial strategy) [NOT ACTIVE]
            ├── Step cleanup [NOT ACTIVE]
            └── Step backup [NOT ACTIVE]

```

We can look into the restore process that happens in the init container before
the actual pod starts:

```bash
kubectl logs $INSTANCE_NAME-node-0 -c medusa-restore --namespace $NAMESPACE
```

```text
Start Restore for node 'cassandra' from backup 'Backup1' in prefix 'cluster1'
[2020-03-06 12:48:06,591] WARNING: is ccm : 0
[2020-03-06 12:48:06,795] INFO: Downloading data from backup to /tmp/medusa-restore-5aa6b9e3-831d-4d80-9ed1-1ca88f169f5b
[2020-03-06 12:48:08,226] INFO: Downloading backup data
...
[2020-03-06 12:48:17,947] INFO: Downloading backup data
[2020-03-06 12:48:18,522] INFO: Downloading backup metadata...
[2020-03-06 12:48:18,696] INFO: Stopping Cassandra
[2020-03-06 12:48:18,702] INFO: Moving backup data to Cassandra data directory
[2020-03-06 12:48:21,028] INFO: No --seeds specified so we will not wait for any
[2020-03-06 12:48:21,028] INFO: Starting Cassandra
```

This step can take quite a while for bigger backups.

### Verify the backup

As we have created a new cluster, and therefore a new service, we need to get
the external DNS again: Save the DNS of the external service of the cluster:

```bash
CASSANDRA_CLUSTER=`kubectl get service --namespace $NAMESPACE --field-selector metadata.name=$INSTANCE_NAME-svc-external -o jsonpath='{.items[*].status.loadBalancer.ingress[*].hostname}'`

echo "Cassandra Cluster DNS: $CASSANDRA_CLUSTER"
```

Now we can verify we get the same results as before the backup:

```bash
cqlsh $CASSANDRA_CLUSTER -e "USE schema1; SELECT * FROM users;"
```

```text
 user_id | age | first | last
---------+-----+-------+-------
  jsmith |  42 |  John | Smith

(1 rows)
```
