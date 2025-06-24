FROM python:3.9-slim

ENV TZ=Etc/UTC
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install --yes --no-install-recommends \
        anacron=2.3-36 \
        cron=3.0pl1-162 \
        curl=7.88.1-10+deb12u12 \
        jq=1.6-2.1 \
        util-linux=2.38.1-5+deb12u3 \
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
