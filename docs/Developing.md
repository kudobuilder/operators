# Developing an Operator with KUDO

## Running tests

If you do not have a Kubernetes cluster, then start one with KIND:

```
make create-cluster
```

Now, run the tests:

```
make test
```

Or if you already have a Kubernetes cluster:

```
make USE_KIND=0 test
```
