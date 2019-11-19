# Managing KUDO Cassandra Operator instances

**Table of Contents**

- [Updating parameters](#updating-parameters)
- [Upgrading](#upgrading)
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

```
kubectl kudo update cassandra \
        --instance analytics-cassandra \
        --namespace production \
        -p SOME_PARAMETER=SOME_VALUE
```

For example, the following command starts a rolling configuration update setting
`cassandra.yaml`'s `hinted_handoff_throttle_in_kb` to `2048` in all of the
cluster nodes'.

```
kubectl kudo update cassandra \
        --instance analytics-cassandra \
        --namespace production \
        -p HINTED_HANDOFF_THROTTLE_IN_KB=2048
```

Multiple parameters can be updated in parallel as well.

```
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

TODO

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

### Uninstall an operator instance

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
