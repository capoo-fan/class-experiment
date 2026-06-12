package edu.hitsz.aircraft;

import edu.hitsz.application.Main;
import edu.hitsz.observer.PropObserver;

/**
 * 敌机抽象父类
 */
public abstract class AbstractEnemy extends AbstractAircraft implements PropObserver {

    protected int scoreValue = 10;

    public AbstractEnemy(int locationX, int locationY, int speedX, int speedY, int hp) {
        super(locationX, locationY, speedX, speedY, hp);
    }

    @Override
    public void forward() {
        super.forward();
        // 敌机向下飞行出界后失效
        if (locationY >= Main.WINDOW_HEIGHT) {
            vanish();
        }
    }

    public int getScoreValue() {
        return scoreValue;
    }

    @Override
    public int onBombEffect() {
        if (notValid()) {
            return 0;
        }
        vanish();
        return scoreValue;
    }

    protected void freezeForMillis(long durationMs) {
        applyFreeze(durationMs);
    }

    protected void freezeForever() {
        applyFreeze(0L);
    }

    protected void slowForMillis(double factor, long durationMs) {
        applySlowdown(factor, durationMs);
    }
}
