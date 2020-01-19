# Ebook News Service

This project build the environment to create a news ebook with calibre tools in a docker container running on my NAS.

## Build and Release

Use make to do the work

```bash
$ make
Makefile with following options (make <option>):
	clean
	build_image
	build
	release
	deploy
    (*) not implemented

```

## TAG Version

Not tagged at moment

## Production

Set all on NAS

### Setup docker image calibre

Load the saved image with docker command on NAS

```bash
$ sudo docker load -input calibre-tools.img.tar
```

### Run with cron job

Start the generation via docker image with cron job every day at 06:00. The script cron.news.sh call all sub-scripts start with currten abbreviation day name (e.g. Sat-, Sun-, ...)

```crontab
0 6 * * * root /volume1/maintenance/cron.news.sh
```

```bash
```
#!/bin/sh
#
# weekly cron job action script
#

WOY=`date +%V`    # Week of the Year (0-53)
NOW=`date +%w`    # Number of the weekday 0 for Sunday
WDN=`date +%a`    # locals abbre weekday name

ACTIONS="/volume1/maintenance/action.news"

for EACH_ACTION in ${ACTIONS}/${WDN}-*.sh
do
  if [ -d ${EACH_ACTION} ]
  then
    echo "[ACTION.NEWS] File ${EACH_ACTION} is not a shell script"
    continue
  fi

  if [ -x ${EACH_ACTION} ]
  then
    echo -n "[ACTION.NEWS] Execute news shell script: ${EACH_ACTION}"
    $EACH_ACTION
  fi

done

#EOF
```

## Docker build environment

```bash
docker pull debian:jessie-slim
```

```dockerfile
# easily convert ebooks

FROM debian:jessie-slim

LABEL MAINTAINERS="brutus"

ARG S6_OVERLEY_VERSION='v1.22.1.0'
ARG S6_OVERLAY_TYPE='amd64'
# ARG S6_OVERLAY_FILE='https://github.com/just-containers/s6-overlay/releases/download/${S6_OVERLEY_VERSION}/s6-overlay-${S6_OVERLAY_TYPE}.tar.gz'
ARG S6_OVERLAY_FILE='https://github.com/just-containers/s6-overlay/releases/download/v1.22.1.0/s6-overlay-amd64.tar.gz'

RUN apt update \
  && echo "Install calibre tools" \
  && apt -y install \
      curl \
      calibre \
      imagemagick \
  && echo "Install s6 overlay" \
  && curl -fsSL -o /tmp/s6-overlay.tar.gz -L ${S6_OVERLAY_FILE} \
  && tar xfz /tmp/s6-overlay.tar.gz -C / \
  && echo "Create actor user and make project folders" \
  && groupmod -g 1000 users \
  && useradd -u 911 -U -d /actor -s /bin/false actor \
  && usermod -G users actor \
  && mkdir -p \
  /actor \
  /target \
  && echo "Cleanup" \
  && rm -rf /tmp/*

# add local files
COPY root-init/ /

VOLUME ["/target"]
WORKDIR /target

ENTRYPOINT ["/init"]
```

```bash
$ docker run -it -e TZ=Europe/Berlin -e PUID=$UID -e PGID=$GID --rm brutus/calibre date
[s6-init] making user provided files available at /var/run/s6/etc...exited 0.
[s6-init] ensuring user provided files have correct perms...exited 0.
[fix-attrs.d] applying ownership & permissions fixes...
[fix-attrs.d] 10-target-dir: applying... 
[fix-attrs.d] 10-target-dir: exited 0.
[fix-attrs.d] done.
[cont-init.d] executing container initialization scripts...
[cont-init.d] 10-adduser: executing... 

-------------------------------------
Development Environment
-------------------------------------
GID/UID
-------------------------------------

User uid:    1000
User gid:    1000
-------------------------------------

[cont-init.d] 10-adduser: exited 0.
[cont-init.d] 20-set-timezone: executing... 
[cont-init.d] 20-set-timezone: exited 0.
[cont-init.d] done.
[services.d] starting services
[services.d] done.
Thu Jun  6 22:41:50 CEST 2019
[cmd] date exited 0
[cont-finish.d] executing container finish scripts...
[cont-finish.d] done.
[s6-finish] waiting for services.
[s6-finish] sending all processes the TERM signal.
[s6-finish] sending all processes the KILL signal and exiting.
$
```

```bash
docker run -it --rm -v ~/Projects/HomeWork/Docker/calibre4news/data/target:/target -e TZ=Europe/Berlin -e PUID=$UID -e PGID=$GID brutus/calibre ls -la /target
[s6-init] making user provided files available at /var/run/s6/etc...exited 0.
[s6-init] ensuring user provided files have correct perms...exited 0.
[fix-attrs.d] applying ownership & permissions fixes...
[fix-attrs.d] 10-target-dir: applying... 
[fix-attrs.d] 10-target-dir: exited 0.
[fix-attrs.d] done.
[cont-init.d] executing container initialization scripts...
[cont-init.d] 10-adduser: executing... 

-------------------------------------
Development Environment
-------------------------------------
GID/UID
-------------------------------------

User uid:    1000
User gid:    1000
-------------------------------------

[cont-init.d] 10-adduser: exited 0.
[cont-init.d] 20-set-timezone: executing... 
[cont-init.d] 20-set-timezone: exited 0.
[cont-init.d] done.
[services.d] starting services
[services.d] done.
total 8
drwxrwxr-x 2 actor users 4096 Jun  6 23:02 .
drwxr-xr-x 1 root  root  4096 Jun  6 23:03 ..
-rw-rw-r-- 1 actor users    0 Jun  6 23:02 test.txt
[cmd] ls exited 0
[cont-finish.d] executing container finish scripts...
[cont-finish.d] done.
[s6-finish] waiting for services.
[s6-finish] sending all processes the TERM signal.
[s6-finish] sending all processes the KILL signal and exiting.
```

```bash
$ docker-compose -f docker-compose.dev.unix.yml exec calibre_tools ebook-convert --version
```
## How to create a ebook

This section describe how to build a ebook from recipe placed in target recipe. First start the service with docker-compose file.

```bash
$ docker-compose -f docker-compose.<dev-ops-type>.yml up -d

e.g.:
$ docker-compose -f docker-compose.dev.unix.yml up -d
```

After docker container service is run following command to create a epub book inside target with name it-news.epub

```bash
BUILD_DATE=`date +[%a, %d %b %Y]`
docker-compose -f docker-compose.dev.unix.yml exec calibre_tools convert -font helvetica -fill red -pointsize 24 -draw "text 100,585 '$BUILD_DATE'" ./recipes/fake-news.jpg ./recipes/cover.jpg
```


```bash
$ docker-compose -f docker-compose.dev.unix.yml exec calibre_tools ebook-convert ./recipes/BrutusNews.recipe ./tmp/it-news.epub
1% Converting input to HTML...
InputFormatPlugin: Recipe Input running
Using custom recipe
1% Fetching feeds...
.
.
.
The cover image has an id != "cover". Renaming to work around bug in Nook Color
EPUB output written to /target/it-news.epub
Output saved to   /target/it-news.epub

```

## Receipe Configuration #################################################


## Some handy maintenance docker commands ####################################

Remove all container
```windows-shell
docker ps -aq | % { docker rm $_ }
```

Remove all images with tag `<none>`
```windows-shell
docker images --filter dangling=true | ConvertFrom-String | where {$_.P2 -eq "<none>"} | % { docker rmi $_.P3 }
```

Remove all docker volume
```windows-shell
docker volume list | ConvertFrom-String | where {$_.P1 -eq "local"} | % { docker volume rm $_.P2 }
```

Display the Name and IP-Address of `[container]`
```
docker inspect --format='{{{.Name}} {range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' [container]
```

List all runnuíng containers with name an IP address
```windows-shell
docker ps -q | % { docker inspect --format='{{.Name}} {{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $_ } | ConvertFrom-String | Format-Table @{Expression={$_.P1};Label="Name"}, @{Expression={$_.P2};Label="IP"}
```

List part of columns from active containers
```
docker ps --format 'table {{.ID}}\t {{.Names}}\t {{.Image}}\t {{.Status}}'
```

Get the build version string  - in this case from proxy
```
docker inspect --format '{{ index .Config.Labels.build_version}}' homemedia_proxy_1
```