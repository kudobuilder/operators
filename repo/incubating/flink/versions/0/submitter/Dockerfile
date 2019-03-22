#kudobuilder/flink-submission:1.7
FROM flink:1.7
COPY --from=bitnami/kubectl:1.13 /opt/bitnami/kubectl/bin/kubectl /usr/local/bin/kubectl

RUN apt-get update && apt-get install  -y jq

ADD submit.sh .

ENTRYPOINT [ "./submit.sh" ]
