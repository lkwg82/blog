package de.lgohlke.blog.examples;

import java.util.List;
import java.util.concurrent.CopyOnWriteArrayList;

/**
* Created by lars on 21.01.15.
*/
class DataProvider {
    private List<Consumer> consumers = new CopyOnWriteArrayList<>();

    public void subscribe(Consumer consumer) {
        consumers.add(consumer);
    }

    public void unscubscribe(Consumer consumer) {
        consumers.remove(consumer);
    }

    public List<Consumer> getConsumers() {
        return consumers;
    }
}
