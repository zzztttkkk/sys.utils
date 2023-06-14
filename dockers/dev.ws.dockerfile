FROM alpine:latest as dev_ws_base

RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories && \
    apk update && \
    apk add su-exec tzdata libpq postgresql postgresql-contrib postgresql-url_encode python3 py3-pip \
    rm -rf /var/cache/apk/*

RUN mkdir /usr/scripts/

COPY ./wsscripts /usr/scripts
RUN pip install -i https://pypi.tuna.tsinghua.edu.cn/simple flask
RUN python /usr/scripts/pg.init.py

ENTRYPOINT [ "python", "/usr/scripts/server.py" ]