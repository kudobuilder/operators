# Kafka Connect

## Overview

KUDO Kafka operator comes with builtin integration of [Kafka Connect](https://kafka.apache.org/documentation/#connect).

Kafka Connect is a tool for scalably and reliably streaming data between Apache Kafka and other systems. It provides a [REST API](https://kafka.apache.org/documentation/#connect_rest) to configure and interact connectors.

Kafka Connect integration is disabled by default.

This guide shows how to stream data from a Cassandra instance to a MySQL instance using the integration provided by the operator.

## Pre-conditions

The following are necessary for this runbook:
- One running Cassandra cluster.
- One running MySQL server.

## Steps

### Preparation

### 1. Set the shell variables

The examples below assume the following shell variables. With this assumptions met, you should be able to copy-paste the commands easily.

```bash
kafka_namespace_name=kafka-demo
kafka_instance_name=kafka
```

You also need the following:

:arrow_right: **Cassandra instance node list**

:warning: This runbook assumes that the Cassandra instance has transport encryption (TLS) and authorization disabled.

**If the Cassandra instance is a [KUDO Cassandra](https://github.com/kudobuilder/operators/tree/master/repository/cassandra/3.11) instance running in the same kubernetes
cluster:**

You can generate the node list using the following commands:
```bash
cassandra_instance_name=cassandra
cassandra_namespace_name=cassandra-demo
cassandra_port=$(kubectl get svc ${cassandra_instance_name}-svc -n $cassandra_namespace_name \
  --template='{{ range .spec.ports }}{{if eq .name "native-transport" }}{{ .port }}{{ end }}{{ end }}')
cassandra_node_list=$(kubectl get pods -l app=cassandra,cassandra=cassandra,kudo.dev/instance=$cassandra_instance_name -n $cassandra_namespace_name \
  --template="{{ range .items }}{{ .spec.hostname }}.{{ .spec.subdomain }}.{{ .metadata.namespace }}.svc.cluster.local{{ \"\\n\" }}{{end}}" \
  | head -n 3 | paste -d, -s)
echo $cassandra_node_list 
```

Example output:
```
cassandra-node-0.cassandra-svc.cassandra-demo.svc.cluster.local,cassandra-node-1.cassandra-svc.cassandra-demo.svc.cluster.local,cassandra-node-2.cassandra-svc.cassandra-demo.svc.cluster.local
```

**Otherwise:**

Please refer to its documentation about how to retrieve a list of cassandra nodes.
These need to be reachable from the KUDO Kafka instance.

```bash
cassandra_nodes_list=cassandra-node-1.example.com,cassandra-node-2.example.com
```

:arrow_right: **MySQL instance hostname, port, user credentinals and database name**

**If the MySQL instance is a [KUDO MySQL](https://github.com/kudobuilder/operators/tree/master/repository/mysql) instance running in the same kubernetes
cluster:**

You can generate the required MySQL variables using the following commands:
```bash
mysql_instance_name=mysql
mysql_namespace_name=mysql-demo
mysql_port=$(kubectl get svc ${mysql_instance_name} -n $mysql_namespace_name \
  --template='{{ range .spec.ports }}{{ .port }}{{ end }}')
mysql_hostname=$mysql_instance_name.$mysql_namespace_name.svc.cluster.local
mysql_user=demo
mysql_password=demo
mysql_database=demo
mysql_root_password=$(kubectl get pods -l app=mysql,kudo.dev/instance=$mysql_instance_name -n $mysql_namespace_name \
  --template='{{ range .items }}{{ range .spec.containers }}{{ if eq .name "mysql" }}{{ range .env }}{{ if eq .name "MYSQL_ROOT_PASSWORD" }}{{ .value }}{{ "\n" }}{{ end }}{{ end }}{{ end }}{{ end }}{{ end }}' \
  | head -n 1 )
mysql_pod=$(kubectl get pods -l app=mysql,kudo.dev/instance=$mysql_instance_name -n $mysql_namespace_name \
  --template='{{ range .items }}{{ .metadata.name }}{{ "\n" }}{{ end }}' \
  | head -n 1 )
kubectl exec -n $mysql_namespace_name -it $mysql_pod -- mysql -p$mysql_root_password --execute="CREATE DATABASE demo; GRANT ALL PRIVILEGES ON demo.* TO 'demo'@'%' IDENTIFIED BY 'demo'; FLUSH PRIVILEGES;"
echo $mysql_hostname $mysql_port
echo $mysql_user $mysql_password
echo $mysql_database
```
:warning: The commands also create a user `demo` with full access to a new database `demo`.

Example output:
```
mysql.mysql-demo.svc.cluster.local 3306
demo demo
demo
```

**Otherwise:**

Please refer to its documentation about how to retrieve the hostname and port.
The hostname and port need to be reachable from the KUDO Kafka instance. Also the user credintials provided must be able to create tables, read and write data in the database.

```bash
mysql_hostname=mysql.example.com
mysql_port=3306
mysql_user=demo
mysql_password=demo
mysql_database=demo
```

### 2. Create a new schema with table in the Cassandra instance

Create a schema `demo` and a table `users`. Run the following CQL query in `cqlsh`:

```sql
CREATE SCHEMA demo WITH replication = { 'class' : 'SimpleStrategy', 'replication_factor' : 1 };
USE demo;
CREATE TABLE users ( userid int, firstname varchar, lastname varchar, email varchar,
 created_date timestamp, PRIMARY KEY (userid));
```

:information_source: If the Cassandra instance is a KUDO Cassandra instance running in the same kubernetes
cluster, use the following commands to access cqlsh:

```bash
cassandra_pod=$(kubectl get pods -l app=cassandra,cassandra=cassandra,kudo.dev/instance=$cassandra_instance_name -n $cassandra_namespace_name \
  --template='{{ range .items }}{{ .metadata.name }}{{ "\n" }}{{ end }}' \
  | head -n 1 )
kubectl exec -n $cassandra_namespace_name -it -c cassandra $cassandra_pod -- bash -c "CQLSH_PORT=$cassandra_port CQLSH_HOST=\$(hostname -f) cqlsh"
```

## Setup Kafka Connect

### Connectors Configuration

KUDO Kafka Connect accepts a Config Map with an entry of `config.json`. This configuration file contains the bootstrap connectors list describing their respective external asset list with and their configuration.

```json
{
  "<connector#1-name>": {
    "resources": [
      "<link to asset#1>",
      "<link to asset#2>",
      ...
    ],
    "config": <configuration of connector#1>
  },
  ...
}
```

:information_source: The operator also accepts configuration in YAML format.

:information_source: The operator uses `p7zip` utility to extract archive assets. For the list of supported archive formats check its [documentation](https://packages.debian.org/buster/p7zip-full).


#### Configuring Cassandra Source and MySQL Sink connectors


```bash
cat <<EOT > config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: connectorsconfig
  namespace: ${kafka_namespace_name}
data:
  config.json: |
    {
      "mysql-sink-connector": {
        "resources": [
            "https://d1i4a15mxbxib1.cloudfront.net/api/plugins/confluentinc/kafka-connect-jdbc/versions/5.4.0/confluentinc-kafka-connect-jdbc-5.4.0.zip",
            "https://cdn.mysql.com//Downloads/Connector-J/mysql-connector-java-8.0.19.zip"
        ],
        "config": {
            "name": "jdbc_dest_mysql_users",
            "config": {
                "connector.class": "io.confluent.connect.jdbc.JdbcSinkConnector",
                "tasks.max": "1",
                "topics": "demo_topic",
                "connection.url": "jdbc:mysql://${mysql_hostname}:${mysql_port}/${mysql_database}?user=${mysql_user}&password=${mysql_password}",
                "auto.create": "true",
                "name": "jdbc_dest_mysql_users"
            }
        }
      },
      "cassandra-source-connector": {
        "resources": [
            "https://github.com/lensesio/stream-reactor/releases/download/1.2.3/kafka-connect-cassandra-1.2.3-2.1.0-all.tar.gz"
        ],
        "config": {
            "name": "cassandra_source_users",
            "config": {
                "tasks.max": "1",
                "connector.class": "com.datamountaineer.streamreactor.connect.cassandra.source.CassandraSourceConnector",
                "connect.cassandra.contact.points": "${cassandra_node_list}",
                "connect.cassandra.port": ${cassandra_port},
                "connect.cassandra.consistency.level": "LOCAL_ONE",
                "connect.cassandra.key.space": "demo",
                "connect.cassandra.import.mode": "incremental",
                "connect.cassandra.kcql": "INSERT INTO demo_topic SELECT * FROM users PK created_date INCREMENTALMODE=TIMESTAMP",
                "connect.cassandra.import.poll.interval": 5000
            }
        }
      }
    }
EOT
kubectl apply -f config.yaml
```


### Update instance to start Kafka Connect

Run the following command to start Kafka Connect alongside the KUDO Kafka instance:

```sh
kubectl kudo update --instance=$kafka_instance_name \
  --namespace=$kafka_namespace_name \
  -p KAFKA_CONNECT_ENABLED=true \
  -p KAFKA_CONNECT_CONNECTORS_CM=connectorsconfig
```

### Insert dummy data in the Cassandra table

Execute CQL insert statements in `cqlsh` to add data to the `users` table.

:bulb: To generate CQL insert statements containing random data use the following commands:

```bash
ID="${ID:-1}";query=""
for ((i = $ID ; i <= $ID+5 ; i++))
do
  user=$(http https://randomuser.me/api/)
  first=$(echo $user | jq -r '.results[].name.first')
  last=$(echo $user | jq -r '.results[].name.last')
  first=$(echo $user | jq -r '.results[].name.first')
  email=$(echo $user | jq -r '.results[].email')
  query="$query\nINSERT INTO users (userid, firstname, lastname, email, created_date) VALUES ( $i, '$first', '$last', '$email', toTimestamp(now()));"
done
ID=$i
printf "$query\n"
```

Run the following CQL commands to check for the inserted rows in `users` table:

```sql
USE demo;
SELECT * FROM users;
```

Example output:

```sql
 userid | created_date                    | email                        | firstname | lastname
--------+---------------------------------+------------------------------+-----------+----------
      5 | 2020-02-17 23:58:30.683000+0000 |         swrn.prs@example.com |    George |    Brown
      1 | 2020-02-17 23:58:30.569000+0000 |     jaime.torres@example.com |     Jaime |   Torres
      2 | 2020-02-17 23:58:30.587000+0000 |    gladys.morris@example.com |    Gladys |   Morris
      4 | 2020-02-17 23:58:30.670000+0000 |    marina.crespo@example.com |    Marina |   Crespo
      6 | 2020-02-17 23:58:30.690000+0000 | matilda.anderson@example.com |   Matilda | Anderson
      3 | 2020-02-17 23:58:30.638000+0000 |      enzo.novaes@example.com |      Enzo |   Novaes
```


### Check MySQL database for new data

Kafka Connect will sync data from the Cassandra `users` table into MySQL. A new table `demo_topic` will be created by Kafka Conenct which be used to insert data from the `users` table of Cassandra. To check for new data run the following SQL statements:

```sql
USE demo;
SHOW tables;
SELECT * FROM demo_topic;
```

Example output:

```sql
mysql> use demo;

Database changed
mysql> show tables;
+----------------+
| Tables_in_demo |
+----------------+
| demo_topic     |
+----------------+
1 row in set (0.00 sec)

mysql> select * from demo_topic;
+-----------+-------------------------+--------+------------------------------+----------+
| firstname | created_date            | userid | email                        | lastname |
+-----------+-------------------------+--------+------------------------------+----------+
| George    | 2020-02-17 23:58:30.683 |      5 | swrn.prs@example.com         | Brown    |
| Jaime     | 2020-02-17 23:58:30.569 |      1 | jaime.torres@example.com     | Torres   |
| Gladys    | 2020-02-17 23:58:30.587 |      2 | gladys.morris@example.com    | Morris   |
| Marina    | 2020-02-17 23:58:30.670 |      4 | marina.crespo@example.com    | Crespo   |
| Matilda   | 2020-02-17 23:58:30.690 |      6 | matilda.anderson@example.com | Anderson |
| Enzo      | 2020-02-17 23:58:30.638 |      3 | enzo.novaes@example.com      | Novaes   |
+-----------+-------------------------+--------+------------------------------+----------+
6 rows in set (0.00 sec)
```

## Disable Kafka Connect

To disable Kafka Connect, scale the
pod count to 0, using the following command:

```sh
kubectl kudo update --instance=$kafka_instance_name \
  --namespace=$kafka_namespace_name \
  -p KAFKA_CONNECT_REPLICA_COUNT=0
``` 


## Limitations

Currently Kafka Connect works with Kafka protocol `PLAINTEXT` only. It will not work if Kerberos and or TLS is
enabled in the Kafka instance. Future releases of KUDO Kafka will
address this limitation through a Kafka Connect operator.
