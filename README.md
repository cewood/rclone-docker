# Rclone Docker

An opinionated set of simple Docker containers with [Rclone](https://rclone.org/) and [Supercronic](https://github.com/aptible/supercronic).


## Usage

Being slightly opinionated there isn't any `ENTRYPOINT` specified, instead only a default `CMD` to run Supercronic with the bundled `/etc/crontab` file that simply echoes a short message once a minute. This means you can easily change what the container does without having to override an `ENTRYPOINT`, and if you want to use the Supercronic functionality you only need to mount in your own crontab file at `/etc/crontab` and run the container without any additional args.


### Docker Run

```
$ docker run --rm -it \
    -v $PWD/conf:/conf \
    -v $PWD/data:/data \
    cewood/rclone:alpine_UPDATEME \
    rclone config show
```


### Docker Compose

```
version: "3.4"
services:
  rclone:
    image: cewood/rclone:alpine_UPDATEME
    container_name: rclone
    working_dir: /data
    volumes:
      - "./rclone/conf:/conf"
      - "./rclone/data:/data"
    restart: unless-stopped
    labels:
      org.label-schema.group: "backups"
```


## Image variants

Currently the following distributions are included:

 - Alpine 3.12
 - Debian 10.7 (Slim variant)
 - Ubuntu 20.04 (LTS release)


## Supported architectures

Currently the following architectures are built for each image variant:

 - linux/amd64
 - linux/arm64 (Currently disabled because of bugs**)
 - linux/arm/v7 (Currently disabled because of bugs**)

** the bug in question is https://github.com/docker/buildx/issues/314


# Frequently Asked Questions
## Why Supercronic and not just regular cron

If we were running a normal system in an interactive manner, then normal Cron or friends (Anacron, Fcron, etc) would be fine choices. However in a containerised environment, these traditional cron implementations have some downsides, that make Supercronic a better fit. Namely the printing of jobs output to stdout, hence when running Supercronic as the ENTRYPOINT/CMD I can see the output of the jobs being run without having to jump through any hoops. There are undoubtedly other features that Supercronic brings with it that make it a better fit for use in containers, but this was the main motivator for me.
