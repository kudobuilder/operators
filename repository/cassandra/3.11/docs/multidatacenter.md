# KUDO Cassandra with Multiple Datacenters and Rack awareness

This guide explains the details of a multi-datacenter setup for KUDO Cassandra

## Description

Cassandra supports different topologies, including different datacenters and
rack awareness.

- Different datacenters usually provide complete replication and locality. Each
  datacenter usually contains a separate 'ring'
- Different racks indicate different failure zones to Cassandra: Data is
  replicated in a way that different copies are not stored in the same rack.

## Kubernetes cluster prerequisites

### Naming

In a multi-datacenter setup, a Cassandra cluster is formed by combining multiple
Cassandra datacenters. Cassandra datacenters can either run in a single
Kubernetes cluster that is spanning multiple physical datacenters, or in
multiple Kubernetes clusters, each one in a different physical datacenter. All
instances of Cassandra have to have the same name. This is achieved by using the
same instance name or by setting the `OVERRIDE_CLUSTER_NAME` parameter.

### Node labels

- Datacenter labels: Each Kubernetes node must have appropriate labels
  indicating the datacenter it belongs to. These labels can have any name, but
  it is advised to use the standard
  [Kubernetes topology labels](https://kubernetes.io/docs/reference/kubernetes-api/labels-annotations-taints/#topologykubernetesioregion).

If the Kubernets cluster is running on AWS, these labels are usually set by
default, on AWS they correspond to the different regions:

```yaml
topology.kubernetes.io/region=us-east-1
```

As datacenter selection is configured on datacenter level for cassandra, it is
possible to use different keys for each datacenter. This might be especially
useful for hybrid clouds. For example, this would be an valid configuration:

```yaml
Datacenter 1 (OnPrem):
nodeLabels:
  custom.topology=onprem

Datacenter 2 (AWS):
nodeLabels:
  topology.kubernetes.io/region=us-east-1
```

- Rack labels: Additionally to the datacenter label, each kubernetes node must
  have a rack label. This label defines how Cassandra distributes data in each
  datacenter, and can correspond to AWS availability zones, actual rack names in
  a datacenter, power groups, etc.

Again, it is advised to use the
[Kubernetes topology labels](https://kubernetes.io/docs/reference/kubernetes-api/labels-annotations-taints/#topologykubernetesioregion),
for example on AWS a label would look like:

```yaml
topology.kubernetes.io/zone=us-east-1c
```

The label key is again defined on datacenter level and therefore they key needs
to be the same for all nodes used in the same datacenter.

### Service Account

As there is currently no easy way to read node labels from inside a pod, the
KUDO Cassandra operator uses an initContainer to read the rack of the deployed
pod. This requires a service account with valid RBAC permissions. KUDO Cassandra
provides an easy way to automatically create this service account for you:

```text
SERVICE_ACCOUNT_INSTALL=true
```

If this parameter is enabled, the operator will create a service account,
cluster role and cluster role binding. It uses the `NODE_RESOLVE_SERVICEACCOUNT`
parameter as the name for the service account and derived names for the cluster
role and cluster role binding. The created cluster role has the permissions to
`get`, `watch` and `list` the `nodes` resource.

If you prefer to manage this manually, please follow the
[Kubernetes documentation](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/)
on how to create service accounts and set `NODE_RESOLVE_SERVICEACCOUNT` to the
name of the created service account.

## Topology

KUDO Cassandra supports the cluster setup with a single `NODE_TOPOLOGY`
parameter. This parameter contains a YAML structure that describes the expected
setup.

An example:

```yaml
- datacenter: dc1
  datacenterLabels:
    failure-domain.beta.kubernetes.io/region: us-west-2
  nodes: 9
  rackLabelKey: failure-domain.beta.kubernetes.io/zone
  racks:
    - rack: rack1
      rackLabelValue: us-west-2a
    - rack: rack2
      rackLabelValue: us-west-2b
    - rack: rack3
      rackLabelValue: us-west-2c
- datacenter: dc2
  datacenterLabels:
    failure-domain.beta.kubernetes.io/region: us-east-1
  nodes: 9
  rackLabelKey: failure-domain.beta.kubernetes.io/zone
  racks:
    - rack: rack4
      rackLabelValue: us-east-1a
    - rack: rack5
      rackLabelValue: us-east-1b
    - rack: rack6
      rackLabelValue: us-east-1c
```

This deployment requires a kubernetes cluster of at least 18 worker nodes, with
at least 9 in each `us-west-2` and `us-east1` region.

It will deploy two StatefulSets with each 9 pods. Each StatefulSet creates it's
own ring, the replication factor between the datacenters can be specified on the
keyspace level inside cassandra.

It is _not_ possible to exactly specify how many pods will be started on each
rack at the moment - the KUDO Cassandra operator and Kubernetes will distribute
the Cassandra nodes over all specified racks by availability and with the most
possible spread:

For example, if we use the above example, and the nodes in the `us-west-2`
region are:

- 5x `us-west-2a`
- 5x `us-west-2b`
- 5x `us-west-2c`

The operator would deploy 3 cassandra nodes in each availability zone.

If the nodes were:

- 1x `us-west-2a`
- 10x `us-west-2b`
- 15x `us-west-2c`

Then the cassandra node distribution would probably end up similar to this:

- 1x `us-west-2a`
- 4x `us-west-2b`
- 4x `us-west-2c`

## Adding instances running in other Kubernetes clusters

Datacenters can also span multiple Kubernetes clusters. To let an instance know
about a datacenter running in another Kubernetes cluster, the
`EXTERNAL_SEED_NODES` parameter has to be set. This parameter takes an array of
DNS names or IP addresses that seed nodes outside of the cluster have. The
clusters have to be set up so that the pods running Cassandra nodes can
communicate with each other. Futhermore, the cluster names have to be the same
across all datacenters. This is achieved by using the same instance name or
setting the `OVERRIDE_CLUSTER_NAME` parameter across all datacenters.

For example, if we have a Kubernetes cluster in the `us-west-2` region with 5
nodes. When starting a new Cassandra instance on a Kubernetes cluster in the
`us-east-2` region, we set `EXTERNAL_SEED_NODES` to the seed nodes of the
cluster in `us-west-2`

```yaml
EXTERNAL_SEED_NODES:
  [
    <DNS of first seed node>,
    <DNS of second seed node>,
    <DNS of third seed node>,
  ]
```

Once the Cassandra instance in `us-east-2` has been deployed, the Cassandra
instances in `us-west-2` has to be updated to learn about the seed nodes of the
cluster in `us-east2`. Once that is done, both datacenters are replicating with
each other.

## Other parameters

### Endpoint Snitch

To let cassandra know about the topology, a different Snitch needs to be set:

```text
ENDPOINT_SNITCH=GossipingPropertyFileSnitch
```

The GossipingPropertyFileSnitch lets cassandra read the datacenter and rack
information from a local file which the operator generates from the
`NODE_TOPOLOGY`.

### Node Anti-Affinity

This prefents the cluster to schedule two cassandra nodes on to the same
Kubernetes node.

```text
NODE_ANTI_AFFINITY=true
```

If this feature is enabled, you _must_ have at least that many Kubernetes nodes
in your cluster as you use in the NODE_TOPOLOGY definition.

### Full list of required parameters

```text
ENDPOINT_SNITCH=GossipingPropertyFileSnitch
NODE_ANTI_AFFINITY=true
NODE_TOPOLOGY=<the cluster topology>
```
