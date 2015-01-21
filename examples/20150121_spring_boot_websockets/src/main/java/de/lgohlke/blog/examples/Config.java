package de.lgohlke.blog.examples;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.web.socket.WebSocketHandler;
import org.springframework.web.socket.config.annotation.EnableWebSocket;
import org.springframework.web.socket.config.annotation.WebSocketConfigurer;
import org.springframework.web.socket.config.annotation.WebSocketHandlerRegistry;

/**
 * Created by lars on 21.01.15.
 */
@Configuration
@EnableWebSocket
@EnableScheduling
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

    @Bean
    DateProvider dateProvider() {
        return new DateProvider();
    }
}
