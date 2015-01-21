package de.lgohlke.blog.examples;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;

import java.io.IOException;

/**
 * Created by lars on 21.01.15.
 */
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
