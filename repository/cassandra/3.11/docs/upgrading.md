# Upgrade KUDO Cassandra

This guide explains how to upgrade a running KUDO Cassandra instance to a newer
version of KUDO Cassandra.

## Pre-conditions

- KUDO Cassandra instance running
- KUDO CLI installed

## Steps

### Preparation

#### 1. Set the shell variables

The examples below assume that the instance and namespace names are stored in
the following shell variables. With this assumptions met, you should be able to
copy-paste the commands easily.

```bash
instance_name=cassandra
namespace_name=default
destination_version=1.0.0
```

#### 2. Verify that the variables are set correctly

```bash
kubectl get instance $instance_name -n $namespace_name
echo About to upgrade to $destination_version

```

Example output:

```bash
NAME        AGE
cassandra   16h
About to upgrade to 1.0.0
```

#### 3. Verify the state of the KUDO Cassandra instance

```bash
kubectl kudo plan status --instance=$instance_name -n $namespace_name
```

In the output note if:

- the current `Operator-Version` matches your expectation, and
- deploy plan is `COMPLETE`

Example output:

```text
Plan(s) for "cassandra" in namespace "default":
.
└── cassandra (Operator-Version: "cassandra-1.0.0" Active-Plan: "deploy")
    └── Plan deploy (serial strategy) [COMPLETE]
        └── Phase nodes (parallel strategy) [COMPLETE]
            └── Step node [COMPLETE]

```

### Upgrade

```bash
kubectl kudo upgrade cassandra -n $namespace_name --instance=$instance_name --operator-version=$destination_version
```

Example output:

```text
operatorversion.kudo.dev/v1beta1/cassandra-1.0.0 created
instance.kudo.dev/v1beta1/cassandra updated
```

### Verification

Check the plan status:

```bash
kubectl kudo plan status --instance=$instance_name -n $namespace_name
```

Expected output should show:

- `deploy` plan either `IN_PROGRESS` or `COMPLETE`, and
- the `Operator-Version` to match the destination version.

```text
Plan(s) for "cassandra" in namespace "default":
.
└── cassandra (Operator-Version: "cassandra-1.0.0" Active-Plan: "deploy")
    └── Plan deploy (serial strategy) [IN_PROGRESS]
        └── Phase nodes (parallel strategy) [IN_PROGRESS]
            └── Step node [IN_PROGRESS]

```

Once the pods are ready (passing readiness and liveness checks), the plan should
change to `COMPLETE`.
