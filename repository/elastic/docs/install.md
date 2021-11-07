# Deploy an Instance

## Overview

This guide shows how to deploy an instance of Elastic Search using KUDO.

## Pre-conditions

The following are necessary for this runbook:

- A kubernetes cluster
- [KUDO CLI](https://kudo.dev/docs/cli/) installed locally
- [KUDO controller](https://kudo.dev/docs/getting-started/) deployed on the cluster

## Steps

### 1. Set the shell variables

The examples below assume the following shell variables. With this assumptions met, you should be able
to copy-paste the commands easily.

```bash
instance_name=elastic
namespace_name=default
```

### 2. Deploy an instance

Run the following command:

```bash
kubectl kudo install elastic --namespace=$namespace_name --instance $instance_name
```

Example output:
```
operator.kudo.dev/v1beta1/elastic created
operatorversion.kudo.dev/v1beta1/elastic-0.2.0 created
instance.kudo.dev/v1beta1/elastic created
```

### 3. Verify successful deployment

Verify if the deploy plan is complete:

```bash
kubectl kudo plan status --namespace=$namespace_name --instance $instance_name
```

Example output:

```
Plan(s) for "elastic" in namespace "default":
.
└── elastic (Operator-Version: "elastic-0.2.0" Active-Plan: "deploy")
    └── Plan deploy (serial strategy) [COMPLETE]
        ├── Phase deploy-master (parallel strategy) [COMPLETE]
        │   └── Step deploy-master [COMPLETE]
        ├── Phase deploy-data (parallel strategy) [COMPLETE]
        │   └── Step deploy-data [COMPLETE]
        ├── Phase deploy-coordinator (parallel strategy) [COMPLETE]
        │   └── Step deploy-coordinator [COMPLETE]
        └── Phase deploy-ingest (parallel strategy) [COMPLETE]
            └── Step deploy-ingest [COMPLETE]

```

Once the deployment has finished use the following command.

```bash
kubectl get pods -n $namespace_name
```

You should see that 3 master, 2 data, and 1 coordinator node are running and ready.

```
NAME            READY   STATUS    RESTARTS   AGE
coordinator-0   1/1     Running   0          23m
data-0          1/1     Running   0          24m
data-1          1/1     Running   0          24m
master-0        1/1     Running   0          25m
master-1        1/1     Running   0          24m
master-2        1/1     Running   0          24m
```

