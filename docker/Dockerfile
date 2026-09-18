FROM python:3.12-slim

ENV TZ=Etc/UTC
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install --yes --no-install-recommends \
        anacron=2.3-43 \
        cron=3.0pl1-197 \
        curl=8.14.1-2+deb13u5 \
        jq=1.7.1-6+deb13u3 \
        util-linux=2.41.5-0+deb13u1 \
        iproute2=6.15.0-1 \
    && rm -rf /var/lib/apt/lists/* /var/cache/debconf \
    && apt-get clean

RUN mkfifo --mode 0666 /var/log/cron.log

WORKDIR /
COPY --chmod=0755 docker/entrypoint.sh ./

WORKDIR /app/metrics
COPY docker/metrics.prom  ./

WORKDIR /app
COPY --chmod=0755  docker/app.sh /docker/exporter.py ./

CMD ["/bin/sh", "/entrypoint.sh"]
