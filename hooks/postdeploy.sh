#!/bin/bash

# Azure Developer CLI Post-deployment Hook
# This script runs after the infrastructure deployment

echo "🎉 Starting post-deployment validation for R Shiny Container Apps..."

# Get the container app URL from Terraform outputs
echo "📋 Retrieving deployment information..."

cd infra

# Get outputs from Terraform
CONTAINER_APP_URL=$(terraform output -raw container_app_url 2>/dev/null)
RESOURCE_GROUP=$(terraform output -raw resource_group_name 2>/dev/null)
CONTAINER_APP_NAME=$(terraform output -raw container_app_environment_name 2>/dev/null)

cd ..

if [ -z "$CONTAINER_APP_URL" ]; then
    echo "⚠️  Could not retrieve container app URL from Terraform outputs"
else
    echo "🌐 Container App URL: $CONTAINER_APP_URL"
fi

if [ -n "$RESOURCE_GROUP" ]; then
    echo "📦 Resource Group: $RESOURCE_GROUP"

    # Check resource deployment status
    echo "🔍 Checking resource deployment status..."
    az group show --name "$RESOURCE_GROUP" --query "properties.provisioningState" -o tsv

    # List all resources in the group
    echo "📋 Resources deployed:"
    az resource list --resource-group "$RESOURCE_GROUP" --query "[].{Name:name, Type:type, Status:properties.provisioningState}" -o table
fi

# Health check
if [ -n "$CONTAINER_APP_URL" ]; then
    echo "🏥 Performing health check..."

    # Wait a bit for the container to start
    echo "⏳ Waiting 30 seconds for container to initialize..."
    sleep 30

    # Try to access the application
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$CONTAINER_APP_URL" --max-time 30)

    if [ "$HTTP_STATUS" = "200" ]; then
        echo "✅ Health check passed! Application is responding correctly."
        echo "🎯 Your R Shiny application is ready at: $CONTAINER_APP_URL"
    else
        echo "⚠️  Health check returned HTTP status: $HTTP_STATUS"
        echo "🔧 The application might still be starting up. Check the logs with:"
        echo "   az containerapp logs show --name <container-app-name> --resource-group $RESOURCE_GROUP"
    fi
fi

echo ""
echo "🚀 Deployment Summary:"
echo "✅ Infrastructure deployed successfully"
echo "📱 Application: R Shiny Web App"
echo "🏗️  Platform: Azure Container Apps"
echo "🔧 Infrastructure: Terraform"
echo ""

if [ -n "$CONTAINER_APP_URL" ]; then
    echo "🌐 Access your application at: $CONTAINER_APP_URL"
else
    echo "📋 Use 'terraform output' in the infra/ directory to get deployment details"
fi

echo ""
echo "📚 Next steps:"
echo "1. Test your R Shiny application"
echo "2. Configure custom domain (if needed)"
echo "3. Set up monitoring and alerts"
echo "4. Review security settings"
echo ""
echo "✅ Post-deployment validation completed!"
