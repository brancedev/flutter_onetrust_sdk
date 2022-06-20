FROM docker.onetrust.dev/python-3.7-ubuntu:lts

COPY . /

RUN apt-get update && \
    apt-get install apt-transport-https && \
    curl https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - && \
    curl https://storage.googleapis.com/download.dartlang.org/linux/debian/dart_stable.list > /etc/apt/sources.list.d/dart_stable.list && \
    apt-get update && \
    apt-get install dart && \
    apt-get clean;

USER root
RUN apt-get update && apt-get install -y --no-install-recommends wget git ca-certificates

VOLUME /mobnativesdkflutter/output
WORKDIR /mobnativesdkflutter

CMD ["/bin/sh", "-c"]
