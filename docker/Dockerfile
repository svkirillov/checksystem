FROM perl:5.30

ADD cpanfile /

RUN cpanm -n --installdeps /
RUN cpanm -n DDP

VOLUME /app

WORKDIR /app

CMD ["/app/docker/checksystem-entrypoint.sh"]
