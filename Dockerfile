FROM ubuntu:latest
RUN apt-get update && apt-get upgrade -yqq wget
RUN wget --output-document /usr/local/bin/flix \
    https://github.com/dscottboggs/flix.cr/releases/download/1.0.0/flix
RUN apt-get purge wget -y && apt-get autoremove --purge -y && apt-get clean -y
RUN chmod 555 /usr/local/bin/flix
RUN [ -z "$(ls /media)" ]
EXPOSE 80
CMD flix --dir /media
