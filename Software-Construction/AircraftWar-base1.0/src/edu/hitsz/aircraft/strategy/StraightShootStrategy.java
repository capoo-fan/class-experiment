package edu.hitsz.aircraft.strategy;

import edu.hitsz.bullet.BaseBullet;

import java.util.LinkedList;
import java.util.List;

/**
 * 直射弹道策略
 */
public class StraightShootStrategy extends AbstractShootStrategy {

    private final int shootNum;
    private final int spacing;
    private final int speedYDelta;

    public StraightShootStrategy(int shootNum) {
        this(shootNum, 10, 5);
    }

    public StraightShootStrategy(int shootNum, int spacing, int speedYDelta) {
        this.shootNum = shootNum;
        this.spacing = spacing;
        this.speedYDelta = speedYDelta;
    }

    @Override
    public List<BaseBullet> shoot(int locationX, int locationY, int speedY, int power, int direction, boolean heroBullet) {
        List<BaseBullet> res = new LinkedList<>();
        int bulletY = locationY + direction * 2;
        int bulletSpeedY = speedY + direction * speedYDelta;
        for (int i = 0; i < shootNum; i++) {
            int bulletX = locationX + (i * 2 - shootNum + 1) * spacing;
            res.add(createBullet(heroBullet, bulletX, bulletY, 0, bulletSpeedY, power));
        }
        return res;
    }
}
