# Azure Developer CLI Template for R Shiny Web Apps

This repository contains a comprehensive **Azure Developer CLI** (azd) template for deploying R Shiny applications to Azure using **Azure Container Apps** and **Terraform** as Infrastructure as Code.

## 🚀 Features

- **Production-Ready Infrastructure**: Azure Container Apps with auto-scaling
- **Security First**: Managed identities, Key Vault integration, RBAC
- **Modern Architecture**: Containerized deployment with private container registry
- **Monitoring**: Integrated logging with Log Analytics
- **IaC**: Complete Terraform infrastructure setup
- **Automated Deployment**: One-command deployment with azd

## 🏗️ Architecture

The template deploys the following Azure resources:

- **Azure Container Apps**: Serverless container hosting
- **Azure Container Registry**: Private Docker registry
- **Azure Key Vault**: Secure secret management
- **Log Analytics Workspace**: Centralized logging
- **Managed Identity**: Secure service-to-service authentication
- **RBAC Assignments**: Least privilege access control

## 🎯 Quick Start

### Prerequisites

- [Azure Developer CLI (azd)](https://aka.ms/azd-install)
- [Terraform](https://aka.ms/azure-dev/terraform-install) (>= 1.3.0)
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- [Docker](https://docs.docker.com/get-docker/)

### Deploy to Azure

1. **Initialize the template**:
   ```bash
   azd init --template <repository-url>
   cd <your-project-name>
   ```

2. **Configure variables** (optional):
   ```bash
   cp infra/terraform.tfvars.example infra/terraform.tfvars
   # Edit terraform.tfvars with your preferred settings
   ```

3. **Deploy everything**:
   ```bash
   azd up
   ```

4. **Access your app**:
   After deployment, azd will output the URL of your running R Shiny application.

## 📁 Project Structure

```
├── src/                    # R Shiny application source
│   ├── app.R              # Enhanced R Shiny app with Azure features
│   └── Dockerfile         # Production-ready container definition
├── infra/                 # Terraform infrastructure
│   ├── main.tf           # Main infrastructure resources
│   ├── variables.tf      # Input variables
│   ├── outputs.tf        # Output values
│   ├── provider.tf       # Terraform providers
│   ├── terraform.tfvars.example  # Example configuration
│   └── README.md         # Infrastructure documentation
├── hooks/                 # Deployment hooks
│   ├── predeploy.sh      # Pre-deployment validation
│   └── postdeploy.sh     # Post-deployment verification
├── azure.yaml            # azd configuration
└── README.md             # This file
```

## 🔧 Configuration

### Environment Variables

The R Shiny application can access these environment variables:

- `PORT`: Application port (default: 3838)
- `APP_SECRET`: Application secret from Key Vault

### Terraform Variables

Configure these in `infra/terraform.tfvars`:

| Variable | Description | Default |
|----------|-------------|---------|
| `location` | Azure region | - |
| `environment_name` | Resource name prefix | - |
| `image_name` | Container image name | `shinyapp` |
| `app_secret_value` | Application secret | `default-secret-value` |
| `min_replicas` | Minimum container instances | `1` |
| `max_replicas` | Maximum container instances | `3` |

## 🔐 Security Features

- **No hardcoded credentials**: Uses managed identities
- **Private container registry**: Secure image storage
- **Key Vault integration**: Encrypted secret management
- **RBAC**: Role-based access control
- **HTTPS only**: Automatic TLS termination
- **Non-root containers**: Enhanced security

## 📊 Monitoring & Logging

- **Container logs**: Automatically sent to Log Analytics
- **Health checks**: Built-in container health monitoring
- **Azure Monitor**: Ready for alerts and dashboards
- **Application insights**: Can be easily added

## 🔄 Development Workflow

1. **Modify your R Shiny app** in `src/app.R`
2. **Test locally** with Docker:
   ```bash
   cd src
   docker build -t my-shiny-app .
   docker run -p 3838:3838 my-shiny-app
   ```
3. **Deploy changes**:
   ```bash
   azd deploy
   ```

## 🛠️ Advanced Usage

### Custom R Packages

Add package installations to `src/Dockerfile`:

```dockerfile
RUN R -e "install.packages(c('plotly', 'dplyr'), repos='https://cran.rstudio.com/')"
```

### Scaling Configuration

Modify scaling in `infra/terraform.tfvars`:

```hcl
min_replicas = 2
max_replicas = 10
```

### Additional Secrets

Add more secrets in `infra/main.tf`:

```hcl
resource "azurerm_key_vault_secret" "additional_secret" {
  name         = "another-secret"
  value        = var.another_secret_value
  key_vault_id = azurerm_key_vault.kv.id
}
```

## 🚨 Troubleshooting

### Common Issues

1. **Container fails to start**:
   ```bash
   az containerapp logs show --name <app-name> --resource-group <rg-name>
   ```

2. **Authentication errors**:
   Check managed identity role assignments in Azure Portal

3. **Build failures**:
   Verify Dockerfile syntax and R package dependencies

### Useful Commands

```bash
# View deployment status
azd show

# Check container app status
az containerapp show --name <app-name> --resource-group <rg-name>

# View logs
azd logs

# Redeploy application only
azd deploy

# Destroy all resources
azd down
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test the deployment
5. Submit a pull request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- [Azure Developer CLI Documentation](https://docs.microsoft.com/en-us/azure/developer/azure-developer-cli/)
- [Azure Container Apps Documentation](https://docs.microsoft.com/en-us/azure/container-apps/)
- [R Shiny Documentation](https://shiny.posit.co/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
