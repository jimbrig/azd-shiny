# R Shiny Azure Container Apps Deployment Validation
# This PowerShell script validates the deployment and provides useful information

param(
    [string]$ResourceGroupName,
    [string]$EnvironmentName,
    [switch]$SkipHealthCheck
)

Write-Host "🔍 R Shiny Container Apps Deployment Validation" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

# Check if Azure CLI is available
try {
    $null = Get-Command az -ErrorAction Stop
    Write-Host "✅ Azure CLI found" -ForegroundColor Green
} catch {
    Write-Host "❌ Azure CLI not found. Please install Azure CLI first." -ForegroundColor Red
    exit 1
}

# Check if logged in to Azure
try {
    $account = az account show 2>$null | ConvertFrom-Json
    Write-Host "✅ Logged in to Azure as: $($account.user.name)" -ForegroundColor Green
    Write-Host "📋 Subscription: $($account.name) ($($account.id))" -ForegroundColor Blue
} catch {
    Write-Host "❌ Not logged in to Azure. Please run 'az login' first." -ForegroundColor Red
    exit 1
}

# Get Terraform outputs if resource group not specified
if (-not $ResourceGroupName -or -not $EnvironmentName) {
    Write-Host "📋 Retrieving deployment information from Terraform..." -ForegroundColor Yellow

    if (Test-Path "infra") {
        Push-Location "infra"
        try {
            $containerAppUrl = terraform output -raw container_app_url 2>$null
            $ResourceGroupName = terraform output -raw resource_group_name 2>$null
            $containerRegistryName = terraform output -raw container_registry_name 2>$null
            $keyVaultName = terraform output -raw key_vault_name 2>$null
            $containerAppEnvName = terraform output -raw container_app_environment_name 2>$null
        } catch {
            Write-Host "⚠️  Could not retrieve Terraform outputs. Continuing with manual validation..." -ForegroundColor Yellow
        }
        Pop-Location
    }
}

if (-not $ResourceGroupName) {
    Write-Host "❌ Resource group name not provided and could not be determined from Terraform outputs." -ForegroundColor Red
    Write-Host "Usage: .\validate-deployment.ps1 -ResourceGroupName <rg-name> -EnvironmentName <env-name>" -ForegroundColor Yellow
    exit 1
}

Write-Host "🎯 Validating deployment in resource group: $ResourceGroupName" -ForegroundColor Blue

# Check if resource group exists
try {
    $rg = az group show --name $ResourceGroupName 2>$null | ConvertFrom-Json
    Write-Host "✅ Resource group found: $($rg.name) in $($rg.location)" -ForegroundColor Green
    Write-Host "📍 Provisioning state: $($rg.properties.provisioningState)" -ForegroundColor Blue
} catch {
    Write-Host "❌ Resource group '$ResourceGroupName' not found." -ForegroundColor Red
    exit 1
}

# List all resources in the group
Write-Host "`n📦 Resources in the resource group:" -ForegroundColor Cyan
try {
    $resources = az resource list --resource-group $ResourceGroupName | ConvertFrom-Json
    foreach ($resource in $resources) {
        $status = if ($resource.properties.provisioningState) { $resource.properties.provisioningState } else { "N/A" }
        $statusColor = switch ($status) {
            "Succeeded" { "Green" }
            "Failed" { "Red" }
            "Running" { "Yellow" }
            default { "White" }
        }
        Write-Host "  • $($resource.name) ($($resource.type)) - $status" -ForegroundColor $statusColor
    }
} catch {
    Write-Host "⚠️  Could not list resources." -ForegroundColor Yellow
}

# Check Container App specifically
Write-Host "`n🏗️  Container App Details:" -ForegroundColor Cyan
try {
    $containerApps = az containerapp list --resource-group $ResourceGroupName | ConvertFrom-Json
    foreach ($app in $containerApps) {
        Write-Host "  • Name: $($app.name)" -ForegroundColor White
        Write-Host "  • FQDN: $($app.properties.configuration.ingress.fqdn)" -ForegroundColor White
        Write-Host "  • Status: $($app.properties.runningStatus)" -ForegroundColor $(if ($app.properties.runningStatus -eq "Running") { "Green" } else { "Yellow" })
        Write-Host "  • Replicas: $($app.properties.template.scale.minReplicas)-$($app.properties.template.scale.maxReplicas)" -ForegroundColor White

        if ($app.properties.configuration.ingress.fqdn) {
            $containerAppUrl = "https://$($app.properties.configuration.ingress.fqdn)"
        }
    }
} catch {
    Write-Host "⚠️  Could not retrieve Container App details." -ForegroundColor Yellow
}

# Check Container Registry
Write-Host "`n📦 Container Registry Details:" -ForegroundColor Cyan
try {
    $registries = az acr list --resource-group $ResourceGroupName | ConvertFrom-Json
    foreach ($registry in $registries) {
        Write-Host "  • Name: $($registry.name)" -ForegroundColor White
        Write-Host "  • Login Server: $($registry.loginServer)" -ForegroundColor White
        Write-Host "  • SKU: $($registry.sku.name)" -ForegroundColor White
        Write-Host "  • Admin Enabled: $($registry.adminUserEnabled)" -ForegroundColor White
    }
} catch {
    Write-Host "⚠️  Could not retrieve Container Registry details." -ForegroundColor Yellow
}

# Check Key Vault
Write-Host "`n🔐 Key Vault Details:" -ForegroundColor Cyan
try {
    $keyVaults = az keyvault list --resource-group $ResourceGroupName | ConvertFrom-Json
    foreach ($kv in $keyVaults) {
        Write-Host "  • Name: $($kv.name)" -ForegroundColor White
        Write-Host "  • Vault URI: $($kv.properties.vaultUri)" -ForegroundColor White
        Write-Host "  • RBAC Enabled: $($kv.properties.enableRbacAuthorization)" -ForegroundColor White

        # Try to list secrets (if we have permission)
        try {
            $secrets = az keyvault secret list --vault-name $kv.name 2>$null | ConvertFrom-Json
            Write-Host "  • Secrets: $($secrets.Count) configured" -ForegroundColor White
        } catch {
            Write-Host "  • Secrets: Access denied (normal for RBAC)" -ForegroundColor Yellow
        }
    }
} catch {
    Write-Host "⚠️  Could not retrieve Key Vault details." -ForegroundColor Yellow
}

# Health check
if (-not $SkipHealthCheck -and $containerAppUrl) {
    Write-Host "`n🏥 Performing Health Check:" -ForegroundColor Cyan
    Write-Host "  Target URL: $containerAppUrl" -ForegroundColor White

    try {
        $response = Invoke-WebRequest -Uri $containerAppUrl -Method Get -TimeoutSec 30 -UseBasicParsing
        if ($response.StatusCode -eq 200) {
            Write-Host "✅ Health check passed! Application is responding correctly." -ForegroundColor Green
            Write-Host "🎯 Your R Shiny application is ready at: $containerAppUrl" -ForegroundColor Green
        } else {
            Write-Host "⚠️  Health check returned status code: $($response.StatusCode)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "❌ Health check failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "🔧 The application might still be starting up. Check the logs with:" -ForegroundColor Yellow
        Write-Host "   az containerapp logs show --name <container-app-name> --resource-group $ResourceGroupName" -ForegroundColor Yellow
    }
}

# Summary
Write-Host "`n🎉 Validation Summary:" -ForegroundColor Cyan
Write-Host "=================" -ForegroundColor Cyan
Write-Host "✅ Resource Group: $ResourceGroupName" -ForegroundColor Green
Write-Host "📦 Resources: $($resources.Count) deployed" -ForegroundColor Blue
if ($containerAppUrl) {
    Write-Host "🌐 Application URL: $containerAppUrl" -ForegroundColor Blue
}

Write-Host "`n📚 Next Steps:" -ForegroundColor Cyan
Write-Host "• Test your R Shiny application functionality" -ForegroundColor White
Write-Host "• Configure monitoring and alerts" -ForegroundColor White
Write-Host "• Set up custom domain (if needed)" -ForegroundColor White
Write-Host "• Review security settings and access policies" -ForegroundColor White
Write-Host "• Set up CI/CD pipeline for automated deployments" -ForegroundColor White

Write-Host "`n✅ Validation completed!" -ForegroundColor Green
