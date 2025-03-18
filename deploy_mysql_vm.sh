#!/bin/bash

# Set variables
RESOURCE_GROUP="8935920"
VM_NAME="mysql-vm"
ADMIN_USER="azureuser"
MYSQL_PASSWORD="Secure#Pass123!"  # Ensure a strong password
IMAGE="Ubuntu2204"  # Use a valid Azure VM image

# Validate Password Length & Complexity
if [[ ${#MYSQL_PASSWORD} -lt 12 || ! "$MYSQL_PASSWORD" =~ [A-Z] || ! "$MYSQL_PASSWORD" =~ [a-z] || ! "$MYSQL_PASSWORD" =~ [0-9] || ! "$MYSQL_PASSWORD" =~ [\@\#\$\%\&\*] ]]; then
    echo "ERROR: Password must be at least 12 characters long and include uppercase, lowercase, a number, and a special character."
    exit 1
fi

# Create an Azure VM
echo "Creating Azure VM for MySQL..."
az vm create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$VM_NAME" \
  --image "$IMAGE" \
  --size "Standard_B1ms" \
  --admin-username "$ADMIN_USER" \
  --admin-password "$MYSQL_PASSWORD" \
  --public-ip-sku Standard \
  --generate-ssh-keys --output none

# Wait for a few seconds to allow the VM to get an IP
sleep 10

# Get the public IP of the VM
VM_IP=$(az network public-ip list --resource-group "$RESOURCE_GROUP" --query "[?starts_with(name, '$VM_NAME')].ipAddress" --output tsv)

# Validate VM Creation and Public IP retrieval
if [ -z "$VM_IP" ]; then
    echo "ERROR: Failed to get the VM public IP. Exiting..."
    exit 1
fi

echo "Azure VM Created: $VM_NAME"
echo "🔹 Public IP: $VM_IP"

# Open port 3306 for MySQL
echo "🔹 Opening port 3306 for MySQL access..."
az vm open-port --resource-group "$RESOURCE_GROUP" --name "$VM_NAME" --port 3306 --output none
echo "Port 3306 opened."

# Install MySQL on the VM
echo "🔹 Installing MySQL on the VM..."
ssh -o StrictHostKeyChecking=no "$ADMIN_USER@$VM_IP" << EOF
    sudo apt update && sudo apt install mysql-server -y
    sudo systemctl enable mysql
    sudo systemctl start mysql
    sudo mysql -e "CREATE USER 'adminuser'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';"
    sudo mysql -e "GRANT ALL PRIVILEGES ON *.* TO 'adminuser'@'%' WITH GRANT OPTION;"
    sudo mysql -e "FLUSH PRIVILEGES;"
    sudo sed -i 's/bind-address.*/bind-address = 0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf
    sudo systemctl restart mysql
EOF

echo "MySQL installed and configured for remote access."
echo "🔹 Connect using: mysql -h $VM_IP -u adminuser -p"
