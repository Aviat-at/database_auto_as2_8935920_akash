#!/bin/bash

# Set variables
RESOURCE_GROUP="8935920" 
MYSQL_SERVER_NAME="companydb$RANDOM"
MYSQL_LOCATION="eastus"
MYSQL_ADMIN="root"
MYSQL_PASSWORD="YourSecurePassword123!"
MYSQL_SKU="B_Gen5_1"  
MYSQL_STORAGE=32
FIREWALL_RULE_NAME="AllowAll"

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

echo "🚀 Deploying Azure MySQL Single Server: $MYSQL_SERVER_NAME..."
az mysql server create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$MYSQL_SERVER_NAME" \
  --location "$MYSQL_LOCATION" \
  --admin-user "$MYSQL_ADMIN" \
  --admin-password "$MYSQL_PASSWORD" \
  --sku-name "$MYSQL_SKU" \
  --storage-size "$MYSQL_STORAGE" --output none

# Verify MySQL deployment success
MYSQL_HOST=$(az mysql server show --resource-group "$RESOURCE_GROUP" --name "$MYSQL_SERVER_NAME" --query "fullyQualifiedDomainName" --output tsv)

if [ -z "$MYSQL_HOST" ]; then
    echo "❌ ERROR: MySQL deployment failed. Exiting..."
    exit 1
fi

echo "✅ MySQL Server Deployed Successfully!"
echo "🔹 Hostname: $MYSQL_HOST"
echo "🔹 Admin User: $MYSQL_ADMIN@$MYSQL_SERVER_NAME"
echo "🔹 Password: $MYSQL_PASSWORD"
echo "🔹 Region: $MYSQL_LOCATION"
echo "🔹 Storage Size: ${MYSQL_STORAGE}GB"

# Configure firewall rule to allow access from all IPs
echo "🔹 Configuring firewall rule: $FIREWALL_RULE_NAME..."
az mysql server firewall-rule create \
  --resource-group "$RESOURCE_GROUP" \
  --server-name "$MYSQL_SERVER_NAME" \
  --name "$FIREWALL_RULE_NAME" \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 255.255.255.255 --output none

echo "✅ Firewall rule configured successfully."

# Install MySQL client
echo "🔹 Installing MySQL client..."
sudo apt install -y mysql-client

# Test MySQL connection
echo "🔹 Testing MySQL connection..."
mysql -h "$MYSQL_HOST" -u "$MYSQL_ADMIN@$MYSQL_SERVER_NAME" -p"$MYSQL_PASSWORD" -e "SHOW DATABASES;"

echo "✅ MySQL setup completed successfully!"
