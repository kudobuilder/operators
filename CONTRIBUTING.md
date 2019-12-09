# Contributing Guidelines

The KUDO Operators project accepts contributions via GitHub pull requests. This document outlines the process to help get your contribution accepted.

## Sign the CLA

Kubernetes projects require that you sign a Contributor License Agreement (CLA) before we can accept your pull requests.

Please see https://git.k8s.io/community/CLA.md for more info.

## How to Contribute to an Existing Operator

1. Submit an issue describing your proposed change to the operator in question.
2. The operator maintainer or repo owners will respond  to your issue promptly
3. If your proposed change is accepted, and you haven't already done so, sign a Contributor License Agreement (see details above).
4. Fork the desired repo, develop and test your code changes.
5. Submit a pull request.

### Requirements for the new Operators

- Must include a `README.md`
- Must include source GitHub repositories for images used in the Operator
- Must pass the `kubectl kudo package verify` 
- Must specify the minimum `KUDO` version and `Kubernetes` version in `operator.yaml`
- Must provide tests for the Operator
- Must follow the structure described in [getting started guide](https://kudo.dev/docs/developing-operators.html#getting-started)
- Each file in `templates` directory must be of one Kubernetes object type
- Should follow Kubernetes best practices
- Should support Operator upgrades
- Should provide a sane default configuration

### Release Process

Release process will be automated in upcoming iterations. Right now there are two ways to manually trigger the release process

- Submit an issue describing which operator has to be released
- Use the [KUDO Slack](https://kubernetes.slack.com/messages/kudo/) channel to ask the owners of the repository to release an operator

### Reporting an issue in KUDO

This repository is used by KUDO Operator developers. If your issue is in the KUDO itself, please use the issue tracker in the [kudobuilder/kudo](https://github.com/kudobuilder/kudo) repository.

## Community, Discussion, and Support

Learn how to engage with the KUDO community on the [community page](https://kudo.dev/community/).

You can reach the maintainers of this project at:

- [Slack](https://kubernetes.slack.com/messages/kudo/)
- [Mailing List](https://groups.google.com/d/forum/kudobuilder)

## Code of Conduct

Participation in the Kubernetes community is governed by the [Kubernetes Code of Conduct](https://github.com/kudobuilder/kudo/blob/master/code-of-conduct.md).