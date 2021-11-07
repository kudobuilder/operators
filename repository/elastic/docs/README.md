# Elastic

Elasticsearch is a distributed, RESTful search and analytics engine. It is based on Apache Lucene.

This Framework is deploying an Elasticsearch Cluster.

## Prerequisites

You need a `Kubernetes cluster` up and running and `Persistent Storage` available with a default `Storage Class` defined.

If you use `minikube` then launch it with the following resource options.

```sh
minikube start --vm-driver=hyperkit --cpus=3 --memory=9216 --disk-size=10g
```

## Runbooks

- [Installing an instance](install.md)
- [Using an instance](use.md)
- [Updating an instance](udpate.md)
