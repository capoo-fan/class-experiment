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

    private final ShootStrategy defaultShootStrategy;
    private ShootStrategy shootStrategy;
    private long temporaryStrategyExpireAt = -1L;

    private HeroAircraft(int locationX, int locationY, int speedX, int speedY, int hp) {
        super(locationX, locationY, speedX, speedY, hp);
        this.defaultShootStrategy = new StraightShootStrategy(1);
        this.shootStrategy = defaultShootStrategy;
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

    public synchronized void setShootStrategy(ShootStrategy shootStrategy) {
        if (shootStrategy == null) {
            return;
        }
        this.shootStrategy = shootStrategy;
        this.temporaryStrategyExpireAt = -1L;
    }

    public synchronized void setShootStrategyForDuration(ShootStrategy shootStrategy, long durationMillis) {
        if (shootStrategy == null || durationMillis <= 0) {
            return;
        }
        this.shootStrategy = shootStrategy;

        long now = System.currentTimeMillis();
        long base = Math.max(now, temporaryStrategyExpireAt);
        temporaryStrategyExpireAt = base + durationMillis;
    }

    public synchronized void refreshShootStrategy() {
        if (temporaryStrategyExpireAt < 0) {
            return;
        }
        if (System.currentTimeMillis() < temporaryStrategyExpireAt) {
            return;
        }

        shootStrategy = defaultShootStrategy;
        temporaryStrategyExpireAt = -1L;
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
    public synchronized List<BaseBullet> shoot() {
        refreshShootStrategy();
        return shootStrategy.shoot(this.getLocationX(), this.getLocationY(), this.getSpeedY(), power, direction, true);
    }

}
