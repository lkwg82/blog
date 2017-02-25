---
layout: post
title: testing dockerfiles
subtitle: a simple pragmatic approach 
date: 2017-02-23 23:23:07 CET
comments: true
categories: docker tdd devops
---

Since a while I'm facing regularly issues with images create from docker files. 
So I'm trying to develop a simple approach to test them. It is inspired basically by 
<a href="https://www.martinfowler.com/bliki/TestDrivenDevelopment.html">TDD</a>.

# concept

Let me show my approach. It is aimed to be easy to implement and easy to comprehend.

I follow these simple steps:
- creating a `Dockerfile`
- create a `test.sh` under `test/`
- run `test.sh` from `test/`


-----

# trivial example

`Dockerfile`
{% highlight docker linenos %}
{% include examples/20170224-testing-dockerfiles/simple/Dockerfile %}
{% endhighlight %}

`test.sh`
{% highlight bash linenos %}
{% include examples/20170224-testing-dockerfiles/simple/test/test.sh %}
{% endhighlight %}
 
 and the output
{% highlight bash %}
$ ./test.sh 
Sending build context to Docker daemon 3.584 kB
Step 1/2 : FROM ubuntu
 ---> f49eec89601e
Step 2/2 : CMD date
 ---> Using cache
 ---> 50149deef371
Successfully built 50149deef371
+ docker run test-simple
+ set +x
cleanup: Untagged: test-simple:latest
---------
Test: SUCCESS
{% endhighlight %}

----
# more complex example with docker-compose

This example is about an application which consists of two images, app and database.
The test is only about the app, which actually uses the database. This example is taken from [lkwg82/docker-trss](https://github.com/lkwg82/docker-ttrss/tree/8581ca27e780af2cb1bf0f4673b329f37d52b23c), 
here you can checkout and test it yourself (commit #8581ca2). 

`test/docker-compose.yml`
{% highlight yaml linenos %}
{% include examples/20170224-testing-dockerfiles/docker-ttrss/test/docker-compose.yml %}
{% endhighlight %}


`test/test.sh`
{% highlight bash linenos %}
{% include examples/20170224-testing-dockerfiles/docker-ttrss/test/test.sh%}
{% endhighlight %}
I admit any test with sleeps inside is worth inspecting and mostly due to poor design. 
At this point I make a tradeoff after 2hrs reading about :(. 

output
{% highlight bash %}
$ ./test.sh 
Sending build context to Docker daemon 23.55 kB
Step 1/18 : FROM ubuntu:14.04
 ---> b969ab9f929b
...
Successfully built d37df1479d4a
test_db_1 is up-to-date
test_db_1 is up-to-date
test_ttrss_1 is up-to-date
+ docker-compose exec ttrss curl --fail -v http://localhost:8080/
+ grep '^< HTTP/1.1 200 OK'
< HTTP/1.1 200 OK
+ docker-compose exec ttrss curl --fail -v http://localhost:8080/
+ grep '^< Set-Cookie: ttrss_sid=deleted'
< Set-Cookie: ttrss_sid=deleted; expires=Thu, 01-Jan-1970 00:00:01 GMT; Max-Age=0; path=/
+ set +x
cleanup 
-------
Test: SUCCESS
{% endhighlight %}

----

I know tooling around would make some aspects more convinient, but at least *start testing dockerfiles*!

Feedback is welcome - of course!
