package edu.hitsz.aircraft;

import edu.hitsz.aircraft.strategy.ShootStrategy;
import edu.hitsz.aircraft.strategy.StraightShootStrategy;
import edu.hitsz.bullet.BaseBullet;

import java.util.List;

/**
 * 英雄飞机，游戏玩家操控
 * 
 * @author hitsz
 */
public class HeroAircraft extends AbstractAircraft {

    private static HeroAircraft instance;

    // 子弹威力
    private final int power = 30;

    // 子弹射击方向 (向上发射：-1，向下发射：1)
    private final int direction = -1;

    private ShootStrategy shootStrategy;

    private HeroAircraft(int locationX, int locationY, int speedX, int speedY, int hp) {
        super(locationX, locationY, speedX, speedY, hp);
        this.shootStrategy = new StraightShootStrategy(1);
    }

    public static synchronized HeroAircraft getInstance(int locationX, int locationY, int speedX, int speedY, int hp) {
        if (instance == null) {
            instance = new HeroAircraft(locationX, locationY, speedX, speedY, hp);
        }
        return instance;
    }

    public static synchronized HeroAircraft getInstance() {
        return instance;
    }

    public void setShootStrategy(ShootStrategy shootStrategy) {
        if (shootStrategy == null) {
            return;
        }
        this.shootStrategy = shootStrategy;
    }

    @Override
    public void forward() {
        // 英雄机由鼠标控制，不通过forward函数移动
    }

    @Override
    /**
     * 通过射击产生子弹
     * 
     * @return 射击出的子弹List
     */
    public List<BaseBullet> shoot() {
        return shootStrategy.shoot(this.getLocationX(), this.getLocationY(), this.getSpeedY(), power, direction, true);
    }

}
