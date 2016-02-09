FROM ubuntu:15.04

RUN apt-get update && apt-get upgrade -y
RUN apt-get install -y bundler
RUN apt-get install -y zlib1g-dev

ENV JEKYLL_UID 1000
ENV JEKYLL_GID 1000

RUN groupadd --gid $JEKYLL_GID jekyll \
    && useradd --uid $JEKYLL_UID --gid $JEKYLL_GID jekyll \
    && mkdir /jekyll \
    && chown jekyll /jekyll

WORKDIR /jekyll
USER jekyll

EXPOSE 4000

CMD bundler install --path .bundler && bundler exec guard