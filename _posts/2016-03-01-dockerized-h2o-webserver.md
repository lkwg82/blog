---
layout: post
title: h2o webserver with docker
subtitle:
date: 2016-03-01 13:23:07 UTC
comments: true
categories: docker h2o
---

[h2o](https://h2o.examp1e.net/) was one of the earliest webserver supporting [http2](https://searchenginewatch.com/2016/02/29/what-is-http2-and-how-does-it-affect-us/). To make the usability just a bit more convinient I packaged it as Docker image. Available at [lkwg82/h2o-http2-server](https://hub.docker.com/r/lkwg82/h2o-http2-server/) and will be kept in sync with new versions. 

## What is h2o?
   
>  H2O is a new generation HTTP server that provides quicker response to users with less CPU utilization when compared to older generation of web servers. Designed from ground-up, the server takes full advantage of HTTP/2 features including prioritized content serving and server push, promising outstanding experience to the visitors of your web site.
>
> [![alt](/img/posts/2016-03-01-8mbps100msec-nginx195-h2o_s.jpg)](/img/posts/2016-03-01-8mbps100msec-nginx195-h2o_b.jpg)[![alt](/img/posts/2016-03-01-staticfile612-nginx1910-h2o170_s.jpg)](/img/posts/2016-03-01-staticfile612-nginx1910-h2o170_b.jpg)
>

source: [https://h2o.examp1e.net/](https://h2o.examp1e.net/)

## How to do?

### a simple run 

{% highlight bash%}
$ docker run -p "8080:80" -ti lkwg82/h2o-http2-server
{% endhighlight %}

{% include asciinema.html file="2016-03-02-h2o.asciinema" %}

### with external configuration at your current location

{% highlight bash%}
$ docker run -p "8080:80" -v "$(pwd)/etc/h2o" -ti lkwg82/h2o-http2-server
{% endhighlight %}

### with [docker-compose](https://docs.docker.com/compose/overview/#content)

<figure>
        <figcaption>File: <tt>docker-compose.yml</tt></figcaption>
{% highlight yaml %}
version: '2'

services:
  h2o:
    image: lkwg82/h2o-http2-server
    ports:
       - "444:443"
    volumes:
       - "/etc/h2o:/etc/h2o"
       - "/etc/letsencrypt:/etc/letsencrypt"
       - "/var/log/h2o:/var/log/h2o"
    working_dir: /etc/h2o
    restart: always
{% endhighlight %}</figure>

and run it

{% highlight bash %}
$  docker-compose up -d --force-recreate h2o
{% endhighlight %}

As you can see in the configuration snippet for docker-compose I offer https endpoints and use the infrastructure of [letsencrypt.org](https://letsencrypt.org/). More about that in the next posts.
