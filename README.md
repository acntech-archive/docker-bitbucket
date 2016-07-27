# docker-bitbucket: A Docker image for Bitbucket Server

## Features
* Installs *Altassian Bitbucket Server* v 4.8
* Runs on *openjdk-8-jre*
* Ready to be configured with *Nginx* as a reverse proxy (https available).

## Note
This Docker is based on the official [Attlasian Bitbucket Server image](https://bitbucket.org/atlassian/docker-atlassian-bitbucket-server) and is only extending it with support for Nginx.
See also [Securing Bitbucket Server begind nginx using SSL](https://confluence.atlassian.com/bitbucketserver/securing-bitbucket-server-behind-nginx-using-ssl-776640112.html)
## Quick Start
For the `BITBUCKET_HOME` directory that is used to store the data we recommend mounting a host directory as a [data volume](https://docs.docker.com/engine/tutorials/dockervolumes/) :
Set permissions for the data directory so that the runuser can write to it:
```bash
$> docker run -u root -v /data/bitbucket:/var/atlassian/application-data/bitbucket acntech/adop-bitbucket chown -R daemon /var/atlassian/application-data/bitbucket
```
Start Atlassian Bitbucket Server:

```bash
$> docker run -v /data/bitbucket:/var/atlassian/application-data/bitbucket --name="bitbucket" -d -p 7990:7990 -p 7999:7999 acntech/adop-bitbucket
```
**Success**. Bitbucket is now available on [http://localhost:7990](http://localhost:7990)*

Please ensure your container has the necessary resources allocated to it.
We recommend 2GiB of memory allocated to accommodate both the application server
and the git processes.
See [Supported Platforms](https://confluence.atlassian.com/display/BitbucketServer/Supported+platforms) for further information.

_* Note: If you are using `docker-machine` on Mac OS X, please use `open http://$(docker-machine ip default):7990` instead._

### Parameters

You can use this parameters to configure your Bitbucket Server instance:

* **-s:** Enables the connector security and sets `https` as connector scheme.
* **-n &lt;proxyName&gt;:** Sets the connector proxy name.
* **-p &lt;proxyPort&gt;:** Sets the connector proxy port.
* **-c &lt;contextPath&gt;:** Sets the context path (do not write the initial /). Note The context path does [not](https://confluence.atlassian.com/bitbucketserver/moving-bitbucket-server-to-a-different-context-path-776640153.html) affect the URL at which _SSH_ operations occur.

This parameters should be given to the entrypoint (passing them after the image):

```bash
$> docker run -d -p 7990:7990 acntech/adop-bitbucket <parameters>
```

> If you want to execute another command instead of launching Bitbucket you should overwrite the entrypoint with `--entrypoint <command>` (docker run parameter).

### Nginx as reverse proxy

Lets say you have the following *nginx* configuration for bitbucket:

```
server {
    listen                          80;
    server_name                     example.com;
    return                          301 https://$host$request_uri;
}
server {
    listen                          443;
    server_name                     example.com;
    
    ssl                  	on;
    ssl_certificate      	<path/to/your/certificate>;
    ssl_certificate_key  	<path/to/your/certificate/key>;
    ssl_session_timeout  	5m;
    ssl_protocols  			TLSv1 TLSv1.1 TLSv1.2;
    ssl_ciphers  			HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers   on;
    # Optional optimisation - please refer to http://nginx.org/en/docs/http/configuring_https_servers.html
    # ssl_session_cache   shared:SSL:10m;
    location /bitbucket {
        proxy_pass 			http://localhost:7990;
        proxy_set_header 	X-Forwarded-Host $host;
        proxy_set_header 	X-Forwarded-Server $host;
        proxy_set_header    X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header    X-Real-IP $remote_addr;
        proxy_redirect 		off;
    }
}
```

> This is only an example, please secure you *nginx* better.

For that configuration you should run your Bitbucket Server container with:

```bash
$> docker run -d -p 7990:7990 acntech/adop-bitbucket -s -n example.com -p 443 -c bitbucket
```


## Upgrade
Refer to [Bitbucket Server upgrade guide](https://confluence.atlassian.com/bitbucketserver/bitbucket-server-upgrade-guide-776640551.html)

To upgrade to a more recent version of Bitbucket Server you can simply stop the `bitbucket`
container and start a new one based on a more recent image:

    $> docker stop bitbucket
    $> docker rm bitbucket
    $> docker run ... (See above)

As your data is stored in the data volume directory on the host it will still
be available after the upgrade.

_Note: Please make sure that you **don't** accidentally remove the `bitbucket`
container and its volumes using the `-v` option._

## Backup
See official [Docker image for Bitbucket Server](https://bitbucket.org/atlassian/docker-atlassian-bitbucket-server)

## License

This image is licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE) for the full license text.
