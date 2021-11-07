# Confluent Schema Registry

Confluent Schema Registry provides a serving layer for your metadata. It provides a RESTful interface for storing and retrieving Apache Avro® schemas. It stores a versioned history of all schemas based on a specified subject name strategy, provides multiple compatibility settings and allows evolution of schemas according to the configured compatibility settings and expanded Avro support. It provides serializers that plug into Apache Kafka® clients that handle schema storage and retrieval for Kafka messages that are sent in the Avro format.

Source: [Confluent at GitHub](https://github.com/confluentinc/schema-registry)
DockerFile: [Schema Registry 5.3.2](https://github.com/confluentinc/cp-docker-images/blob/v5.3.2/debian/schema-registry/Dockerfile)

## Documentation

- [Custom Configuration](./docs/v1.0/runbook_custom_configuration.md)
- [Security](./docs/v1.0/security.md)