package edu.hitsz.aircraft;

import edu.hitsz.aircraft.strategy.ScatterShootStrategy;
import edu.hitsz.aircraft.strategy.ShootStrategy;
import edu.hitsz.bullet.BaseBullet;

import java.util.List;

/**
 * 进阶精英敌机
 */
public class EliteProEnemy extends AbstractEnemy {

    private static final int BOMB_DAMAGE = 30;

    private final int power = 18;
    private final int direction = 1;
    private final ShootStrategy shootStrategy;

    public EliteProEnemy(int locationX, int locationY, int speedX, int speedY, int hp) {
        super(locationX, locationY, speedX, speedY, hp);
        this.shootStrategy = new ScatterShootStrategy(3, 10, 2, 5);
    }

    @Override
    public List<BaseBullet> shoot() {
        return shootStrategy.shoot(this.getLocationX(), this.getLocationY(), this.getSpeedY(), power, direction, false);
    }

    @Override
    public int onBombEffect() {
        if (notValid()) {
            return 0;
        }
        decreaseHp(BOMB_DAMAGE);
        return 0;
    }

    @Override
    public void onFreezeEffect() {
        if (notValid()) {
            return;
        }
        slowForMillis(0.5, 5_000L);
    }
}
