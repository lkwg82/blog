---
layout: post
title: sleuth valve for tomcat 
subtitle: inject header on first request for springboot avoid proxy/firewall instrumentation
date: 2017-11-26 14:00:07 CET 
comments: true
categories: sleuth tomcat spring-cloud spring-boot
---

At <a href="https://www.idealo.de">idealo</a> we do a lot of microservices with spring-boot. 
To trace request we use <a href="https://cloud.spring.io/spring-cloud-sleuth/">spring-cloud-sleuth</a> as <a href="http://opentracing.io/">opentracing</a> implementation.
I'm missing the injection of the trace header on first request. You still need to deliver those with your request. So here follows my solution…

# concept

Let me show my approach. It is aimed to be easy to implement and easy to comprehend.

I follow these simple steps:
1. add a custom tomcat valve named [SleuthValve](https://gist.github.com/lkwg82/0c19e00b65a34763a1b50d1ba26ca703#file-sleuthvalve-java)
2. configure tomcat with [LogbackValve](https://logback.qos.ch/access.html#tomcat) and SleuthValve in [AccessLogAutoConfiguration](https://gist.github.com/lkwg82/0c19e00b65a34763a1b50d1ba26ca703#file-accesslogautoconfiguration-java)
3. configure [logback-access.xml](https://gist.github.com/lkwg82/0c19e00b65a34763a1b50d1ba26ca703#file-logback-access-xml) to log traces

This really nice integrates with [logback-redis](https://github.com/idealo/logback-redis).

-----

[SleuthValve.java](https://gist.github.com/lkwg82/0c19e00b65a34763a1b50d1ba26ca703#file-sleuthvalve-java):
```java
@RequiredArgsConstructor // lombok
class SleuthValve extends ValveBase {
    private final Tracer tracer;

    @Override
    public void invoke(Request request, Response response) 
        throws IOException, ServletException {

        enrichWithSleuthHeaderWhenMissing(tracer, request);

        Valve next = getNext();
        if (null == next) {
            // no next valve
            return;
        }
        next.invoke(request, response);
    }

    private static void enrichWithSleuthHeaderWhenMissing(Tracer tracer, 
                                                          Request request) {
        String header = request.getHeader(Span.TRACE_ID_NAME);
        if (null == header) {

            org.apache.coyote.Request coyoteRequest = request.getCoyoteRequest();
            MimeHeaders mimeHeaders = coyoteRequest.getMimeHeaders();

            Span span = tracer.createSpan("SleuthValve");

            addHeader(mimeHeaders, Span.TRACE_ID_NAME, span.traceIdString());
            addHeader(mimeHeaders, Span.SPAN_ID_NAME, span.traceIdString());
        }
    }

    private static void addHeader(MimeHeaders mimeHeaders, 
                                  String traceIdName, 
                                  String value) {
        MessageBytes messageBytes = mimeHeaders.addValue(traceIdName);
        messageBytes.setString(value);
    }
}
```

See [SleuthValveTest.java](https://gist.github.com/lkwg82/0c19e00b65a34763a1b50d1ba26ca703#file-sleuthvalvetest-java) for the tests.

[AccessLogAutoConfiguration.java](https://gist.github.com/lkwg82/0c19e00b65a34763a1b50d1ba26ca703#file-accesslogautoconfiguration-java) for spring-boot:
```java
@Slf4j
@Configuration
public class AccessLogAutoConfiguration {
    @Bean
    public EmbeddedServletContainerCustomizer containerCustomizer(SleuthValve sleuthValve, 
                                                                  LogbackValve logbackValve) {
        return container -> {
            if (container instanceof TomcatEmbeddedServletContainerFactory) {
                ((TomcatEmbeddedServletContainerFactory) container)
                        .addContextCustomizers((TomcatContextCustomizer) context -> {
                            context.getPipeline().addValve(sleuthValve);
                            context.getPipeline().addValve(logbackValve);
                        });
            } else {
                log.warn("no access-log auto-configuration for container: {}", container);
            }
        };
    }

    @Bean
    public SleuthValve sleuthValve(Tracer tracer) {
        return new SleuthValve(tracer);
    }

    @Bean
    public LogbackValve logbackValve() {
        LogbackValve logbackValve = new LogbackValve();
        logbackValve.putProperty("HOSTNAME", new ContextUtil(null).safelyGetLocalHostName());
        logbackValve.setFilename("logback-access.xml");
        logbackValve.setQuiet(true);
        return logbackValve;
    }
}
```

[logback-access.xml](https://gist.github.com/lkwg82/0c19e00b65a34763a1b50d1ba26ca703#file-logback-access-xml):
```xml
<?xml version="1.0" encoding="UTF-8"?>
<configuration>

    <appender name="FILE_ACCESS" class="ch.qos.logback.core.FileAppender">
        <append>false</append>
        <file>target/logs/access.log</file>
        <encoder>
            <pattern>ACCESS ${HOSTNAME} %i{X-B3-TraceId}</pattern>
        </encoder>
    </appender>

    <appender name="CONSOLE" class="ch.qos.logback.core.ConsoleAppender">
        <encoder>
            <pattern>ACCESS ${HOSTNAME} %i{X-B3-TraceId}</pattern>
        </encoder>
    </appender>

    <appender-ref ref="CONSOLE"/>
    <appender-ref ref="FILE_ACCESS"/>

</configuration>
```
 
Hint: 
- all code is available via [gist](https://gist.github.com/lkwg82/0c19e00b65a34763a1b50d1ba26ca703)
- code uses [lombok](https://projectlombok.org/) annotation
