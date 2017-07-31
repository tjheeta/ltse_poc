#FROM bitwalker/alpine-elixir-phoenix
FROM trenpixster/elixir
MAINTAINER TJ

WORKDIR /opt/app

COPY _build/kube/rel/ltse_poc/releases/0.0.1/ltse_poc.tar.gz /opt/app
RUN tar xf ltse_poc.tar.gz

ENV PORT 4000
EXPOSE 4000

CMD ["./bin/ltse_poc", "foreground"]
