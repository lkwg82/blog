package de.lgohlke.blog.examples;

import org.eclipse.jetty.websocket.api.Session;
import org.eclipse.jetty.websocket.api.annotations.*;

import java.util.ArrayList;
import java.util.List;

/**
* Created by lars on 21.01.15.
*/
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
