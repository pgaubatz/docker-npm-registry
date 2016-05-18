#!/bin/bash

set -e

if [ -z "$COUCHDB_USER" ] || [ -z "$COUCHDB_PASSWORD" ]; then
  echo "ERROR: COUCHDB_USER and COUCHDB_PASSWORD env vars must be defined"
  exit 1
fi

# create admin
printf "[admins]\n$COUCHDB_USER = $COUCHDB_PASSWORD\n" > /usr/local/etc/couchdb/local.d/docker.ini

# we need to set the permissions here because docker mounts volumes as root
chown -R couchdb:couchdb \
  /usr/local/var/lib/couchdb \
  /usr/local/var/log/couchdb \
  /usr/local/var/run/couchdb \
  /usr/local/etc/couchdb

chmod -R 0770 \
  /usr/local/var/lib/couchdb \
  /usr/local/var/log/couchdb \
  /usr/local/var/run/couchdb \
  /usr/local/etc/couchdb

chmod 664 /usr/local/etc/couchdb/*.ini
chmod 775 /usr/local/etc/couchdb/*.d

if [ "$1" = "couchdb" ]; then
  cd /usr/local/var/lib/couchdb

  if [ ! -e _NPM_REGISTRY_COUCHAPP_IS_INSTALLED ]; then
    echo "Installing NPM Registry CouchApp..."

    # start couchdb
    gosu couchdb couchdb -b -o /dev/null -e /dev/null
    echo "Waiting for CouchDB to become ready..."
    sleep 5

    # create registry db
    REGISTRY="http://$COUCHDB_USER:$COUCHDB_PASSWORD@localhost:5984/registry"
    curl -X PUT $REGISTRY

    # install couchapp
    cd /usr/local/lib/node_modules/npm-registry-couchapp/
    echo "npm-registry-couchapp:couch=$REGISTRY" > .npmrc
    export DEPLOY_VERSION="v$NPM_REGISTRY_COUCHAPP_VERSION"
    npm start
    npm run load
    NO_PROMPT=1 npm run copy

    # stop couchdb
    cd /usr/local/var/lib/couchdb
    gosu couchdb couchdb -d  -o /dev/null -e /dev/null

    touch _NPM_REGISTRY_COUCHAPP_IS_INSTALLED

    echo "NPM Registry CouchApp has been installed"
  fi

  exec gosu couchdb "$@"
fi

exec "$@"
