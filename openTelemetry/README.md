# Claude Telemetry (OpenTelemetry) Integration Guide

This guide explains how to use the `claude-telemetry.sh` script for monitoring Claude Code usage via OpenTelemetry (OTel) on macOS and Linux, how to replace the original script, configure settings, and integrate with VS Code devcontainers.

![Status line](../../docs/images/openTelemetry/openTelemetry_grafana-dashboard.png)

---

## 1. Quick Start: Enable Telemetry

1. **Enable telemetry:**
   ```sh
   export CLAUDE_CODE_ENABLE_TELEMETRY=1
   ```
2. **Choose exporters (optional):**
   ```sh
   export OTEL_METRICS_EXPORTER=otlp       # otlp, prometheus, console, none
   export OTEL_LOGS_EXPORTER=otlp          # otlp, console, none
   ```
3. **Configure OTLP endpoint (for OTLP exporter):**
   ```sh
   export OTEL_EXPORTER_OTLP_PROTOCOL=grpc
   export OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317
   ```
4. **Set authentication (if required):**
   ```sh
   export OTEL_EXPORTER_OTLP_HEADERS="Authorization=Bearer your-token"
   ```
5. **(Optional) Debugging:**
   ```sh
   export OTEL_METRIC_EXPORT_INTERVAL=10000  # 10s (default: 60000ms)
   export OTEL_LOGS_EXPORT_INTERVAL=5000     # 5s (default: 5000ms)
   ```
6. **Run Claude Code:**
   ```sh
   claude
   ```

For more, see the [official monitoring docs](https://code.claude.com/docs/en/monitoring-usage).

---

## 2. Using `claude-telemetry.sh` on macOS & Linux

- Place `claude-telemetry.sh` in your `PATH` or reference it directly.
- Make it executable:
  ```sh
  chmod +x /path/to/claude-telemetry.sh
  ```
- Replace the original telemetry script by updating any references (e.g., in your launch scripts or settings) to point to `claude-telemetry.sh`.
- The script should output valid JSON headers if used as a dynamic headers helper (see below).

---

## 3. Reference: Dynamic Headers Helper

To use a script for dynamic OTLP headers (token refresh, etc.), add to your `.claude/settings.json`:

```json
{
  "otelHeadersHelper": "/absolute/path/to/claude-telemetry.sh"
}
```

The script must output JSON key-value pairs for HTTP headers, e.g.:
```sh
#!/bin/bash
echo '{"Authorization": "Bearer $(get-token.sh)"}'
```

---

## 4. Example: Managed Settings (`settings.json`)

You can centrally configure telemetry via a managed settings file:

```json
{
  "env": {
    "CLAUDE_CODE_ENABLE_TELEMETRY": "1",
    "OTEL_SERVICE_NAME": "bedrock-cost-dashboard",
    "OTEL_METRICS_EXPORTER": "otlp",
    "OTEL_LOGS_EXPORTER": "otlp",
    "OTEL_EXPORTER_OTLP_PROTOCOL": "grpc",
    "OTEL_EXPORTER_OTLP_ENDPOINT": "http://localhost:4317",
    "OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE": "cumulative",
    "OTEL_METRIC_EXPORT_INTERVAL": "10000"
  }
}
```

See [settings precedence](https://code.claude.com/docs/en/settings#settings-precedence) for details.


---

## 6. Additional Resources

- [Claude Code Monitoring Docs](https://code.claude.com/docs/en/monitoring-usage)
- [OpenTelemetry Spec](https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/protocol/exporter.md#configuration-options)
- [Claude Code ROI Measurement Guide](https://github.com/anthropics/claude-code-monitoring-guide)

---

**Note:**
- For advanced configuration (tracing, mTLS, multi-team, etc.), see the [full documentation](https://code.claude.com/docs/en/monitoring-usage).
- Environment variables in managed settings cannot be overridden by users.
- For dynamic headers, use the `otelHeadersHelper` setting as shown above.
