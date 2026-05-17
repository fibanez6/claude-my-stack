#!/usr/bin/env bash

export CLAUDE_CODE_ENABLE_TELEMETRY=1
export OTEL_METRICS_EXPORTER=otlp
export OTEL_LOGS_EXPORTER=otlp
export OTEL_TRACES_EXPORTER=otlp

export OTEL_EXPORTER_OTLP_ENDPOINT=https://otel.company.internal:4317
export OTEL_EXPORTER_OTLP_HEADERS="Authorization=Bearer COMPANY_TOKEN"

exec claude "$@"