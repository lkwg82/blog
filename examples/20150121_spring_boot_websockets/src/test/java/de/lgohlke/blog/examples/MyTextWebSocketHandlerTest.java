package de.lgohlke.blog.examples;

import org.eclipse.jetty.websocket.api.Session;
import org.eclipse.jetty.websocket.client.ClientUpgradeRequest;
import org.eclipse.jetty.websocket.client.WebSocketClient;
import org.junit.After;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.test.SpringApplicationConfiguration;
import org.springframework.boot.test.WebIntegrationTest;
import org.springframework.test.annotation.DirtiesContext;
import org.springframework.test.context.junit4.SpringJUnit4ClassRunner;

import java.net.URI;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;

import static org.assertj.core.api.Assertions.assertThat;

@RunWith(SpringJUnit4ClassRunner.class)
@WebIntegrationTest(randomPort = true)
@SpringApplicationConfiguration(classes = Application.class)
@DirtiesContext
public class MyTextWebSocketHandlerTest {
    @Value("${local.server.port}")
    private int port;


    private WebSocketClient client;
    private SimpleWebSocket socket;
    private URI uri;

    @Before
    public void setup() throws Exception {
        client = new WebSocketClient();
        socket = new SimpleWebSocket();
        uri = new URI("ws://localhost:" + port + "/ws/test");
        client.start();
    }

    @After
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