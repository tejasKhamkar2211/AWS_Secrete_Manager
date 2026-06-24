#!/bin/bash

# =========================================================
# AWS LEMP + PHP + AWS SDK + Secrets Manager Setup Script
# =========================================================

set -e  # stop script if any command fails

echo "🚀 Updating system..."
sudo apt update -y

# ---------------------------------------------------------
# 1. Install required PHP packages
# ---------------------------------------------------------
echo "📦 Installing PHP + required extensions..."

sudo apt install -y \
    php \
    php-cli \
    php-mysql \
    php-xml \
    php-mbstring \
    unzip \
    curl

# ---------------------------------------------------------
# 2. Install Composer (if not installed)
# ---------------------------------------------------------
if ! command -v composer &> /dev/null
then
    echo "📦 Installing Composer..."

    curl -sS https://getcomposer.org/installer -o composer-setup.php
    php composer-setup.php
    sudo mv composer.phar /usr/local/bin/composer
    rm composer-setup.php
fi

echo "✅ Composer version:"
composer -V

# ---------------------------------------------------------
# 3. Go to web root
# ---------------------------------------------------------
echo "📁 Moving to /var/www/html..."
cd /var/www/html

# ---------------------------------------------------------
# 4. Install AWS SDK for PHP
# ---------------------------------------------------------
echo "📦 Installing AWS SDK for PHP..."

composer require aws/aws-sdk-php

# ---------------------------------------------------------
# 5. Create db.php for AWS Secrets Manager
# ---------------------------------------------------------
echo "📝 Creating db.php..."

cat > db.php << 'EOF'
<?php

require __DIR__ . '/vendor/autoload.php';

use Aws\SecretsManager\SecretsManagerClient;

/**
 * Fetch database credentials from AWS Secrets Manager
 */
$client = new SecretsManagerClient([
    'version' => 'latest',
    'region'  => 'us-east-1'
]);

$result = $client->getSecretValue([
    'SecretId' => 'facebook-prod-db'
]);

$secret = json_decode($result['SecretString'], true);

/**
 * Create MySQL connection
 */
$conn = new mysqli(
    $secret['host'],
    $secret['username'],
    $secret['password'],
    $secret['dbname']
);

/**
 * Check DB connection
 */
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}
EOF

echo "✅ db.php created"

# ---------------------------------------------------------
# 6. Restart services
# ---------------------------------------------------------
echo "🔄 Restarting PHP & Nginx..."

sudo systemctl restart php*-fpm || true
sudo systemctl restart nginx || true

# ---------------------------------------------------------
# 7. Test AWS SDK
# ---------------------------------------------------------
echo "🧪 Testing AWS SDK..."

php -r '
require "/var/www/html/vendor/autoload.php";
var_dump(class_exists("Aws\\SecretsManager\\SecretsManagerClient"));
'

echo "🎉 Setup completed successfully!"
echo "👉 Next step: attach IAM role with SecretsManager access"
