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

    while getopts ":sn:p:c:" opt; do
        case $opt in
            s)
                echo "Using security and 'https' as connector scheme"
                # Use secure connector
                xmlstarlet ed --inplace --delete "/Server/Service/Connector/@secure" "${BITBUCKET_HOME}/shared/server.xml"
                xmlstarlet ed --inplace --insert "/Server/Service/Connector" --type attr -n secure -v true "${BITBUCKET_INSTALL_DIR}/"${BITBUCKET_HOME}/shared/server.xml""
                # Use https
                xmlstarlet ed --inplace --delete "/Server/Service/Connector/@scheme" "${BITBUCKET_HOME}/shared/server.xml"
                xmlstarlet ed --inplace --insert "/Server/Service/Connector" --type attr -n scheme -v https "${BITBUCKET_HOME}/shared/server.xml"
                ;;
            n)
                echo "Using '$OPTARG' as connector proxyName"
                # Set connector proxyName
                xmlstarlet ed --inplace --delete "/Server/Service/Connector/@proxyName" "${BITBUCKET_HOME}/shared/server.xml"
                xmlstarlet ed --inplace --insert "/Server/Service/Connector" --type attr -n proxyName -v $OPTARG "${BITBUCKET_HOME}/shared/server.xml"
                ;;
            p)
                echo "Using '$OPTARG' as connector proxyPort"
                # Set connector proxyPort
                xmlstarlet ed --inplace --delete "/Server/Service/Connector/@proxyPort" "${BITBUCKET_HOME}/shared/server.xml"
                xmlstarlet ed --inplace --insert "/Server/Service/Connector" --type attr -n proxyPort -v $OPTARG "${BITBUCKET_HOME}/shared/server.xml"
                ;;
            c)
                echo "Using '$OPTARG' as context path"
                xmlstarlet ed --inplace --delete "/Server/Service/Engine/Host/Context/@path" "${BITBUCKET_HOME}/shared/server.xml"
                xmlstarlet ed --inplace --insert "/Server/Service/Engine/Host/Context" --type attr -n path -v /$OPTARG "${BITBUCKET_HOME}/shared/server.xml"
                ;;
            \?)
                echo "Unknown option: -$OPTARG"
                ;;
            :)
                echo "-$OPTARG requires an argument"
                exit 1
                ;;
        esac
    done
else
    echo "${BITBUCKET_HOME}/shared/server.xml already exists, no modification will be performed"
fi

# Run in foreground, start-webapp will exclude adding Elastich Search which is bundled with Bitbucket. This is due that
# we will use Splunk in stead
bin/start-webapp.sh -fg
