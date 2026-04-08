package edu.hitsz.aircraft.strategy;

import edu.hitsz.bullet.BaseBullet;
import edu.hitsz.bullet.EnemyBullet;
import edu.hitsz.bullet.HeroBullet;

/**
 * 射击策略抽象基类，封装子弹创建细节
 */
public abstract class AbstractShootStrategy implements ShootStrategy {

    protected BaseBullet createBullet(boolean heroBullet, int x, int y, int speedX, int speedY, int power) {
        if (heroBullet) {
            return new HeroBullet(x, y, speedX, speedY, power);
        }
        return new EnemyBullet(x, y, speedX, speedY, power);
    }
}
