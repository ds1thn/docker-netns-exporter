#!/bin/bash

printenv | awk -F= '{print "export " "\""$1"\"""=""\""$2"\"" }'  > /app/env.sh

echo "$CRON root /bin/bash /app/app.sh 2>&1"  > /etc/cron.d/hello-cron

cron
python -u /app/exporter.py
tail -f /var/log/cron.log
