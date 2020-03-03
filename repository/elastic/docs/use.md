# Use an Instance

## Overview

This guide shows how to use an instance of Elastic Search deployed using KUDO.

## Pre-conditions

The following are necessary for this runbook:

- [KUDO CLI](https://kudo.dev/docs/cli/) installed locally
- An instance of Elastic [deployed using KUDO](install.md)

## Steps

### Preparation

### 1. Set the shell variables

The examples below assume the following shell variables. With this assumptions met, you should be able
to copy-paste the commands easily.

```bash
this_instance_name=elastic
this_namespace_name=default
```

### 2. Start a shell in one of the pods

The following command will propagate variables you just set:

```bash
kubectl exec --namespace=$namespace_name -ti master-0 \
 env this_instance_name=$this_instance_name this_namespace_name=$this_namespace_name bash
```

Example output:
```
[root@master-0 elasticsearch]# 
```

### 3. Check cluster health

Use the following curl command to check the health of the cluster.

```bash
curl coordinator-hs:9200/_cluster/health?pretty
```

Example output:

```json
{
  "cluster_name" : "elastic-cluster",
  "status" : "green",
  "timed_out" : false,
  "number_of_nodes" : 6,
  "number_of_data_nodes" : 2,
  "active_primary_shards" : 0,
  "active_shards" : 0,
  "relocating_shards" : 0,
  "initializing_shards" : 0,
  "unassigned_shards" : 0,
  "delayed_unassigned_shards" : 0,
  "number_of_pending_tasks" : 0,
  "number_of_in_flight_fetch" : 0,
  "task_max_waiting_in_queue_millis" : 0,
  "active_shards_percent_as_number" : 100.0
}
```

### 4. Add and retrieve data

Use the following curl command to add some data:

```bash
curl -X POST "coordinator-hs:9200/twitter/_doc/" -H 'Content-Type: application/json' -d'
{
    "user" : "kimchy",
    "post_date" : "2009-11-15T14:12:12",
    "message" : "trying out Elasticsearch"
}
'
```

Use the following curl command to search for the data just added:

```bash
curl -X GET "coordinator-hs:9200/twitter/_search?q=user:kimchy&pretty"
```

Example output:

```json
{
  "took" : 6,
  "timed_out" : false,
  "_shards" : {
    "total" : 1,
    "successful" : 1,
    "skipped" : 0,
    "failed" : 0
  },
  "hits" : {
    "total" : {
      "value" : 1,
      "relation" : "eq"
    },
    "max_score" : 0.2876821,
    "hits" : [
      {
        "_index" : "twitter",
        "_type" : "_doc",
        "_id" : "n18aemoBCj0qv5VrMWv2",
        "_score" : 0.2876821,
        "_source" : {
          "user" : "kimchy",
          "post_date" : "2009-11-15T14:12:12",
          "message" : "trying out Elasticsearch"
        }
      }
    ]
  }
}
```

## Further reading

You can learn more on how to use Elasticsearch from the
[Elasticsearch documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/index.html).

