#!/bin/bash

# Azure Developer CLI Pre-deployment Hook
# This script runs before the infrastructure deployment

echo "🚀 Starting pre-deployment setup for R Shiny Container Apps..."

# Check if required tools are installed
echo "📋 Checking prerequisites..."

# Check Azure CLI
if ! command -v az &> /dev/null; then
    echo "❌ Azure CLI is not installed. Please install it first."
    exit 1
fi
echo "✅ Azure CLI found"

# Check if logged in to Azure
if ! az account show &> /dev/null; then
    echo "❌ Not logged in to Azure. Please run 'az login' first."
    exit 1
fi
echo "✅ Azure authentication verified"

# Check Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install it first."
    exit 1
fi
echo "✅ Docker found"

# Check Terraform
if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform is not installed. Please install it first."
    exit 1
fi
echo "✅ Terraform found"

echo "✅ All prerequisites check passed!"

# Validate Terraform configuration
echo "🔍 Validating Terraform configuration..."
cd infra
terraform init -backend=false
terraform validate

if [ $? -eq 0 ]; then
    echo "✅ Terraform configuration is valid"
else
    echo "❌ Terraform configuration validation failed"
    exit 1
fi

cd ..

echo "✅ Pre-deployment setup completed successfully!"
