
# flix

Video streaming server in Crystal, using Kemal.
Serves videos from one or more directories with a ReactJS web app or over a simple API.

A demo site hosting some public-domain videos is available at
[demo.flix.tams.tech](https://demo.flix.tams.tech/index.html). The username is
*demouser* and the password is *demopass*.

![screenshot of flix](https://raw.githubusercontent.com/dscottboggs/flix.cr/SSL/Screenshot_2019-01-26__flix%20.png)

## Why flix?

Flix does not aim to be a full-featured media center like Emby or Plex. It is focused on being a
fast, lightweight video-streaming platform. It is developed under the unix philosophy of doing
one thing and doing it well, maintaining as much separation and independence between individual
components as possible.

#### Features:
 - Performance: while playing every video on the demo site at the same time, it consumed
   18MB of memory and 0.1% of my 2.6GHz CPU. Raspberry Pi 1 image coming soon.
 - Stream videos from one or more nested directories.
 - Minimal progressive web app with mobile-friendly design
 - Password-protected API and interface
 - SSL integration
 - compiles to a single binary

#### Yet to be implemented
See the [issues](https://github.com/dscottboggs/flix.cr/issues) page

#### Features that won't be implemented:
 - Querying to a 3rd party service for subtitles, thumbnails, titles, etc.
 - Music playback or other media playback besides video (although there's no reason another service
   couldn't be created based on this which serves music instead, however it would require a much
   more complicated user interface)

### Flix vs...
##### Plex or Emby
Flix is an free and open-source software licensed under the AGPL, a restrictive copyleft license
which ensures that it will always be a software that benefits its users first. It is 100% respective
of your privacy and does not interact with any 3rd party services.

##### Jellyfin
I wholly support the Jellyfin project, and recognize that it's feature set may be more desireable to
some, however, I wanted a more lightweight, privacy-by-design solution. Additionally, Crystal's extreme
readability and flexible syntax makes development more pleasant.

##### Streama
Streama is built using the Grails platform, which is a dynamically-typed language which targets the
JVM. I haven't tested it personally, but I would assume that performance on such a platform would be
greatly reduced compared to native Crystal binaries. Additionally, Streama implements many features
I find to be undesirable. See the **Features that won't be implemented** section.


## Installation

Crystal allows compiling to a single self-contained executable. I'll drop one of
those in the "releases" section of the repo.

Please note that statically-linked crystal binaries still require the presence
of glibc.

### From source
When installing from source, you must have the development libraries for libmagic. On Ubuntu, it's available as the `libmagic-dev` package.

Run the following commands in the directory you wish to download the source to.
```sh
git clone https://github.com/dscottboggs/flix.cr.git # clone this repository
cd flix.cr      # change working directory to the repository
shards install  # install dependencies
crystal build --release --static -o /usr/local/bin/flix.cr src/flix.cr # build and install
flix.cr --port 8080 # run the server, exposing it on port 8080
```

### Deployment with the frontend
There is a frontend being developed in parallel to this server in React.JS. It can be found at https://github.com/dscottboggs/flix-webui. If you want to deploy with the frontend available, follow these instructions *instead* of those above.
```sh
git clone https://github.com/dscottboggs/flix-webui.git # clone the webui
git clone https://github.com/dscottboggs/flix.cr.git # clone this repository
cd flix.cr      # change working directory to the repository
shards install  # install dependencies
sudo crystal build --release --static -o /usr/local/bin/flix src/flix.cr # build and install
cd ../flix-webui
npm install # install frontend dependencies
npm run build # compile JS (for compatibility and size)
flix_webroot=$PWD/build flix --port=8080 # starts serving.
```

### Deployment with built-in SSL and certbot
I use a reverse proxy to manage a number of sites and web services hosted on a
single machine. It's simpler that way for me. However, for someone who's only
deploying this one service, it may be simpler to deploy it standalone by
providing certificates directly to the webserver (for example if running on a
Raspberry Pi).

If you want to deploy `flix` directly with SSL:
1. get a domain, and point your DNS record at your local IP.
2. make sure you have ports 80 and 443 open on your router. Certbot uses these ports directly, so you'll need to deploy on that port and run as root.
3. Make sure you have `certbot` installed and a `flix.cr` executable on your `$PATH`.
4. run `./local-deploy.sh`, passing it any options you wish to overload. You will need at least
  - `--email`: the email you wish to register with the ACME/LetsEncrypt service with
  - `--doman`: the domain you want to register a certificate for
  - `--port 443`: or whatever port you want to wind up having.
5. once you're sure it all works (you'll get an error about an invalid certificate issuer in the browser, but everything besides that) run `./local-deploy.sh` again with the same options, and add the `--production` flag.
6. you can now close port 80 (no redirect support)

### Deployment with Docker and Traefik
##### (how I do it)
This is the docker-compose file from the [demo site](https://demo.flix.tams.tech/), verbatim.

```yaml
version: '3'
services:
  flix.cr:
    build:
      context: .
      dockerfile: Dockerfile.with-ui
    networks:
      # The "web" network is what I have traefik configured to watch on. Yours may be different.
      # see global networks config
      - web
    volumes:
      # bind mount for media
      - /home/scott/Videos/Public:/media:ro
      # regular volume for storing config state
      # see global volumes config
      - flix_demo_config:/config
    labels:
      traefik.docker.network: web
      traefik.enable: "true"
      # This next label tells traefik to forward all requests for these Host values to this container
      traefik.madscientists_blog.frontend.rule: Host:demo.flix.tams.tech,demo.flix.madscientists.co
      traefik.madscientists_blog.port: "80"
      traefik.madscientists_blog.protocol: http

networks:
  web:
    external: true

volumes: { flix_demo_config: }
```

Using the appropriate values (substitute the hostname for your own and set the
appropriate path to your media directory), this deployment is as simple as:

1. point your DNS at your IP
2. Open ports 80 and 443 for traefik?
3. run `docker-compose up -d`

That's it!

## Usage

See the output of `--help` for command line usage.
