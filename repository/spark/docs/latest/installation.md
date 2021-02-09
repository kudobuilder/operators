# KUDO Spark Operator Installation 

## Installing the KUDO Spark Operator

Requirements:

- Install the [KUDO controller](https://kudo.dev/docs/getting-started/)
- Install the [KUDO CLI](https://kudo.dev/docs/cli/)

## Installing the Operator

Check out existing [limitations](limitations.md) before installing a KUDO Spark instance. Currently, multi-instance 
(multi-tenant) operator installation supports only a single instance per namespace. 

Create a namespace for the operator:
```
kubectl create ns spark
```
To install a new instance of Spark operator from the official repository, use the following command:
```
kubectl kudo install spark --namespace spark
```
This will install a Spark operator instance with the name `spark-instance` to the provided namespace.
You can also specify a different instance name using `--instance` parameter:

```
kubectl kudo install spark --instance spark-instance --namespace spark
```

Verify if the deploy plan for `--instance spark-instance` is complete:
```
kubectl kudo plan status --instance spark-instance --namespace spark

Plan(s) for "spark-instance" in namespace "spark":
.
└── spark-instance (Operator-Version: "spark-3.0.0-1.1.0" Active-Plan: "deploy")
    └── Plan deploy (serial strategy) [COMPLETE], last updated 2021-02-09 10:58:24
        ├── Phase preconditions (serial strategy) [COMPLETE]
        │   ├── Step crds [COMPLETE]
        │   ├── Step service-account [COMPLETE]
        │   └── Step rbac [COMPLETE]
        ├── Phase webhook (serial strategy) [COMPLETE]
        │   └── Step webhook [COMPLETE]
        ├── Phase spark (serial strategy) [COMPLETE]
        │   └── Step spark [COMPLETE]
        ├── Phase monitoring (serial strategy) [COMPLETE]
        │   └── Step monitoring [COMPLETE]
        └── Phase history (serial strategy) [COMPLETE]
            ├── Step history-deploy [COMPLETE]
            └── Step history-service [COMPLETE]
```

You can view all configuration options [here](configuration.md)

#### Installing multiple Spark Operator Instances

Optionally, create dedicated namespaces for installing KUDO Spark instances(e.g. `spark-operator-1` and `spark-operator-2` in this example):
```bash
kubectl create ns spark-operator-1 && kubectl create ns spark-operator-2
```
```
kubectl kudo install spark --instance=spark-1 --namespace spark-operator-1 -p sparkJobNamespace=spark-operator-1
kubectl kudo install spark --instance=spark-2 --namespace spark-operator-2 -p sparkJobNamespace=spark-operator-2
```

The above commands will install two Spark Operators in two different namespaces. Spark Applications submitted to a specific
namespace will be handled by the Operator installed in the same namespace. This is achieved by explicitly setting 
the `sparkJobNamespace` parameter to corresponding operator namespace.

#### Uninstalling the Spark Operator
The KUDO Spark Operator installation includes Custom Resource Definitions (CRDs) for Spark Applications and the KUDO Spark
Operator instances. While Operator instance can be used on a per-namespace basis, the Custom Resource Definitions
are a cluster-global resource which requires a manual cleanup when all KUDO Spark Operator instances are uninstalled.

To completely remove KUDO Spark Operator from a Kubernetes cluster:
1. Wait for the running jobs to complete or terminate them
  ```
  kubectl delete sparkapplications --all
  kubectl delete scheduledsparkapplications --all
  ```
1. Uninstall each KUDO Spark Operator instance:
  ```
  kubectl kudo uninstall --instance spark-instance --namespace spark
  ```
1. Remove Spark Applications CRDs:
  ```
  kubectl delete crds sparkapplications.sparkoperator.k8s.io scheduledsparkapplications.sparkoperator.k8s.io
  ```
