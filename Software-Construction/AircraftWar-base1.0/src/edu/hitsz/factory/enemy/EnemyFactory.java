package edu.hitsz.factory.enemy;

import edu.hitsz.aircraft.AbstractEnemy;

/**
 * 敌机工厂方法接口
 */
public interface EnemyFactory {
    AbstractEnemy createEnemy();
}
