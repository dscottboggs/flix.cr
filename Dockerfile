FROM ubuntu:18.04
# install dependencies
RUN apt-get update &&\
    apt-get upgrade -yqq \
      wget git libz-dev libssl-dev libgc1c2 \
      make gcc libpcre3-dev libevent-dev \
      libmagic-dev libyaml-dev curl &&\
    wget --output-document "/tmp/crystal.deb" \
      "https://github.com/crystal-lang/crystal/releases/download/0.27.0/crystal_0.27.0-1_amd64.deb" &&\
    dpkg -i /tmp/crystal.deb;\
    apt-get install -fyqq &&\
    mkdir /flix.cr
WORKDIR /flix.cr
# install dependencies and cache before copying so we don't have to redo this
# step every time any file (including this one) changes in the whole source tree
COPY shard.yml /flix.cr
RUN shards install &&\
    apt-get purge wget git curl -qqy &&\
    apt-get autoremove --purge -qqy &&\
    apt-get clean -yqq
COPY . /flix.cr
# compile and install
RUN /usr/bin/crystal build --release --static -o /usr/local/bin/flix src/flix.cr &&\
    chmod 555 /usr/local/bin/flix &&\
    mkdir /config

ENTRYPOINT /flix.cr/docker-entrypoint.sh
