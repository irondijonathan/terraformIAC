#!/bin/bash
# Update package manager
sudo apt-get update -y

# Install necessary packages
sudo apt-get install -y nginx php-fpm php-mysql php-xml php-mbstring php-zip curl unzip git

# Install Composer
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer

# Set up Laravel
cd /var/www/html/app 
sudo rm -rf *
git clone https://github.com/irondijonathan/terraformTest.git .
composer install

# Set permissions
sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 755 /var/www/html
sudo chmod -R 777 /var/www/html/storage
sudo chmod -R 777 /var/www/html/bootstrap/cache

# Set environment variables
cp .env .env
php artisan key:generate
php artisan migrate --force

# Configure Nginx
sudo tee /etc/nginx/sites-available/default > /dev/null <<EOT
server {
    listen 80;
    server_name _;
    root /var/www/html/public;

    index index.php index.html index.htm;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php7.4-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOT

# Restart Nginx to apply changes
sudo systemctl restart nginx