package edu.hitsz.factory.enemy;

import edu.hitsz.aircraft.AbstractEnemy;
import edu.hitsz.aircraft.ElitePlusEnemy;
import edu.hitsz.application.ImageManager;

/**
 * 精锐敌机工厂
 */
public class ElitePlusEnemyFactory extends AbstractEnemyFactory {

    @Override
    public AbstractEnemy createEnemy() {
        return new ElitePlusEnemy(
                randomSpawnX(ImageManager.ELITE_PLUS_ENEMY_IMAGE.getWidth()),
                randomSpawnY(),
                randomSideSpeed(2, 3),
                7,
                55);
    }
}
