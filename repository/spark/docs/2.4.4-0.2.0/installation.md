KUDO Spark Operator Installation 
---

## Installing the KUDO Spark Operator

Requirements:

- Install the [KUDO controller](https://kudo.dev/docs/getting-started/)
- Install the [KUDO CLI](https://kudo.dev/docs/cli/)

## Installing the Operator

Check out existing [limitations](limitations.md) before installing a KUDO Spark instance. Currently, multi-instance 
(multi-tenant) operator installation supports only a single instance per namespace. 

```
kubectl kudo install spark --instance=spark
```

Verify if the deploy plan for `--instance=spark` is complete:
```
kubectl kudo plan status --instance=spark

Plan(s) for "spark" in namespace "default":
.
└── spark-instance (Operator-Version: "spark-beta1" Active-Plan: "deploy")
    └── Plan deploy (serial strategy) [COMPLETE]
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
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: spark-operator-1
  labels:
    name: spark-operator-1
---
apiVersion: v1
kind: Namespace
metadata:
  name: spark-operator-2
  labels:
    name: spark-operator-2
EOF
```

```
kubectl kudo install spark --instance=spark-1 --namespace spark-operator-1
kubectl kudo install spark --instance=spark-2 --namespace spark-operator-2
```

The above commands will install two Spark Operators in two different namespaces. Spark Applications submitted to a specific
namespace will be handled by the Operator installed in the same namespace.
