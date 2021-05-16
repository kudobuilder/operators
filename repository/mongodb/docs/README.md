# MongoDB

MongoDB is a free and open-source cross-platform document-oriented database program.

This Operator deploy a MongoDB Community Edition, see [MongoDB](https://hub.docker.com/_/mongo/), with standalone mode.

## Prerequisites

You need a Kubernetes cluster up and running and Persistent Storage available with a default `Storage Class` defined.

## Getting Started

Deploy the `Operator` using the following command:

`kubectl kudo install mongodb`

It deploys a MongoDB StatefulSet composed of 1 instances.
