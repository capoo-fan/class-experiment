package edu.hitsz.aircraft;

import edu.hitsz.application.Main;

/**
 * 敌机抽象父类
 */
public abstract class AbstractEnemy extends AbstractAircraft {

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
}
