FROM                java:openjdk-8-jre

MAINTAINER          Ismar Slomic <ismar.slomic@accenture.com>

# Install dependencies, download and extract Bitbucket Server and create the required directory layout.
# Try to limit the number of RUN instructions to minimise the number of layers that will need to be created.
RUN apt-get update -qq \
    && apt-get install -y --no-install-recommends git libtcnative-1 xmlstarlet vim \
    && apt-get clean autoclean \
    && apt-get autoremove --yes \
    && rm -rf /var/lib/{apt,dpkg,cache,log}/

# Data directory for Bitbucket Server
# https://confluence.atlassian.com/bitbucketserver/bitbucket-server-home-directory-776640890.html
ENV BITBUCKET_HOME          /var/atlassian/application-data/bitbucket

# Install Atlassian Bitbucket Server to the following location
ENV BITBUCKET_INSTALL_DIR   /opt/atlassian/bitbucket

ENV BITBUCKET_VERSION       4.8.3
ENV DOWNLOAD_URL            https://downloads.atlassian.com/software/stash/downloads/atlassian-bitbucket-${BITBUCKET_VERSION}.tar.gz

# Create Bitbucket Server application user, can be overwritten by providing -u option in docker run
# https://docs.docker.com/engine/reference/run/#/user
ARG user=bitbucket
ARG group=bitbucket
ARG uid=1000
ARG gid=1000

# Bitbucket Server is running with user `bitbucket`, uid = 1000
# If you bind mount a volume from the host or a data container,
# ensure you use the same uid
RUN mkdir -p $(dirname $BITBUCKET_HOME) \
    && groupadd -g ${gid} ${group} \
    && useradd -d "$BITBUCKET_HOME" -u ${uid} -g ${gid} -m -s /bin/bash ${user}

RUN mkdir -p                                ${BITBUCKET_HOME} \
    && mkdir -p                             ${BITBUCKET_HOME}/caches/indexes \
    && chmod -R 700                         ${BITBUCKET_HOME} \
    && chown -R ${user}:${group}            ${BITBUCKET_HOME} \
    && mkdir -p                             ${BITBUCKET_INSTALL_DIR}/conf/Catalina \
    && curl -L --silent                     ${DOWNLOAD_URL} | tar -xz --strip=1 -C "$BITBUCKET_INSTALL_DIR" \
    && chmod -R 700                         ${BITBUCKET_INSTALL_DIR}/conf \
    && chmod -R 700                         ${BITBUCKET_INSTALL_DIR}/logs \
    && chmod -R 700                         ${BITBUCKET_INSTALL_DIR}/temp \
    && chmod -R 700                         ${BITBUCKET_INSTALL_DIR}/work \
    && chown -R ${user}:${group}            ${BITBUCKET_INSTALL_DIR}/conf \
    && chown -R ${user}:${group}            ${BITBUCKET_INSTALL_DIR}/logs \
    && chown -R ${user}:${group}            ${BITBUCKET_INSTALL_DIR}/temp \
    && chown -R ${user}:${group}            ${BITBUCKET_INSTALL_DIR}/work \
    && ln --symbolic                        "/usr/lib/x86_64-linux-gnu/libtcnative-1.so" "${BITBUCKET_INSTALL_DIR}/lib/native/libtcnative-1.so" \
    && perl -i -p -e 's/^# umask 0027/umask 0027/'  ${BITBUCKET_INSTALL_DIR}/bin/setenv.sh

COPY        docker-entrypoint.sh /
ENTRYPOINT  ["/docker-entrypoint.sh"]
RUN         chmod +x /docker-entrypoint.sh

USER        ${user}:${group}

# HTTP Port
EXPOSE      7990

# SSH Port
EXPOSE      7999

# Set volume mount points for installation and home directory. Changes to the
# home directory needs to be persisted
VOLUME      ["${BITBUCKET_HOME}"]

# Set the default working directory as the installation directory.
WORKDIR     $BITBUCKET_INSTALL_DIR

# Run Atlassian Bitbucket Server as a foreground process by default.
# https://confluence.atlassian.com/bitbucketserver/starting-and-stopping-bitbucket-server-776640144.html
CMD         ["bin/start-bitbucket.sh", "-fg"]