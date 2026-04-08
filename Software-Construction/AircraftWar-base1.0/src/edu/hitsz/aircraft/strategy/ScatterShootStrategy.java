package edu.hitsz.aircraft.strategy;

import edu.hitsz.bullet.BaseBullet;

import java.util.LinkedList;
import java.util.List;

/**
 * 散射弹道策略
 */
public class ScatterShootStrategy extends AbstractShootStrategy {

    private final int shootNum;
    private final int spacing;
    private final int speedXStep;
    private final int speedYDelta;

    public ScatterShootStrategy() {
        this(5, 10, 2, 5);
    }

    public ScatterShootStrategy(int shootNum, int spacing, int speedXStep, int speedYDelta) {
        this.shootNum = shootNum;
        this.spacing = spacing;
        this.speedXStep = speedXStep;
        this.speedYDelta = speedYDelta;
    }

    @Override
    public List<BaseBullet> shoot(int locationX, int locationY, int speedY, int power, int direction, boolean heroBullet) {
        List<BaseBullet> res = new LinkedList<>();
        int bulletY = locationY + direction * 2;
        int bulletSpeedY = speedY + direction * speedYDelta;
        for (int i = 0; i < shootNum; i++) {
            int offset = i - shootNum / 2;
            int bulletX = locationX + offset * spacing;
            int bulletSpeedX = offset * speedXStep;
            res.add(createBullet(heroBullet, bulletX, bulletY, bulletSpeedX, bulletSpeedY, power));
        }
        return res;
    }
}
