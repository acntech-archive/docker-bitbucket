#!/bin/sh

# create 'shared' folder in BITBUCKET_HOME if not already exist (automatically created by Bitbucket, but after commands below)
mkdir -p ${BITBUCKET_HOME}/shared

# Do modification to server.xml in BITBUCKET_HOME as recommended in official Atlassian docs
# https://confluence.atlassian.com/bitbucketserver/moving-bitbucket-server-to-a-different-context-path-776640153.html
# Check if the `server.xml` file has already been created since the creation of this
# Docker image. If the file has been created the entrypoint script will not
# perform modifications to the configuration file.
if ! [ -f "${BITBUCKET_HOME}/shared/server.xml" ] ; then
    echo "Copying ${BITBUCKET_INSTALL_DIR}/conf/server.xml to ${BITBUCKET_HOME}/shared/server.xml"

    cp "${BITBUCKET_INSTALL_DIR}/conf/server.xml" "${BITBUCKET_HOME}/shared/server.xml"

    if [ -n "${X_PROXY_NAME}" ]; then
        echo "Updating '$X_PROXY_NAME' as connector proxyName"
        xmlstarlet ed --inplace --pf --ps --insert '//Connector[@port="8080"]' --type "attr" --name "proxyName" --value "${X_PROXY_NAME}" "${BITBUCKET_HOME}/shared/server.xml"
    fi
    if [ -n "${X_PROXY_PORT}" ]; then
        echo "Updating '$X_PROXY_PORT' as connector proxyPort"
        xmlstarlet ed --inplace --pf --ps --insert '//Connector[@port="8080"]' --type "attr" --name "proxyPort" --value "${X_PROXY_PORT}" "${BITBUCKET_HOME}/shared/server.xml"
    fi
    if [ -n "${X_PROXY_SCHEME}" ]; then
        echo "Updating '$X_PROXY_SCHEME' as connector scheme"
        xmlstarlet ed --inplace --pf --ps --insert '//Connector[@port="8080"]' --type "attr" --name "scheme" --value "${X_PROXY_SCHEME}" "${BITBUCKET_HOME}/shared/server.xml"
    fi
    if [ -n "${X_PATH}" ]; then
        echo "Updating '$X_PATH' as context path"
        xmlstarlet ed --inplace --pf --ps --update '//Context/@path' --value "${X_PATH}" "${BITBUCKET_HOME}/shared/server.xml"
    fi
else
    echo "${BITBUCKET_HOME}/shared/server.xml already exists, no modification will be performed"
fi

# Run in foreground
exec "$@"