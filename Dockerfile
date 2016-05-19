FROM couchdb:1.6.1

ENV NPM_REGISTRY_COUCHAPP_VERSION 2.6.12
ENV NODE_VERSION 0.12.14

# gpg keys listed at https://github.com/nodejs/node
RUN set -ex \
  && for key in \
    9554F04D7259F04124DE6B476D5A82AC7E37093B \
    94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
    0034A06D9D9B0064CE8ADF6BF1747F4AD2306D93 \
    FD3A5288F042B6850C66B31F09FE44734EB7990E \
    71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
    DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
    B9AE9905FFD7803F25714661B63B535A4C206CA9 \
    C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
    7937DFD2AB06298B2293C3187D33FF9D0246406D \
    114F43EE0176B71C7BC219DD50A3051F888C628D \
  ; do \
    gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
  done

# install node
RUN curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.gz" \
    && curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" \
    && gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc \
    && grep " node-v$NODE_VERSION-linux-x64.tar.gz\$" SHASUMS256.txt | sha256sum -c - \
    && tar -xzf "node-v$NODE_VERSION-linux-x64.tar.gz" -C /usr/local --strip-components=1 \
    && rm "node-v$NODE_VERSION-linux-x64.tar.gz" SHASUMS256.txt.asc SHASUMS256.txt

# configure couchdb
RUN sed -i \
    -e '/\[httpd\]/a secure_rewrites = false' \
    -e '/\[couch_httpd_auth\]/a public_fields = appdotnet, avatar, avatarMedium, avatarLarge, date, email, fields, freenode, fullname, github, homepage, name, roles, twitter, type, _id, _rev\nusers_db_public = true' \
    -e '/\[couchdb\]/a delayed_commits = false' \
    /usr/local/etc/couchdb/local.ini

# download the couchapp
RUN npm install -g @pgaubatz/npm-registry-couchapp \
    && npm cache clear

# install entrypoint
COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

VOLUME ["/usr/local/var/lib/couchdb"]

EXPOSE 5984

WORKDIR /usr/local/var/lib/couchdb

ENTRYPOINT ["tini", "--", "/entrypoint.sh"]

CMD ["couchdb"]
