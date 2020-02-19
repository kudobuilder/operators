# Update an Instance

## Overview

This guide shows how to change a setting on an instance of Elastic Search deployed using KUDO.

## Pre-conditions

The following are necessary for this runbook:

- [KUDO CLI](https://kudo.dev/docs/cli/) installed locally
- An instance of Elastic [deployed using KUDO](install.md)

## Steps

### 1. Set the shell variables

The examples below assume the following shell variables. With this assumptions met, you should be able
to copy-paste the commands easily.

```bash
this_instance_name=elastic
this_namespace_name=default
```

### 2. Change data node count

Lets increase the `DATA_NODE_COUNT` to `3` using the following command.

```sh
kubectl kudo update --namespace=$namespace_name --instance $instance_name -p DATA_NODE_COUNT=3
```

Example output:
```
Instance elastic was updated.
```

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

You should now see that a third `data` node has been deployed and ready.

Example output:

```
NAME            READY   STATUS    RESTARTS   AGE
coordinator-0   1/1     Running   0          23m
data-0          1/1     Running   0          24m
data-1          1/1     Running   0          24m
data-2          1/1     Running   0          77s
master-0        1/1     Running   0          25m
master-1        1/1     Running   0          24m
master-2        1/1     Running   0          24m
```
