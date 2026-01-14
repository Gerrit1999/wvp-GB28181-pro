#!/bin/sh
set -eu

mkdir -p /opt/ylcx /opt/ylcx/wvp /opt/wvp

JAVA_OPTS="${JAVA_OPTS:--Xms512m -Xmx1024m -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/opt/ylcx/}"
SPRING_CONFIG_LOCATION="${SPRING_CONFIG_LOCATION:---spring.config.location=/opt/ylcx/wvp/application.yml}"

# Run backend in background; nginx stays in foreground (PID 1).
# Explicitly forward stdout/stderr to container logs.
# shellcheck disable=SC2086
java ${JAVA_OPTS} -jar /opt/wvp/wvp.jar ${SPRING_CONFIG_LOCATION} >>/proc/1/fd/1 2>>/proc/1/fd/2 &

