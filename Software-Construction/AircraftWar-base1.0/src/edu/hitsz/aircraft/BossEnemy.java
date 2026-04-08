package edu.hitsz.aircraft;

import edu.hitsz.aircraft.strategy.CircleShootStrategy;
import edu.hitsz.aircraft.strategy.ShootStrategy;
import edu.hitsz.application.Main;
import edu.hitsz.bullet.BaseBullet;

import java.util.List;

/**
 * Boss 敌机
 */
public class BossEnemy extends AbstractEnemy {

    private final int power = 20;
    private final int direction = 1;
    private final ShootStrategy shootStrategy;

    public BossEnemy(int locationX, int locationY, int speedX, int speedY, int hp) {
        super(locationX, locationY, speedX, speedY, hp);
        this.shootStrategy = new CircleShootStrategy(20, 6);
    }

    @Override
    public List<BaseBullet> shoot() {
        return shootStrategy.shoot(this.getLocationX(), this.getLocationY(), this.getSpeedY(), power, direction, false);
    }

    @Override
    public void forward() {
        locationX += speedX;
        if (locationX <= 0 || locationX >= Main.WINDOW_WIDTH) {
            speedX = -speedX;
        }
    }
}
