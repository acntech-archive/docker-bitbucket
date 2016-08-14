# Supported tags and respective `Dockerfile` links

-	[`latest` (*latest/Dockerfile*)](https://)

[![](https://badge.imagelayers.io/httpd:latest.svg)](https://imagelayers.io/?images=httpd:2.2.31,httpd:2.2.31-alpine,httpd:2.4.23,httpd:2.4.23-alpine) **TODO**

# What is Bitbucket Server?

Bitbucket Server (previously named Stash) is an on-premises source code management solution for Git that's secure, fast, and enterprise grade. Create and manage repositories, set up fine-grained permissions, and collaborate on code â€“ all with the flexibility of your servers.

Learn more about Bitbucket Server: <https://www.atlassian.com/software/bitbucket>

> [wikipedia.org/wiki/Bitbucket](https://en.wikipedia.org/wiki/Bitbucket)

<img src="logo.png" alt="Logo" width="450px"/>

# How to use this image.

This image is based on official [java:openjdk-8-jre (JRE)](https://github.com/docker-library/docs/tree/master/java) and installs Atlassian Bitbucket Server 4.8.3. It is also enabled for use with reverse proxy by providing environment variables as explained further down in this README.
Reason why this Docker image has been established is that we wanted to do few changes to the official [Atlassian Bitbucket Server image](https://bitbucket.org/atlassian/docker-atlassian-bitbucket-server) such as adding support for reverse proxy, running Bitbucket as `bitbucket` user and setting unmask to 0027.

### Credits
We want to give credit to following Docker images that has been used as inspiration of this image:
- [atlassian/bitbucket-server](https://bitbucket.org/atlassian/docker-atlassian-bitbucket-server)
- [cptactionhank/docker-atlassian-jira-software](https://github.com/cptactionhank/docker-atlassian-jira-software)
- [ahaasler/docker-jira](https://github.com/ahaasler/docker-jira)
- [mhubig/atlassian](https://github.com/mhubig/atlassian)

### Alt 1: Run container with minimum config

```console
$ docker run --restart=unless-stopped -d -p 7990:7990 -p 7999:7999 --name bitbucket acntech/adop-bitbucket
```

You are now ready to start configuration of Bitbucket (choosing license model and other initial configuration) by entering http://localhost:7990. We recommend that you look at logs (`docker logs bitbucket -f`) while initial configuration is done to make sure everything is running smooth.

This will store the workspace in `/var/atlassian/application-data/bitbucket`. All Bitbucket Server data lives in there - including plugins, configuration, attachments ++ (see [Bitbucket Server home directory](https://confluence.atlassian.com/bitbucketserver/bitbucket-server-home-directory-776640890.html) ). You will probably want to make that a persistent volume (recommended). 

The `--restart=unless-stopped` option is set to automatically restart the docker container in case of failure and server reboot, but not if the container has been set to stop state. [More information](https://docs.docker.com/engine/reference/run/#/restart-policies-restart).

### Alt 2: Run container with persisting volume

##### Mount a host directory as a data volume

This strategy is mostly suited for testing locally as the container will be dependent on the filesystem of the host. 
This might cause issues with regards to access rights on the mounted folder from the host filesystem. 

```console
$ docker run --restart=unless-stopped -d -p 7990:7990 -p 7999:7999 --name bitbucket \
      -v "/var/lib/docker/data/bitbucket:/var/atlassian/application-data/bitbucket" \
      acntech/adop-bitbucket
```
This will store the Bitbucket Server data in `/var/lib/docker/data/bitbucket` on the host. 
Ensure that `/var/lib/docker/data/bitbucket` is accessible by the `bitbucket` user in container (`bitbucket` user - uid `1000`) or use [-u](https://docs.docker.com/engine/reference/run/#/user) `some_other_user` parameter with `docker run`.

> WARNING! Please note that [boot2docker](https://github.com/boot2docker/boot2docker), which is used to host Docker on Windows and Mac when spinning up new [Docker Machine](https://docs.docker.com/machine/overview/), **removes** automatically **all folders** but `/var/lib/docker` and `/var/lib/boot2docker` in case of restarting the docker-machine. See [Persistent data](https://github.com/boot2docker/boot2docker#persist-data) and [ServerFault thread](http://serverfault.com/questions/722085/why-does-docker-machine-clear-data-on-restart).
```console
$ docker-machine ssh test-machine
$ docker run -v /data:/data --name mydata busybox true
$ docker run --volumes-from mydata busybox sh -c "echo hello >/data/hello"
$ docker run --volumes-from mydata busybox cat /data/hello
hello
$ docker run -v /var/lib/docker/data:/data --name mydata2 busybox true
$ docker run --volumes-from mydata2 busybox sh -c "echo hello >/data/hello"
$ docker run --volumes-from mydata2 busybox cat /data/hello
hello
$ docker-machine restart test-machine
$ docker-machine ssh test-machine
$ docker run --volumes-from mydata busybox cat /data/hello
cat: can't open '/data/hello': No such file or directory
$ docker run --volumes-from mydata2 busybox cat /data/hello
hello
```

##### Mount a docker data volume

Recommended approach for mounting data outside of the container. The data volume will exist even if you remove the container and the volume can easily be reused by other containers.
[More information](https://docs.docker.com/engine/reference/commandline/volume_create/)

```console
$ docker volume create --name bitbucket_volume
$ docker run --restart=unless-stopped -d -p 7990:7990 -p 7999:7999 --name bitbucket \
    -v bitbucket_volume:/var/atlassian/application-data/bitbucket acntech/adop-bitbucket
```
This will map the data volume `bitbucket_volume` to the containers `/var/atlassian/application-data/bitbucket` directory.

### Alt 3: Run container with reverse proxy

If you have a reverse proxy, such as [Nginx](https://confluence.atlassian.com/bitbucketserver/securing-bitbucket-server-behind-nginx-using-ssl-776640112.html) or [Apache HTTP Server](https://confluence.atlassian.com/kb/integrating-apache-http-server-reverse-proxy-with-bitbucket-server-753894395.html) in front of your Bitbucket Server you need to provide proxy settings:

```console
$ docker run --restart=unless-stopped -d -p 7990:7990 -p 7999:7999 --name bitbucket \
    -v "/var/lib/docker/data/bitbucket:/var/atlassian/application-data/bitbucket" \
    -e "X_PROXY_NAME=example.com" \
    -e "X_PROXY_PORT=80" \
    -e "X_PROXY_SCHEME=http" \
    -e "X_PATH=/bitbucket" \
    acntech/adop-bitbucket
```

Environment Variables:
`X_PROXY_NAME`      : Sets the connector proxy name (in this case `example.com`)
`X_PROXY_PORT`      : Sets the connector proxy port (in this case `80`)
`X_PROXY_SCHEME`    : Sets the connector scheme (in this case `http`).
`X_PATH`            : Sets the context path (in this case `/bitbucket` so you would access Bitbucket http://localhost:8080/bitbucket).

> IMPORTANT! This configuration will be only written to `${BITBUCKET_HOME}/shared/server.xml` file once, when one or more of env variables are provided. Next time you stop/start container these parameters will be ignored.

You will also need to configure reverse proxy, _example_ of such configuration for _Nginx_ (which is running at same [Docker host and network](https://docs.docker.com/engine/userguide/networking/dockernetworks/) as Bitbucket) is:
```
server {
    listen                                  80;
    server_name                             example.com;
    location /bitbucket {
        proxy_set_header X-Forwarded-Host   $host;
        proxy_set_header X-Forwarded-Server $host;
        proxy_set_header X-Forwarded-For    $proxy_add_x_forwarded_for;
        proxy_pass                          http://bitbucket-software:7990;
        proxy_redirect                      off;
    }
}
```
### Alt 4: Run container with custom memory and plugin timeout properties

```console
$ docker run --restart=unless-stopped -d -p 7990:7990 -p 7999:7999 --name bitbucket \
      -v "/var/lib/docker/data/bitbucket:/var/atlassian/application-data/bitbucket" \
      -e "X_PROXY_NAME=example.com" \
      -e "X_PROXY_PORT=80" \
      -e "X_PROXY_SCHEME=http" \
      -e "X_PATH=/bitbucket" \
      -e "CATALINA_OPTS=-Xms256m -Xmx768m -Datlassian.plugins.enable.wait=300" \
      acntech/adop-bitbucket
```

Catalina properties:
`Xms` : JVM Minimum Memory (in this case 256 MB). [More information](https://confluence.atlassian.com/bitbucketserverkb/bitbucket-server-is-reaching-resource-limits-779171381.html#BitbucketServerisreachingresourcelimits-Memorybudget)
`Xmx` : JVM Maximum Memory (in this case 768 MB). [More information](https://confluence.atlassian.com/bitbucketserverkb/bitbucket-server-is-reaching-resource-limits-779171381.html#BitbucketServerisreachingresourcelimits-Memorybudget)
`atlassian.plugins.enable.wait` : Time in seconds Bitbucket waits for plugins to load eg. 300. [More information](https://confluence.atlassian.com/display/JIRAKB/JIRA+applications+System+Plugin+Timeout+While+Waiting+for+Add-ons+to+Enable)

### Using external Oracle database
After container has started for the first time you can access Bitbucket Server UI at http://localhost:7990 and start initial setup. 
If you would like to use external Oracle 12c database, please take a look at [setup-bitbucket-oracledb.sql](sql/setup-bitbucket-oracledb.sql) and official [documentation](https://confluence.atlassian.com/bitbucketserver/connecting-bitbucket-server-to-oracle-776640379.html).

### Upgrade
    
Refer to [Bitbucket Server upgrade guide](https://confluence.atlassian.com/bitbucketserver/bitbucket-server-upgrade-guide-776640551.html)

To upgrade to a more recent version of Bitbucket Server you can simply stop the `bitbucket`
container and start a new one based on a more recent Docker image:

    $> docker stop bitbucket
    $> docker rm bitbucket
    $> docker run ... (See above)

As your data is stored in the data volume directory on the host it will still be available after the upgrade.

> IMPORTANT: Please make sure that you **don't** accidentally remove the `bitbucket`
container and its volumes using the `-v` option.


### Backup 
For evaluations you can use the built-in database that will store its files in the Bitbucket Server home directory. In that case it is sufficient to create a backup archive of the directory on the host that is used as a volume (`/var/lib/docker/data/bitbucket` in the example above).

The [Bitbucket Server Backup Client](https://confluence.atlassian.com/display/BitbucketServer/Data+recovery+and+backups) is currently not supported in the Docker setup. You can however use the [Bitbucket Server DIY Backup](https://confluence.atlassian.com/display/BITBUCKET+SERVER/Using+Bitbucket+DIY+Backup) approach in case you decided to use an external database.

Read more about data recovery and backups: [Data recovery and backups](https://confluence.atlassian.com/display/BitbucketServer/Data+recovery+and+backups)
TODO - See [this](https://github.com/mhubig/atlassian/tree/master/atlassian-stash) image

### Restore
Please refer to official [Data recovery and backups](https://confluence.atlassian.com/display/BitbucketServer/Data+recovery+and+backups) documentation before reading further.
TODO - See [this](https://github.com/mhubig/atlassian/tree/master/atlassian-stash) image

# License

This image is licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE) for the full license text.

# Supported Docker versions

This image is officially supported on Docker version 1.12.

Support for older versions (down to 1.6) is provided on a best-effort basis.

Please see [the Docker installation documentation](https://docs.docker.com/installation/) for details on how to upgrade your Docker daemon.

# User Feedback

## Documentation

Documentation for this image is currently only in this [README.md](README.md) file. Please support us keeping documentation up to date and relevant.

## Issues

If you have any problems with or questions about this image, please contact us through a [GitHub issue](https://github.com/acntech/docker-bitbucket/issues)

You can also reach image maintainers mentioned in the [Dockerfile](Dockerfile).

## Contributing

You are invited to contribute new features, fixes, or updates, large or small; we are always thrilled to receive pull requests, and do our best to process them as fast as we can.

Before you start to code, we recommend discussing your plans through a [GitHub issue](https://github.com/acntech/docker-bitbucket/issues), especially for more ambitious contributions. This gives other contributors a chance to point you in the right direction, give you feedback on your design, and help you find out if someone else is working on the same thing.

Please make sure to raise a Pull Request for your changes to be merged into master branch.

### Recommended Reading
- [Docker Engine](https://docs.docker.com/engine/)
- [Docker Compose](https://docs.docker.com/compose/)
- [Docker Machine](https://docs.docker.com/machine/)
- [Dockerfile reference](https://docs.docker.com/engine/reference/builder/)
- [Best practices for writing Dockerfiles](https://docs.docker.com/engine/userguide/eng-image/dockerfile_best-practices/)
- [Docker run reference](https://docs.docker.com/engine/reference/run/)
- [Docker Cheat Sheet](https://github.com/wsargent/docker-cheat-sheet)
- [Gracefully Stopping Docker Containers](https://www.ctl.io/developers/blog/post/gracefully-stopping-docker-containers/)
- [Running the Bitbucket Server installer](https://confluence.atlassian.com/bitbucketserver/running-the-bitbucket-server-installer-776640183.html)
- [Getting started with Bitbucket Server](https://confluence.atlassian.com/bitbucketserver/using-bitbucket-server-776639769.html)