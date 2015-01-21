package de.lgohlke.blog.examples;

import org.json.JSONObject;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.TextWebSocketHandler;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.CopyOnWriteArrayList;

/**
 * Created by lars on 21.01.15.
 */
class MyTextWebSocketHandler extends TextWebSocketHandler {
    private static final Logger LOG = LoggerFactory.getLogger(MyTextWebSocketHandler.class);

    private List<WebSocketSession> sessions = new CopyOnWriteArrayList<>();
    private Map<WebSocketSession, Map<Consumer, DateProvider>> sessionConsumer = new HashMap<>();
    private DateProvider dateProvider;

    public MyTextWebSocketHandler(DateProvider dateProvider) {
        this.dateProvider = dateProvider;
    }

    @Override
    public void afterConnectionEstablished(WebSocketSession session) throws Exception {
        sessions.add(session);
    }

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
