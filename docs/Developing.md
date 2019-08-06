# Developing an Operator with KUDO

## Running tests

If you do not have the kudo CLI installed already, the Makefile will download it:

```
make test
```

Otherwise, just run:

```
kubectl kudo test
```

By default, the tests will run inside of a kind cluster. If you want to test on a different cluster, just disable kind:

```
kubectl kudo test --start-kind=false
```

Please see the [testing documentation](https://kudo.dev/docs/testing/) or reach out to us on the KUDO slack channel if you have any questions.
