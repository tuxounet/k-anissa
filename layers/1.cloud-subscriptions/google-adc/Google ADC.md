# Google Application Default Credentials (ADC)

## Purpose

This layer authenticates the local workstation with Google Cloud using
[Application Default Credentials](https://cloud.google.com/docs/authentication/provide-credentials-adc).
It runs `gcloud auth application-default login`, then copies the resulting JSON
credentials file to a shared data directory so that other workloads (containers,
LiteLLM proxy, etc.) can mount it read-only.

## Prerequisites

| Requirement   | Notes                                                      |
| ------------- | ---------------------------------------------------------- |
| `gcloud` CLI  | [Install guide](https://cloud.google.com/sdk/docs/install) |
| A GCP project | With Vertex AI API enabled                                 |
| A browser     | The login flow opens a browser window                      |

## Usage

```bash
# Authenticate and write the credentials file
make up

# Remove local credentials and revoke ADC
make down
```

## Exported artefact

After `make up`, the ADC JSON file is available at:

```
${KANISSA_DATA:-.data}/google-adc/application_default_credentials.json
```

### Mounting in Docker Compose workloads

```yaml
services:
  my-service:
    volumes:
      - ${KANISSA_DATA:-.data}/google-adc/application_default_credentials.json:/root/.config/gcloud/application_default_credentials.json:ro
    environment:
      - GOOGLE_APPLICATION_CREDENTIALS=/root/.config/gcloud/application_default_credentials.json
```

This allows any container to use GCP APIs (Vertex AI, GCS, BigQuery, etc.)
without embedding long-lived service-account keys.
