# Managing KUDO Cassandra Operator instances

**Table of Contents**

- [Managing KUDO Cassandra Operator instances](#managing-kudo-cassandra-operator-instances)
  - [Updating parameters](#updating-parameters)
  - [Upgrading](#upgrading)
  - [Failure handling](#failure-handling)
    - [Recovery controller](#recovery-controller)
      - [Node eviction](#node-eviction)
    - [Manual node replacement](#manual-node-replacement)
  - [Accessing](#accessing)
  - [Debugging](#debugging)
    - [Plan status](#plan-status)
    - [Get pods](#get-pods)
    - [Pod container logs](#pod-container-logs)
    - [Describe pod](#describe-pod)
    - [Cassandra nodetool status](#cassandra-nodetool-status)
    - [KUDO controller/manager logs](#kudo-controllermanager-logs)
    - [Get endpoints](#get-endpoints)
    - [Kubernetes events in the instance namespace](#kubernetes-events-in-the-instance-namespace)
  - [Uninstall an operator instance](#uninstall-an-operator-instance)

## Updating parameters

Installing an instance is just the beginning. After doing so, it is likely that
you will need to change the instance's parameter to:

- Scale the cluster horizontally
- Configure specific `cassandra.yaml` or JVM option settings
- Enable or disable monitoring

To change an instance's parameters, the `kubectl kudo update` command can be
used.

```bash
kubectl kudo update cassandra \
        --instance analytics-cassandra \
        --namespace production \
        -p SOME_PARAMETER=SOME_VALUE
```

For example, the following command starts a rolling configuration update setting
`cassandra.yaml`'s `hinted_handoff_throttle_in_kb` to `2048` in all of the
cluster nodes'.

```bash
kubectl kudo update cassandra \
        --instance analytics-cassandra \
        --namespace production \
        -p HINTED_HANDOFF_THROTTLE_IN_KB=2048
```

Multiple parameters can be updated in parallel as well.

```bash
kubectl kudo update cassandra \
        --instance analytics-cassandra \
        --namespace production \
        -p CONCURRENT_READS=32 \
        -p CONCURRENT_WRITES=64 \
        -p JVM_OPT_RING_DELAY_MS=60000ms
```

When `kubectl kudo update` commands are run KUDO will start working on the
"deploy" plan, which takes care of the rolling configuration update. You can
check for its status similarly to how we did it after
[installing an instance](./installing.md).

```bash
kubectl kudo plan status deploy \
        --instance analytics-cassandra \
        --namespace production
```

It is advisable to wait for the plan to reach a "COMPLETE" status before
performing any other operations.

Check out the [parameters reference](./parameters.md) for a complete list of all
configurable settings.

## Upgrading

See the [document on upgrading](upgrading.md).

## Failure handling

When using local storage, a Cassandra pod is using a local persistent volume
that is only available when the pod is scheduled in a specific node. Any
rescheduling will land the pod to the very same node due to the volume node
affinity.

This is an issue in case of a total Kubernetes node loss: the pods running on an
unreachable Node enter the states Terminating or Unknown. Kubernetes doesn’t
allow the deletion of those pods to avoid any brain-split.

KUDO Cassandra provides a way to automatically handle these failure modes and
move a Cassandra node that is located on a failed Kubernetes node to a different
node in the cluster.

### Recovery controller

To enable this feature, use the following parameter:

```bash
RECOVERY_CONTROLLER=true
```

When this parameter is set, KUDO Cassandra will deploy an additional controller
that monitors the deployed Cassandra pods. If any pod reaches an unschedulable
state and detects that the kubernetes node is gone, it will remove the local
volume of that pod and allow Kubernetes to schedule the pod to a different node.
Additionally, the rescheduling can be triggered by an eviction label.

The recovery controller relies on the Kubernetes state of a node, not the actual
running processes. This means that the failure of the hardware on which a
Cassandra node runs does not trigger the recovery. The only way an automatic
recovery is triggered is when the Kubernetes node is removed from the cluster by
kubectl delete node <failed-node-name>. This allows a Kubernetes node to be shut
down for a maintenance period without KUDO Cassandra triggering a recovery.

:warning: This feature will remove persistent volume claims in the Kubernetes
cluster. This may lead to data loss. Additionally, you must not use any
keyspaces with a replication factor of ONE, or the data of the failed Cassandra
node will be lost.

#### Node eviction

Evicting a Cassandra node is similar to Failure recovery described above. The
recovery controller will automate certain steps. The main difference is that
during node eviction the Kubernetes node should stay available, i.e. other pods
on that node shouldn’t get evicted. To evict a Cassandra node, first cordon or
taint the Kubernetes node the Cassandra node is running on. Alternatively, add
the label `kudo-cassandra/cordon=true` to the pod to evict if the whole node
shouldn't be cordoned. This ensures that the pod, once deleted, won’t be
restarted on the same node. Next, mark the pod for eviction by adding the label
`kudo-cassandra/evict=true`. This will trigger the recovery controller and it
will run the same steps as in failure recovery. As a result, the old pod will be
terminated and rescheduled on a different Kubernetes node.

### Manual node replacement

Cassandra nodes can be replaced manually. This is done by decommissioning a node
and bootstrapping a new one. The KUDO Cassandra operator will take care of the
bootstrapping using the same logic that is used in the failure recovery scenario
mentioned above.

To replace a Cassandra node cordon the Kubernetes node the respective pod is
running on. Manually delete the pod. The pod will be recreated and Kubernetes
will try to redeploy it on the same node because its PVC is still on that node.
Because the node has been cordoned, nothing will be deployed. Delete the PVC
belonging to that pod. Keep in mind that this deletion might also delete the
persistent volume claimed by the PVC. Delete the pod again. The pod will now get
redeployed on a new node and a new PVC will be created on the new node as well.
The new pod will bootstrap a Cassandra node.

## Accessing

See the [document on accessing Cassandra](accessing.md).

## Debugging

Some helpful commands. Assuming `$instance_name` and `$instance_namespace` are
set these should be copy-pastable.

### Plan status

```bash
kubectl kudo plan status deploy \
        --instance="${instance_name}" \
        --namespace="${instance_namespace}"
```

### Get pods

```bash
kubectl get pods -n "${instance_namespace}"
```

### Pod container logs

```bash
pod="0"
container="cassandra" # container can also be "prometheus-exporter"

kubectl logs "${instance_name}-node-${pod}" \
        -n "${instance_namespace}" \
        -c "${container}"
```

### Describe pod

```bash
pod="0"

kubectl describe "pods/${instance_name}-node-${pod}" \
        -n "${instance_namespace}"
```

### Cassandra nodetool status

```bash
pod="0"

kubectl exec "${instance_name}-node-${pod}" \
        -n "${instance_namespace}" \
        -c cassandra \
        -- \
        bash -c "nodetool status"
```

### KUDO controller/manager logs

```bash
kubectl logs kudo-controller-manager-0 \
        -n kudo-system \
        --all-containers
```

### Get endpoints

```bash
kubectl get events \
        --sort-by='{.lastTimestamp}' \
        -n "${instance_namespace}"
```

### Kubernetes events in the instance namespace

```bash
kubectl get events \
        --sort-by='{.lastTimestamp}' \
        -n "${instance_namespace}"
```

## Uninstall an operator instance

This will uninstall the instance and delete all its persistent volume claims
causing **irreversible data loss**.

```bash
wget https://raw.githubusercontent.com/mesosphere/kudo-cassandra-operator/master/scripts/uninstall_operator.sh

chmod +x uninstall_operator.sh

./uninstall_operator.sh \
  --operator cassandra \
  --instance "${instance_name}" \
  --namespace "${instance_namespace}"
```
