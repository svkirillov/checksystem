FROM perl:5.30

ADD cpanfile /

RUN cpanm -n --installdeps / && cpanm -n DDP
RUN curl -fsSL https://get.docker.com | sh && apt install -y docker-compose

VOLUME /var/run/docker.sock
VOLUME /app

WORKDIR /app

ENTRYPOINT ["/app/docker/checksystem-entrypoint.sh"]
