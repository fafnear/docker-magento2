#!/usr/bin/env bash

export MSYS_NO_PATHCONV=1

read_var() {
    VAR=$(grep $1 '.env' | xargs)
    IFS="=" read -ra VAR <<< "$VAR"
    echo ${VAR[1]}
}

BASIC_AUTH_USERNAME=$(read_var BASIC_AUTH_USERNAME)
BASIC_AUTH_PASSWORD=$(read_var BASIC_AUTH_PASSWORD)

MAGENTO_BASE_URL=$(read_var MAGENTO_BASE_URL)
MAGENTO_ADMIN_URL=$(read_var MAGENTO_ADMIN_URL)
MAGENTO_ADMIN_USER=$(read_var MAGENTO_ADMIN_USER)
MAGENTO_ADMIN_PASSWORD=$(read_var MAGENTO_ADMIN_PASSWORD)
MAGENTO_ADMIN_FIRSTNAME=$(read_var MAGENTO_ADMIN_FIRSTNAME)
MAGENTO_ADMIN_LASTNAME=$(read_var MAGENTO_ADMIN_LASTNAME)
MAGENTO_ADMIN_EMAIL=$(read_var MAGENTO_ADMIN_EMAIL)
MAGENTO_LANGUAGE=$(read_var MAGENTO_LANGUAGE)
MAGENTO_CURRENCY=$(read_var MAGENTO_CURRENCY)
MAGENTO_TIMEZONE=$(read_var MAGENTO_TIMEZONE)
MAGENTO_USE_REWRITES=$(read_var MAGENTO_USE_REWRITES)

MYSQL_HOST=$(read_var MYSQL_SERVER_HOST)
MYSQL_DATABASE=$(read_var MYSQL_DATABASE)
MYSQL_USER=$(read_var MYSQL_USER)
MYSQL_PASSWORD=$(read_var MYSQL_PASSWORD)
MYSQL_ROOT_PASSWORD=$(read_var MYSQL_ROOT_PASSWORD)

dirs=('src' 'logs/nginx' 'db/mysql')

for directory in ${dirs[@]}; do
    if [[ ! -d $directory ]]; then
        mkdir -p $directory
    fi
done

docker-compose up -d php
docker exec -ti php bash -c "
    composer config -a -g http-basic.repo.magento.com ${BASIC_AUTH_USERNAME} ${BASIC_AUTH_PASSWORD}; \
    composer create-project --stability=stable --repository-url=https://repo.magento.com/ magento/project-community-edition .; \
    php bin/magento setup:install \
    --base-url=${MAGENTO_BASE_URL} \
    --db-host=${MYSQL_HOST} \
    --db-name=${MYSQL_DATABASE} \
    --db-user=${MYSQL_USER} \
    --db-password=${MYSQL_PASSWORD} \
    --admin-firstname=${MAGENTO_ADMIN_FIRSTNAME} \
    --admin-lastname=${MAGENTO_ADMIN_LASTNAME} \
    --admin-email=${MAGENTO_ADMIN_EMAIL} \
    --admin-user=${MAGENTO_ADMIN_USER} \
    --admin-password=${MAGENTO_ADMIN_PASSWORD} \
    --backend-frontname=${MAGENTO_ADMIN_URL} \
    --language=${MAGENTO_LANGUAGE} \
    --currency=${MAGENTO_CURRENCY} \
    --timezone=${MAGENTO_TIMEZONE} \
    --use-rewrites=${MAGENTO_USE_REWRITES}; \
    php bin/magento config:set dev/static/sign 0; \
    php bin/magento config:set admin/security/session_lifetime 86400; \
    php bin/magento setup:static-content:deploy -f; \
    php bin/magento cache:clean"

if [[ -d src/.github ]]; then
    rm -r src/.github
fi

if [[ -d .git ]]; then
    rm -r .git
fi

docker-compose down