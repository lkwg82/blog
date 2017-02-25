FROM ubuntu:16.10

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y \
        git \
        nodejs \
        ruby \
        ruby-dev \
        zlib1g-dev

ENV JEKYLL_UID 1000
ENV JEKYLL_GID 1000

RUN groupadd --gid $JEKYLL_GID jekyll \
    && useradd --create-home --uid $JEKYLL_UID --gid $JEKYLL_GID jekyll \
    && mkdir /jekyll \
    && chown jekyll /jekyll

RUN gem install --no-document bundler --version 1.14.5

WORKDIR /jekyll
USER jekyll

EXPOSE 4000

CMD bundler install --path .bundler --jobs=10 \
    && bundler exec jekyll serve --incremental --host 0.0.0.0 -t
