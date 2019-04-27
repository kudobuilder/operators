# Elastic


## Prerequisites

You need a Kubernetes cluster up and running and Persistent Storage available with a default `Storage Class` defined.


## Deploy the Framework and FrameworkVersion

Deploy the `Framework` using the following command:
```
kubectl apply -f https://raw.githubusercontent.com/kudobuilder/frameworks/master/repo/incubating/elastic/versions/0/elastic-framework.yaml
```

Deploy the `FrameworkVersion` using the following command:
```
kubectl apply -f https://raw.githubusercontent.com/kudobuilder/frameworks/master/repo/incubating/elastic/versions/0/elastic-frameworkversion.yaml
```


## Deploy an Instance

Deploy the `Instance` using the following command:
```
kubectl apply -f https://raw.githubusercontent.com/kudobuilder/frameworks/master/repo/incubating/elastic/versions/0/elastic-instance.yaml
```


## Use the instance

Exec into one of the POD's
```
kubectl -it exec myes-node-0 bash
```

Use the following curl command to check the health of the cluster.
```
curl myes-node-0.myes-hs:9200/_cluster/health?pretty
```

You should see the following output.
```
{
  "cluster_name" : "myes-cluster",
  "status" : "green",
  "timed_out" : false,
  "number_of_nodes" : 3,
  "number_of_data_nodes" : 3,
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

Lets add some data.
```
curl -X POST "myes-node-0.myes-hs:9200/twitter/_doc/" -H 'Content-Type: application/json' -d'
{
    "user" : "kimchy",
    "post_date" : "2009-11-15T14:12:12",
    "message" : "trying out Elasticsearch"
}
'
```

Lets search for the entry.
```
curl -X GET "myes-node-0.myes-hs:9200/twitter/_search?q=user:kimchy"
```

You should see the following output.
```
{
  "took" : 74,
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
        "_id" : "qgisYGoB5y1lRDh0Miao",
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

To learn more on how to use elasticsearch checkout the [elasticsearch documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/index.html).
