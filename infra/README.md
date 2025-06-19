# R Shiny Azure Container Apps Infrastructure

This Terraform configuration deploys a production-ready R Shiny web application on Azure using Container Apps.

## Architecture Overview

The infrastructure includes:

- **Resource Group**: Container for all resources
- **Container Registry**: Stores the Docker images for the R Shiny app
- **Key Vault**: Securely stores application secrets and configuration
- **Log Analytics Workspace**: Centralized logging for Container Apps
- **Container Apps Environment**: Managed environment for container apps
- **Container App**: Hosts the R Shiny application
- **Managed Identity**: Secure authentication between services
- **RBAC Assignments**: Least privilege access control

## Security Features

- **Managed Identity**: No hardcoded credentials
- **Key Vault Integration**: Secure secret management
- **RBAC**: Role-based access control with least privilege
- **Container Registry**: Private registry with managed identity authentication
- **HTTPS Only**: Secure communication with automatic TLS termination

## Scaling and Performance

- **Auto-scaling**: Configurable min/max replicas
- **Resource Limits**: CPU and memory allocation
- **Health Monitoring**: Integrated with Azure Monitor

## Deployment

### Prerequisites

1. Azure CLI installed and authenticated
2. Azure Developer CLI (azd) installed
3. Terraform installed (>= 1.3.0)
4. Docker for building container images

### Quick Start

1. Clone this repository
2. Copy the example variables file:
   ```bash
   cp infra/terraform.tfvars.example infra/terraform.tfvars
   ```
3. Edit `infra/terraform.tfvars` with your values
4. Deploy using azd:
   ```bash
   azd up
   ```

### Manual Terraform Deployment

If you prefer to use Terraform directly:

```bash
cd infra
terraform init
terraform validate
terraform plan
terraform apply
```

### Environment Variables

The following variables can be configured in `terraform.tfvars`:

- `location`: Azure region for deployment
- `environment_name`: Prefix for resource names
- `image_name`: Container image name
- `app_secret_value`: Application secret (store securely)
- `min_replicas`: Minimum container instances
- `max_replicas`: Maximum container instances

## R Shiny Application Configuration

Your R Shiny application should:

1. Listen on port 3838
2. Handle the `PORT` environment variable
3. Use the `APP_SECRET` environment variable for configuration

Example R Shiny server configuration:

```r
# server.R or app.R
library(shiny)

# Get configuration from environment
port <- as.numeric(Sys.getenv("PORT", "3838"))
app_secret <- Sys.getenv("APP_SECRET", "")

# Your Shiny app code here...

# Run the application
shiny::runApp(host = "0.0.0.0", port = port)
```

## Monitoring and Logging

- Container logs are automatically sent to Log Analytics
- Application Insights can be added for detailed telemetry
- Use Azure Monitor for alerts and dashboards

## Cost Optimization

The current configuration uses:
- Basic SKU for Container Registry (upgrade to Standard/Premium for production)
- Consumption-based pricing for Container Apps
- Standard SKU for Key Vault

## Security Considerations

1. Rotate the `app_secret_value` regularly
2. Enable Azure Defender for container registries in production
3. Consider using Azure Key Vault references for all secrets
4. Review and audit RBAC assignments regularly
5. Enable diagnostic settings for all resources

## Troubleshooting

### Common Issues

1. **Container fails to start**: Check the Dockerfile and ensure port 3838 is exposed
2. **Authentication errors**: Verify managed identity role assignments
3. **Image pull errors**: Ensure Container Registry permissions are correct

### Useful Commands

```bash
# View container app logs
az containerapp logs show --name <app-name> --resource-group <rg-name>

# Check container app status
az containerapp show --name <app-name> --resource-group <rg-name>

# View Key Vault secrets (requires permissions)
az keyvault secret list --vault-name <kv-name>
```

## Contributing

When modifying the infrastructure:

1. Follow Terraform best practices
2. Update variable descriptions and examples
3. Test changes in a development environment
4. Update this README with any new features or requirements
