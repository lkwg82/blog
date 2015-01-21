package de.lgohlke.blog.examples;

import org.eclipse.jetty.websocket.api.Session;
import org.eclipse.jetty.websocket.api.annotations.*;
import org.eclipse.jetty.websocket.client.ClientUpgradeRequest;
import org.eclipse.jetty.websocket.client.WebSocketClient;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.test.SpringApplicationConfiguration;
import org.springframework.boot.test.WebIntegrationTest;
import org.springframework.test.annotation.DirtiesContext;
import org.springframework.test.context.junit4.SpringJUnit4ClassRunner;

import java.net.URI;
import java.util.ArrayList;
import java.util.List;
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

    public void cleanup() throws Exception {
        client.stop();
    }

    @Test
    public void testConnect() throws Exception {

        Future<Session> sessionFuture = client.connect(socket, uri, new ClientUpgradeRequest());
        sessionFuture.get(5, TimeUnit.SECONDS);
        assertThat(socket.isConnected()).isTrue();
    }


    @Test
    public void testProtocol() throws Exception {
        Future<Session> sessionFuture = client.connect(socket, uri, new ClientUpgradeRequest());
        Session session = sessionFuture.get(5, TimeUnit.SECONDS);

        session.getRemote().sendString("{type:'subscribe',subscription:'time'}");
        TimeUnit.SECONDS.sleep(1);

        session.getRemote().sendString("{type:'unsubscribe',subscription:'time'}");
        TimeUnit.SECONDS.sleep(1);

        assertThat(socket.getMessages()).hasSize(3);

        session.close();
        TimeUnit.MILLISECONDS.sleep(100);
        assertThat(socket.isConnected()).isFalse();
    }

    @WebSocket
    public static class SimpleWebSocket {
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
}