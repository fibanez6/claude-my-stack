# VS Code Dev Container + OpenTelemetry + Grafana Setup

Yes — a `.devcontainer` setup can absolutely run a full local observability stack:

* OpenTelemetry Collector
* Grafana
* Prometheus
* Tempo (distributed traces)
* Loki (logs, optional)
* Your app container

This is a really common local-dev workflow now.

---

# Recommended Stack

| Purpose         | Tool                    |
| --------------- | ----------------------- |
| Metrics         | Prometheus              |
| Traces          | Tempo                   |
| Dashboards      | Grafana                 |
| OTEL ingestion  | OpenTelemetry Collector |
| Logs (optional) | Loki                    |

The OpenTelemetry Collector acts as the central pipeline.

Your app exports:

* OTLP traces
* OTLP metrics
* OTLP logs

Then the collector forwards them.

---

# Folder Structure

```txt
.devcontainer/
  devcontainer.json
  docker-compose.yml
otel/
  otel-collector-config.yaml
prometheus/
  prometheus.yml
grafana/
  provisioning/
app/
```

---

# .devcontainer/devcontainer.json

```json
{
  "name": "otel-dev",
  "dockerComposeFile": "docker-compose.yml",
  "service": "app",
  "workspaceFolder": "/workspace",

  "forwardPorts": [
    3000,
    4317,
    4318,
    9090,
    3200
  ],

  "customizations": {
    "vscode": {
      "extensions": [
        "ms-azuretools.vscode-docker",
        "grafana.vscode-grafana"
      ]
    }
  }
}
```

---

# .devcontainer/docker-compose.yml

```yaml
version: '3.9'

services:
  app:
    image: mcr.microsoft.com/devcontainers/javascript-node:20
    volumes:
      - ..:/workspace:cached
    command: sleep infinity
    environment:
      OTEL_EXPORTER_OTLP_ENDPOINT: http://otel-collector:4318
      OTEL_SERVICE_NAME: my-app
    depends_on:
      - otel-collector

  otel-collector:
    image: otel/opentelemetry-collector-contrib:latest
    command: ["--config=/etc/otelcol/config.yaml"]
    volumes:
      - ../otel/otel-collector-config.yaml:/etc/otelcol/config.yaml
    ports:
      - "4317:4317"
      - "4318:4318"
    depends_on:
      - prometheus
      - tempo

  prometheus:
    image: prom/prometheus:latest
    volumes:
      - ../prometheus/prometheus.yml:/etc/prometheus/prometheus.yml
    ports:
      - "9090:9090"

  tempo:
    image: grafana/tempo:latest
    command: ["-config.file=/etc/tempo.yaml"]
    ports:
      - "3200:3200"

  grafana:
    image: grafana/grafana:latest
    ports:
      - "3000:3000"
    environment:
      GF_SECURITY_ADMIN_USER: admin
      GF_SECURITY_ADMIN_PASSWORD: admin
    depends_on:
      - prometheus
      - tempo
```

---

# otel/otel-collector-config.yaml

```yaml
receivers:
  otlp:
    protocols:
      grpc:
      http:

exporters:
  prometheus:
    endpoint: "0.0.0.0:8889"

  otlp/tempo:
    endpoint: tempo:4317
    tls:
      insecure: true

processors:
  batch:

service:
  pipelines:
    metrics:
      receivers: [otlp]
      processors: [batch]
      exporters: [prometheus]

    traces:
      receivers: [otlp]
      processors: [batch]
      exporters: [otlp/tempo]
```

---

# prometheus/prometheus.yml

```yaml
global:
  scrape_interval: 5s

scrape_configs:
  - job_name: otel-collector
    static_configs:
      - targets: ["otel-collector:8889"]
```

---

# Instrumenting Your App

## Node.js Example

Install:

```bash
npm install @opentelemetry/sdk-node \
  @opentelemetry/auto-instrumentations-node \
  @opentelemetry/exporter-trace-otlp-http
```

Minimal setup:

```js
const { NodeSDK } = require('@opentelemetry/sdk-node');
const { getNodeAutoInstrumentations } = require('@opentelemetry/auto-instrumentations-node');

const sdk = new NodeSDK({
  instrumentations: [getNodeAutoInstrumentations()]
});

sdk.start();
```

---

# Access URLs

| Service    | URL                                            |
| ---------- | ---------------------------------------------- |
| Grafana    | [http://localhost:3000](http://localhost:3000) |
| Prometheus | [http://localhost:9090](http://localhost:9090) |
| Tempo      | [http://localhost:3200](http://localhost:3200) |

Grafana login:

```txt
admin / admin
```

---

# What You Get

Inside Grafana:

* request latency
* traces/spans
* errors
* throughput
* DB queries
* external API timing
* logs correlation

Basically a mini Datadog/New Relic locally.

---

# Nice Upgrades

## Add Loki for logs

```yaml
loki:
  image: grafana/loki:latest
```

Then add an OTEL logs pipeline.

---

## Add Pyroscope for profiling

Grafana now supports:

* CPU profiling
* memory profiling
* flamegraphs

Very useful for backend optimization.

---

# Easiest Alternative

If you want the fastest possible setup:

Use:

```bash
docker run -p 3000:3000 grafana/grafana
```

and use:

```bash
docker run -p 4318:4318 otel/opentelemetry-collector
```

But the full compose stack is much better.

---

# Recommended Modern Architecture

```txt
App
  ↓ OTLP
OpenTelemetry Collector
  ├── Prometheus (metrics)
  ├── Tempo (traces)
  └── Loki (logs)

Grafana
  ├── reads Prometheus
  ├── reads Tempo
  └── reads Loki
```

This is effectively the standard cloud-native observability architecture now.
