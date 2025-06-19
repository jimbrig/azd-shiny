# azd-shiny

This repository contains an **Azure Developer CLI** (azd) template for deploying a simple [R Shiny](https://shiny.posit.co/) application to Azure using **Terraform**.

## Quickstart

Ensure you have the [Azure Developer CLI](https://aka.ms/azd-install) and [Terraform](https://aka.ms/azure-dev/terraform-install) installed. Then run:

```bash
azd init --template <repository-url>
azd up
```

After provisioning, `azd` will output the URL of the running Shiny app.

## Template Structure

- `src/` – sample Shiny app and Dockerfile
- `infra/` – Terraform infrastructure for Azure resources
- `azure.yaml` – configuration for azd

Replace the sample app in `src/app.R` with your own Shiny code.
