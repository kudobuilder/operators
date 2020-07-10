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
This will install Spark operator instance with a name `spark-instance` to the provided namespace.
You can also specify instance name using `--instance` parameter:

```
kubectl kudo install spark --instance spark-operator --namespace spark
```

Verify if the deploy plan for `--instance spark-instance` is complete:
```
kubectl kudo plan status --instance spark-instance --namespace spark

Plan(s) for "spark-instance" in namespace "spark":
.
└── spark-instance (Operator-Version: "spark-1.0.1" Active-Plan: "deploy")
    └── Plan deploy (serial strategy) [COMPLETE], last updated 2020-07-10 12:21:26
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
