package de.lgohlke.blog.examples;

import org.springframework.scheduling.annotation.Scheduled;

import java.util.Date;

/**
* Created by lars on 21.01.15.
*/
class DateProvider extends DataProvider {

    @Scheduled(fixedRate = 1000)
    public void onEvent() {
        Date date = new Date();
        getConsumers().forEach(consumer -> {
            consumer.sendData("{ type: 'date', data: '" + date + "'}");
        });
    }
}
