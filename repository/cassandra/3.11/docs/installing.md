# Installing the KUDO Cassandra Operator

**Table of Contents**

- [Requirements](#requirements)
- [Installing the operator](#installing-the-operator)

## Requirements

- The [KUDO CLI](https://kudo.dev/docs/#install-kudo-cli) installed on your
  machine
- [KUDO](https://kudo.dev/docs/#install-kudo-into-your-cluster) running in your
  cluster

Make sure that the KUDO version is at least 0.8.0, both for the CLI and the KUDO
running in your cluster.

To see the KUDO CLI version:

```bash
kubectl kudo version
```

To see the KUDO version running in your cluster:

```bash
kubectl get pods/kudo-controller-manager-0 \
        -n kudo-system \
        -o jsonpath='{.spec.containers[0].image}' \
  | cut -d: -f2
```

## Installing the operator

It is possible to install multiple instances of the KUDO Cassandra Operator.
Each instance is a managed Cassandra cluster. KUDO allows differentiating
instances with the `--instance` parameter.

KUDO operator instances are also namespaced via Kubernetes namespaces. It is
possible to have similarly named instances in different namespaces via the
`--namespace` parameter, and differently named instances in the same namespace.

The command below installs a KUDO Cassandra operator instance named
"analytics-cassandra" in the "production" namespace. Omitting the `--namespace`
parameter will cause the instance to be installed in the "default" namespace,
and omitting the `--instance` parameter will cause the instance name to be
"cassandra". If providing a namespace, make sure it exists.

```
kubectl kudo install cassandra \
        --instance analytics-cassandra \
        --namespace production
```

By default a 3-node Cassandra cluster is installed, with each Cassandra node
requiring 1 CPU and 4GiB memory.

The total resources needed are 3 CPUs and 12GiB memory

The command above will start the operator instance installation. To check the
installation progress, the KUDO CLI provides us with the `plan status` command.
Notice that the `--instance` and `--namespace` parameters must be passed on
every KUDO CLI command, so that it interacts with the correct operator instance.

Running `plan status` right after the install command will likely show the plan
as still "in progress". This means that the operator is still deploying all
necessary pods, services, etc.

```bash
kubectl kudo plan status deploy \
        --instance analytics-cassandra \
        --namespace production
```

```text
Plan(s) for "analytics-cassandra" in namespace "production":
.
└── analytics-cassandra (Operator-Version: "cassandra-0.1.0" Active-Plan: "deploy")
    └── Plan deploy (serial strategy) [IN_PROGRESS]
        └── Phase nodes [IN_PROGRESS]
            └── Step node (IN_PROGRESS)
```

After a minute or so the deployment should report as "complete":

```bash
kubectl kudo plan status deploy \
        --instance analytics-cassandra \
        --namespace production
```

```text
Plan(s) for "analytics-cassandra" in namespace "production":
.
└── analytics-cassandra (Operator-Version: "cassandra-0.1.0" Active-Plan: "deploy")
    └── Plan deploy (serial strategy) [COMPLETE]
        └── Phase nodes [COMPLETE]
            └── Step node (COMPLETE)
```

The operator instance pods will also report as "running":

```bash
kubectl get pods -n production
```

```text
NAME                         READY   STATUS    RESTARTS   AGE
analytics-cassandra-node-0   2/2     Running   0          124m
analytics-cassandra-node-1   2/2     Running   0          123m
analytics-cassandra-node-2   2/2     Running   0          122m
```

The Cassandra cluster should also report all nodes as "UN":

```bash
kubectl exec pod/analytics-cassandra-node-0 \
        -n production \
        -c cassandra \
        -- \
        bash -c "nodetool status"
```

```text
Datacenter: datacenter1
=======================
Status=Up/Down
|/ State=Normal/Leaving/Joining/Moving
--  Address          Load       Tokens       Owns (effective)  Host ID                               Rack
UN  192.168.180.232  219.93 KiB  256          68.7%             664c3243-a7b4-48cf-840d-3173aadf9595  rack1
UN  192.168.246.123  193.24 KiB  256          66.2%             38a639d0-6ead-4dcf-b301-f1272e7f870c  rack1
UN  192.168.144.100  191.78 KiB  256          65.1%             18c470c3-f210-4ced-8512-c720bd2828d8  rack1
```

The operator deploys a service that provides a DNS record for containers to
interact with the Cassandra cluster.

```bash
kubectl exec -it pod/analytics-cassandra-node-0 \
        -n production \
        -c cassandra \
        -- \
        bash -c 'cqlsh analytics-cassandra-svc.production.svc.cluster.local'
```

```text
Connected to analytics-cassandra at analytics-cassandra-svc.production.svc.cluster.local:9042.
[cqlsh 5.0.1 | Cassandra 3.11.4 | CQL spec 3.4.4 | Native protocol v4]
Use HELP for help.
cqlsh>
```

Check out the [parameters reference](./parameters.md) for a complete list of all
configurable settings.

Check out the
["configuration" section in the "managing" page](./managing.md#configuration)
for help with changing an existing operator instance's parameters and the
[operating](./operating.md) page for help with managing Cassandra operators and
their underlying Cassandra clusters.

## Required Permissions

KUDO Cassandra requires certain permissions in the cluster to operate. By
default, it creates one service account, role and role binding in the same
namespace as the installed instance. This service account has the permissions to
execute commands in pods.

If the operator is configured to use a `NODE_TOPOLOGY` for a
[multi datacenter setup](multidatacenter.md), additional permissions are
required and explained in the corresponding section.
