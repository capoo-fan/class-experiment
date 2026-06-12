package edu.hitsz.factory.enemy;

import edu.hitsz.aircraft.AbstractEnemy;
import edu.hitsz.aircraft.EliteEnemy;
import edu.hitsz.application.ImageManager;

/**
 * 精英敌机工厂
 */
public class EliteEnemyFactory extends AbstractEnemyFactory {

    @Override
    public AbstractEnemy createEnemy() {
        return new EliteEnemy(
                randomSpawnX(ImageManager.ELITE_ENEMY_IMAGE.getWidth()),
                randomSpawnY(),
                0,
                8,
                45);
    }
}
