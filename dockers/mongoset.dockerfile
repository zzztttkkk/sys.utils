FROM mongo:latest
RUN apt update && apt install -y supervisor
WORKDIR /usr/local/app
RUN mkdir /usr/local/app/main && mkdir /usr/local/app/repl
COPY ./mongoset.supervisor.conf ./supervisor.conf
