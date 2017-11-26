# builder
FROM ubuntu:17.10 as builder

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y \
        g++ \
        gcc \
        git \
        make \
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

RUN gem install --no-document bundler

WORKDIR /jekyll
USER jekyll

# jekyll-run-container
FROM builder

EXPOSE 4000

CMD bundler install --path .bundler --jobs=100 \
    && bundler exec jekyll serve --incremental --host 0.0.0.0 -t
