package edu.hitsz.prop;

import edu.hitsz.application.Main;
import edu.hitsz.basic.AbstractFlyingObject;
import edu.hitsz.observer.PropObserver;
import edu.hitsz.observer.PropSubject;

import java.util.ArrayList;
import java.util.Collection;
import java.util.List;

/**
 * 道具抽象父类
 */
public abstract class AbstractProp extends AbstractFlyingObject implements PropSubject {

    private final List<PropObserver> observers = new ArrayList<>();

    public AbstractProp(int locationX, int locationY, int speedX, int speedY) {
        super(locationX, locationY, speedX, speedY);
    }

    @Override
    public void forward() {
        super.forward();
        if (locationY >= Main.WINDOW_HEIGHT) {
            vanish();
        }
    }

    public abstract void effect();

    @Override
    public void addObserver(PropObserver observer) {
        if (observer == null || observers.contains(observer)) {
            return;
        }
        observers.add(observer);
    }

    public void addObservers(Collection<?> candidates) {
        if (candidates == null || candidates.isEmpty()) {
            return;
        }
        for (Object candidate : candidates) {
            if (candidate instanceof PropObserver) {
                addObserver((PropObserver) candidate);
            }
        }
    }

    @Override
    public void removeObserver(PropObserver observer) {
        observers.remove(observer);
    }

    @Override
    public void clearObservers() {
        observers.clear();
    }

    protected int notifyBombObservers() {
        int reward = 0;
        for (PropObserver observer : observers) {
            reward += observer.onBombEffect();
        }
        return reward;
    }

    protected void notifyFreezeObservers() {
        for (PropObserver observer : observers) {
            observer.onFreezeEffect();
        }
    }
}
