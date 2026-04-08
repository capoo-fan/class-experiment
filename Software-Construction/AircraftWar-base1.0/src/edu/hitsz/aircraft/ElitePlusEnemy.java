package edu.hitsz.aircraft;

import edu.hitsz.aircraft.strategy.ShootStrategy;
import edu.hitsz.aircraft.strategy.StraightShootStrategy;
import edu.hitsz.bullet.BaseBullet;

import java.util.List;

/**
 * 强化精英敌机
 */
public class ElitePlusEnemy extends AbstractEnemy {

    private final int power = 15;
    private final int direction = 1;
    private final ShootStrategy shootStrategy;

    public ElitePlusEnemy(int locationX, int locationY, int speedX, int speedY, int hp) {
        super(locationX, locationY, speedX, speedY, hp);
        this.shootStrategy = new StraightShootStrategy(2);
    }

    @Override
    public List<BaseBullet> shoot() {
        return shootStrategy.shoot(this.getLocationX(), this.getLocationY(), this.getSpeedY(), power, direction, false);
    }
}
