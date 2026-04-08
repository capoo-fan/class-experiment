package edu.hitsz.aircraft.strategy;

import edu.hitsz.bullet.BaseBullet;

import java.util.List;

/**
 * 射击策略接口
 */
public interface ShootStrategy {

    List<BaseBullet> shoot(int locationX, int locationY, int speedY, int power, int direction, boolean heroBullet);
}
