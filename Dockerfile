FROM                atlassian/bitbucket-server:4.8

MAINTAINER          Ismar Slomic <ismar.slomic@accenture.com>

# Change to root user for installation of dependencies and copying the launc file
USER                root:root

# Install dependencies
RUN                 apt-get install --quiet --yes --no-install-recommends vim xmlstarlet

# Add bitbucket customizer and launcher
COPY                files/launch.sh /launch

# Make bitbucket customizer and launcher executable
RUN                 chmod +x /launch

# Launch bitbucket
ENTRYPOINT          ["/launch"]