# Redis

Redis is an open source (BSD licensed), in-memory data structure store, used as a database, cache and message broker.

Redis Cluster provides a way to run a Redis installation where data is automatically sharded across multiple Redis nodes.

This Framework is deploying a Redis Cluster.

## Prerequisites

You need a Kubernetes cluster up and running and Persistent Storage available with a default `Storage Class` defined.

## Getting Started

Deploy the `Framework` using the following command:

`kubectl apply -f https://raw.githubusercontent.com/kudobuilder/frameworks/master/repo/incubating/redis/versions/0/redis-framework.yaml`

Deploy the `FrameworkVersion` using the following command:

`kubectl apply -f https://raw.githubusercontent.com/kudobuilder/frameworks/master/repo/incubating/redis/versions/0/redis-frameworkversion.yaml`

Deploy the `Instance` using the following command:

`kubectl apply -f https://raw.githubusercontent.com/kudobuilder/frameworks/master/repo/incubating/redis/versions/0/redis-instance.yaml`

You can check that everything has been deployed correctly as below:

```
kubectl get pods
NAME                             READY   STATUS      RESTARTS   AGE
rediscluster1-deploy-job-r9rfg   0/1     Completed   0          85m
rediscluster1-redis-0            1/1     Running     0          86m
rediscluster1-redis-1            1/1     Running     0          86m
rediscluster1-redis-2            1/1     Running     0          86m
rediscluster1-redis-3            1/1     Running     0          85m
rediscluster1-redis-4            1/1     Running     0          85m
rediscluster1-redis-5            1/1     Running     0          85m
```

It deploys a Redis Cluster composed of 6 instances. There are 3 masters and 1 slave per master.

The first Pod corresponds to a Job launched to initialize the cluster.
