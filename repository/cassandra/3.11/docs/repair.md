# Repair KUDO Cassandra

KUDO Cassandra comes with a repair plan. It can be triggered using the
`REPAIR_POD` parameter.

Let's see with an example of a 3 node cluster

```
kubectl get pods
NAME                                       READY   STATUS      RESTARTS   AGE
cassandra-instance-node-0                  1/1     Running     0          4m44s
cassandra-instance-node-1                  1/1     Running     0          4m7s
cassandra-instance-node-2                  1/1     Running     1          3m25s
```

we can repair the node-0 by running

```
kubectl kudo update --instance=cassandra-instance -p REPAIR_POD=cassandra-instance-node-0
```

This launches a job to repair the node-0

```
kubectl get jobs
NAME                                 COMPLETIONS   DURATION   AGE
cassandra-instance-node-repair-job   0/1           6s         6s
```

You can also follow the repair plan through the plan status

```
kubectl kudo plan status --instance=cassandra-instance
Plan(s) for "cassandra-instance" in namespace "default":
.
└── cassandra-instance (Operator-Version: "cassandra-1.0.0" Active-Plan: "repair")
    ├── Plan backup (serial strategy) [NOT ACTIVE]
    │   └── Phase backup (serial strategy) [NOT ACTIVE]
    │       ├── Step cleanup [NOT ACTIVE]
    │       └── Step backup [NOT ACTIVE]
    ├── Plan deploy (serial strategy) [NOT ACTIVE]
    │   ├── Phase rbac (parallel strategy) [NOT ACTIVE]
    │   │   └── Step rbac-deploy [NOT ACTIVE]
    │   └── Phase nodes (serial strategy) [NOT ACTIVE]
    │       ├── Step pre-node [NOT ACTIVE]
    │       └── Step node [NOT ACTIVE]
    └── Plan repair (serial strategy) [COMPLETE], last updated 2020-06-18 13:15:35
        └── Phase repair (serial strategy) [COMPLETE]
            ├── Step cleanup [COMPLETE]
            └── Step repair [COMPLETE]
```

And to fetch the logs of the repair job we can get logs of the job.

```
kubectl logs --selector job-name=cassandra-instance-node-repair-job
I0618 11:18:06.389132       1 request.go:621] Throttling request took 1.154911388s, request: GET:https://10.0.0.1:443/apis/scheduling.kubefed.io/v1alpha1?timeout=32s
[2020-06-18 11:18:14,626] Replication factor is 1. No repair is needed for keyspace 'system_auth'
[2020-06-18 11:18:14,723] Starting repair command #1 (66fb8e80-b155-11ea-8794-a356fd81d293), repairing keyspace system_traces with repair options (parallelism: parallel, primary range: false, incremental: true, job threads: 1, ColumnFamilies: [], dataCenters: [], hosts: [], # of ranges: 512, pull repair: false)
[ ... lines removed for clarity ...]
[2020-06-18 11:18:18,720] Repair completed successfully
[2020-06-18 11:18:18,723] Repair command #1 finished in 4 seconds
```
