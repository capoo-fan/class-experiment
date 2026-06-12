package edu.hitsz.aircraft.strategy;

import edu.hitsz.bullet.BaseBullet;

import java.util.LinkedList;
import java.util.List;

/**
 * 环射弹道策略
 */
public class CircleShootStrategy extends AbstractShootStrategy {

    private final int bulletNum;
    private final int bulletSpeed;

    public CircleShootStrategy() {
        this(20, 6);
    }

    public CircleShootStrategy(int bulletNum, int bulletSpeed) {
        this.bulletNum = bulletNum;
        this.bulletSpeed = bulletSpeed;
    }

    @Override
    public List<BaseBullet> shoot(int locationX, int locationY, int speedY, int power, int direction, boolean heroBullet) {
        List<BaseBullet> res = new LinkedList<>();
        int bulletY = locationY + direction * 2;
        for (int i = 0; i < bulletNum; i++) {
            double angle = 2 * Math.PI * i / bulletNum;
            int bulletSpeedX = (int) Math.round(bulletSpeed * Math.cos(angle));
            int bulletSpeedY = (int) Math.round(bulletSpeed * Math.sin(angle)) + speedY;
            if (bulletSpeedX == 0 && bulletSpeedY == 0) {
                bulletSpeedY = direction >= 0 ? bulletSpeed : -bulletSpeed;
            }
            res.add(createBullet(heroBullet, locationX, bulletY, bulletSpeedX, bulletSpeedY, power));
        }
        return res;
    }
}
