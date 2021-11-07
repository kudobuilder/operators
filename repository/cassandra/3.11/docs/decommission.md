# Decommission KUDO Cassandra nodes

KUDO Cassandra does not provide an automated way to scale down the Cassandra
cluster, as this is a critical operation that should not be repeated frequently,
and to discourage anti-patterns when managing an Apache Cassandra cluster.

## Manually decommissioning KUDO Cassandra nodes

KUDO Cassandra only supports decommissioning the node with the highest pod
ordinal index. e.g. when having a cluster with following pods:

```
NAME                         READY   STATUS    RESTARTS   AGE
analytics-cassandra-node-0   2/2     Running   0          124m
analytics-cassandra-node-1   2/2     Running   0          123m
analytics-cassandra-node-2   2/2     Running   0          120m
analytics-cassandra-node-3   2/2     Running   0          118m
analytics-cassandra-node-4   2/2     Running   0          117m
```

we can only decommission `analytics-cassandra-node-4` as it has the highest pod
ordinal index `4`.

### Decomission the node

```bash
kubectl exec -it pod/analytics-cassandra-node-4 \
        -n dev \
        -c cassandra \
        -- \
        nodetool decommission
```

Once the operation is completed, we can update the KUDO Cassandra Instance

```
kubectl kudo update -p NODE_COUNT=4 --instance analytics-cassandra -n dev
```

Once the update plan is complete, we can delete the PVC that was attached to the
KUDO Cassandra `pod/analytics-cassandra-node-4`. Not deleting or cleaning the
PVC will result in issues when scaling the cluster up next time.
