#/bin/bash

mkdir -p ./web/themes/ ./web/modules/ ./web/sites/
# Generate drupal example files on host side
docker run --rm drupal tar -cC /var/www/html/themes . | tar -xC ./web/themes
docker run --rm drupal tar -cC /var/www/html/modules . | tar -xC ./web/modules
docker run --rm drupal tar -cC /var/www/html/sites . | tar -xC ./web/sites
docker run --rm drupal cat /opt/drupal/composer.json > ./composer.json
docker run --rm drupal cat /opt/drupal/composer.lock > ./composer.lock

docker compose up -d

bash claude-cli-install.sh

# mysql クライアント（drush が DB を扱うために必要）
echo "Start: install default-mysql-client"
docker compose exec drupal bash -c 'apt-get update -qq && apt-get install -y -qq default-mysql-client'

echo "End: install default-mysql-client"

# drush
echo "Start: install drush"
docker compose exec drupal composer require drush/drush --working-dir=/opt/drupal --no-interaction

echo "End: install drush"

# 開発用パッケージ（PHPUnit を含む）
echo "Start: install phpunit drupal/core-dev"
docker compose exec drupal composer require --dev phpunit/phpunit drupal/core-dev \
  --working-dir=/opt/drupal --no-interaction --with-all-dependencies

echo "End: install phpunit drupal/core-dev"

echo "Start: install standard site"
docker compose exec drupal /opt/drupal/vendor/bin/drush site:install standard \
  --db-url="mysql://root:password@mysql/drupal" \
  --site-name="Drupal App" \
  --account-name=admin \
  --account-pass=admin \
  --yes

echo "End: install standard site"