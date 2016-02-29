FROM ubuntu:15.10

RUN apt-get update && apt-get upgrade -y
RUN apt-get install -y bundler
RUN apt-get install -y zlib1g-dev
RUN gem uninstall eventmachine

ENV JEKYLL_UID 1000
ENV JEKYLL_GID 1000

RUN groupadd --gid $JEKYLL_GID jekyll \
    && useradd --uid $JEKYLL_UID --gid $JEKYLL_GID jekyll \
    && mkdir /jekyll \
    && chown jekyll /jekyll

WORKDIR /jekyll
USER jekyll

EXPOSE 4000

CMD bundler install --path .bundler \
    && bundler exec guard
#    && bundler exec jekyll serve --incremental --host 0.0.0.0
