---
title: "Websockets mit Spring-Boot und Jetty - Publish/Subscribe"
date: 2015-01-21T14:23:07Z
lastmod: 2015-01-21T14:23:07Z
draft: false
tags: ["websockets", "java"]
---

Hier mein kleines Tutorial wie man mit spring-boot und jetty's websocket Client ein Publish/Subscribe Szenario implementieren kann. 


**Inhalt**

1. [Simples Hello-World mit "welcome"](#hw)
1. [Simples publish/subscribe um Zeitinformation zu erhalten](#ps)

## Simples Hello-World mit "welcome" {#hw}

Die Idee ist, sich in Java sowohl auf Server- als auch auf Client-Seite mittels Websockets zu verbinden. Nach dem erfolgreichen Verbindungsaufbau sendet der Server eine Nachricht mit dem Text `welcome` als Inhalt.

Hier die `pom.xml`:
```xml
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>de.lgohlke.blog.examples</groupId>
    <artifactId>springbootwebsockets</artifactId>
    <version>0.1.0</version>

    <prerequisites>
        <maven>3</maven>
    </prerequisites>

    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>1.2.1.RELEASE</version>
    </parent>

    <properties>
        <java.version>8</java.version>
    </properties>

    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-websocket</artifactId>
        </dependency>
        <dependency>
            <groupId>org.eclipse.jetty.websocket</groupId>
            <artifactId>websocket-client</artifactId>
            <version>${jetty.version}</version>
        </dependency>

        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>
        <dependency>
            <groupId>org.assertj</groupId>
            <artifactId>assertj-core</artifactId>
            <version>1.7.1</version>
            <scope>test</scope>
        </dependency>
        <dependency>
            <groupId>org.json</groupId>
            <artifactId>json</artifactId>
            <version>20140107</version>
        </dependency>
    </dependencies>
</project>
```

die spring configuration `config.java`
```java
@Configuration
@EnableWebSocket
public class Config {

    @Bean
    WebSocketConfigurer webSocketConfigurer(final WebSocketHandler webSocketHandler) {
        return new WebSocketConfigurer() {
            @Override
            public void registerWebSocketHandlers(WebSocketHandlerRegistry registry) {
                registry.addHandler(webSocketHandler, "/ws/test");
            }
        };
    }

    @Bean
    WebSocketHandler myWebsocketHandler(DateProvider dateProvider) {
        return new MyTextWebSocketHandler(dateProvider);
    }
}
```

Ein einfacher Websockethandler für Textnachrichten kann dann so aussehen.
```java
class MyTextWebSocketHandler extends TextWebSocketHandler {
    private List<WebSocketSession> sessions = new CopyOnWriteArrayList<>();

    @Override
    public void afterConnectionEstablished(WebSocketSession session) throws Exception {
        sessions.add(session);
        session.sendMessage(new TextMessage("{message:'welcome'}"));
    }

    @Override
    public void afterConnectionClosed(WebSocketSession session, CloseStatus status) throws Exception {
        sessions.remove(session);
    }

    @Override
    protected void handleTextMessage(WebSocketSession session, TextMessage message) throws Exception {
    }
}
```

Nach jedem Verbindungsaufbau wird eine Willkommensnachricht verschickt.

Der Test dazu würde so aussehen:

```java

@RunWith(SpringJUnit4ClassRunner.class)
@WebIntegrationTest(randomPort = true)
@SpringApplicationConfiguration(classes = Application.class)
@DirtiesContext
public class MyTextWebSocketHandlerTest {
    @Value("${local.server.port}")
    private int port;

    private WebSocketClient client; // from jetty
    private SimpleWebSocket socket; // pojo with some annotation
    private URI uri;

    @Before
    public void setup() throws Exception {
        client = new WebSocketClient();
        socket = new SimpleWebSocket();
        uri = new URI("ws://localhost:" + port + "/ws/test");
        client.start();
    }

    public void cleanup() throws Exception {
        client.stop();
    }

    @Test
    public void testConnect() throws Exception {

        Future<Session> sessionFuture = client.connect(socket, uri, new ClientUpgradeRequest());
        sessionFuture.get(5, TimeUnit.SECONDS);

        // message exchange need some time
        TimeUnit.MILLISECONDS.sleep(500);
        assertThat(socket.getMessages().get(0)).isEqualTo("welcome");

        assertThat(socket.isConnected()).isTrue();
    }
}
```

Der von Client ben&ouml;tigte Websocket in der `SimpleWebSocket.java`:
```java
@WebSocket
public class SimpleWebSocket {
    private Session session;
    private List<String> messages = new ArrayList<>();

    @OnWebSocketClose
    public void onClose(int statusCode, String reason) {
        System.out.printf("Connection closed: %d - %s%n", statusCode, reason);
        session = null;
    }

    @OnWebSocketConnect
    public void onConnect(Session session) {
        System.out.printf("Got connect: %s%n", session);
        this.session = session;
    }

    @OnWebSocketError
    public void onError(Session session, Throwable throwable) {
        System.err.println("error:" + throwable.getMessage());
    }

    @OnWebSocketMessage
    public void onMessage(String msg) {
        System.out.printf("Got msg: %s%n", msg);
        messages.add(msg);
    }

    public boolean isConnected() {
        return session != null && session.isOpen();
    }

    public List<String> getMessages() {
        return messages;
    }
}
```

Abschließend für das erste "Hello-World" der Aufruf des Tests durch Maven und die passende Ausgabe mit Auslassungen (...):
```bash
$ mvn test -Dtest=MyTextWebSocketHandlerTest#testConnect
[INFO] Scanning for projects...
[INFO]
[INFO] ------------------------------------------------------------------------
[INFO] Building springbootwebsockets 0.1.0
[INFO] ------------------------------------------------------------------------
...

-------------------------------------------------------
 T E S T S
-------------------------------------------------------
Running de.lgohlke.blog.examples.MyTextWebSocketHandlerTest
...
  .   ____          _            __ _ _
 /\\ / ___'_ __ _ _(_)_ __  __ _ \ \ \ \
( ( )\___ | '_ | '_| | '_ \/ _` | \ \ \ \
 \\/  ___)| |_)| | | | | || (_| |  ) ) ) )
  '  |____| .__|_| |_|_| |_\__, | / / / /
 =========|_|==============|___/=/_/_/_/
 :: Spring Boot ::        (v1.2.1.RELEASE)

...
Got connect: WebSocketSession[websocket=...]
Got msg: welcome
...
Tests run: 1, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 2.474 sec - in de.lgohlke.blog.examples.MyTextWebSocketHandlerTest

Results :

Tests run: 1, Failures: 0, Errors: 0, Skipped: 0

[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
...
```

&nbsp;

## Simples publish/subscribe um Zeitinformation zu erhalten {#ps}

Jetzt soll es darum gehen mit einem rudimentären Protokoll sich für die Zeitansage anzumelden.

Der Kommunikationsablauf (S:Server, C=Client):

- C: baut Verbindung auf
- S: antwortet mit `welcome`
- C: schickt seine Anmeldung für das Thema 'time' `{type:'subscribe',subscription:'time'}`
- S: antwortet mit `{type:'info',message: 'subscribed to time'}`
- S: schickt regelmäßig Daten wofür sich C eingeschrieben hat `{ type: 'date', data: 'Wed Jan 21 16:46:57 CET 2015'}`
- C: meldet sich vom Thema 'time' ab: `{type:'unsubscribe',subscription:'time'}`
- C: meldet sich vom Thema 'time' ab: `{type:'unsubscribe',subscription:'time'}`
- S: antwortet mit `{type:'info',message: 'unsubscribed from time'}`
- C: beendet die Verbindung

Ich werde jetzt noch neue Klassen bzw. die Erweiterungen pro Klasse zeigen.

```java
class MyTextWebSocketHandler extends TextWebSocketHandler {
    private static final Logger LOG = LoggerFactory.getLogger(MyTextWebSocketHandler.class);

    // ...

    private Map<WebSocketSession, Map<Consumer, DateProvider>> sessionConsumer = new HashMap<>();
    private DateProvider dateProvider;

    public MyTextWebSocketHandler(DateProvider dateProvider) {
        this.dateProvider = dateProvider;
    }

    // ...

    @Override
    public void afterConnectionClosed(WebSocketSession session, CloseStatus status) throws Exception {
        if (sessionConsumer.containsKey(session)) {
            sessionConsumer.get(session).forEach((consumer, dateProvider) -> {
                dateProvider.unscubscribe(consumer);
            });
            sessionConsumer.remove(session);
        }
        sessions.remove(session);
    }

    @Override
    protected void handleTextMessage(WebSocketSession session, TextMessage message) throws Exception {
        String payload = message.getPayload();
        JSONObject jsonObject = new JSONObject(payload);
        String type = jsonObject.getString("type");

        if ("subscribe".equals(type)) {
            String subscription = jsonObject.getString("subscription");
            if ("time".equals(subscription)) {
                LOG.info("{} subscribed to {}", session.getId(), subscription);
                WebsocketTextConsumer consumer = new WebsocketTextConsumer(session);
                dateProvider.subscribe(consumer);

                if (!sessionConsumer.containsKey(session)) {
                    sessionConsumer.put(session, new HashMap<>());
                }
                sessionConsumer.get(session).put(consumer, dateProvider);

                session.sendMessage(new TextMessage("{type:'info',message: 'subscribed to time'}"));
            } else {
                LOG.warn("invalid subscription '{}'", subscription);
            }
        } else {
            if ("unsubscribe".equals(type)) {
                String subscription = jsonObject.getString("subscription");
                if ("time".equals(subscription)) {
                    LOG.info("{} subscribed to {}", session.getId(), subscription);

                    // not checking if formerly subscribed
                    if (sessionConsumer.containsKey(session)) {
                        sessionConsumer.get(session).forEach((consumer, provider) -> {
                            provider.unscubscribe(consumer);
                        });
                    }
                    session.sendMessage(new TextMessage("{type:'info',message: 'unsubscribed from time'}"));
                } else {
                    LOG.warn("invalid subscription '{}'", subscription);
                }
            }
        }
    }
}
```

```java
public class WebsocketTextConsumer implements Consumer {
    private static final Logger LOG = LoggerFactory.getLogger(WebsocketTextConsumer.class);
    private WebSocketSession session;

    public WebsocketTextConsumer(WebSocketSession session) {
        this.session = session;
    }

    @Override
    public void sendData(String json) {
        try {
            if (session.isOpen()) {
                session.sendMessage(new TextMessage(json));
            }else{
                LOG.info("session closed");
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}
```

```java
class DateProvider extends DataProvider {
    @Scheduled(fixedRate = 1000)
    public void onEvent() {
        Date date = new Date();
        getConsumers().forEach(consumer -> {
            consumer.sendData("{ type: 'date', data: '" + date + "'}");
        });
    }
}
```

Der Test muss demzufolge so erweitert werden:
```java
public class MyTextWebSocketHandlerTest {

    // ...

    @Test
    public void testProtocol() throws Exception {
        Future<Session> sessionFuture = client.connect(socket, uri, new ClientUpgradeRequest());
        Session session = sessionFuture.get(5, TimeUnit.SECONDS);

        session.getRemote().sendString("{type:'subscribe',subscription:'time'}");
        // we need to wait for time-tick - at least 1s
        TimeUnit.SECONDS.sleep(1);

        session.getRemote().sendString("{type:'unsubscribe',subscription:'time'}");
        TimeUnit.MILLISECONDS.sleep(800);

        assertThat(socket.getMessages()).hasSize(4);

        session.close();
        TimeUnit.MILLISECONDS.sleep(100);
        assertThat(socket.isConnected()).isFalse();
    }
}
```

Und heraus kommt:

```bash
$ mvn test -Dtest=MyTextWebSocketHandlerTest#testProtocol
[INFO] Scanning for projects...
...
-------------------------------------------------------
 T E S T S
-------------------------------------------------------
Running de.lgohlke.blog.examples.MyTextWebSocketHandlerTest
...
  .   ____          _            __ _ _
 /\\ / ___'_ __ _ _(_)_ __  __ _ \ \ \ \
( ( )\___ | '_ | '_| | '_ \/ _` | \ \ \ \
 \\/  ___)| |_)| | | | | || (_| |  ) ) ) )
  '  |____| .__|_| |_|_| |_\__, | / / / /
 =========|_|==============|___/=/_/_/_/
 :: Spring Boot ::        (v1.2.1.RELEASE)
...
Got connect: WebSocketSession[websocket=...]
Got msg: welcome
2015-01-21 20:06:57.812  INFO 10817 --- [o-auto-1-exec-2] d.l.b.examples.MyTextWebSocketHandler    : 0 subscribed to time
Got msg: {type:'info',message: 'subscribed to time'}
Got msg: { type: 'date', data: 'Wed Jan 21 20:06:58 CET 2015'}
2015-01-21 20:06:58.810  INFO 10817 --- [o-auto-1-exec-3] d.l.b.examples.MyTextWebSocketHandler    : 0 subscribed to time
Got msg: {type:'info',message: 'unsubscribed from time'}
Connection closed: 1000 - null
...
Tests run: 1, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 3.996 sec - in de.lgohlke.blog.examples.MyTextWebSocketHandlerTest

Results :

Tests run: 1, Failures: 0, Errors: 0, Skipped: 0

[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
...
```

