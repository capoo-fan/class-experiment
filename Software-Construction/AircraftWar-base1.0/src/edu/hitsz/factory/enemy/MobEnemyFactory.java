package edu.hitsz.factory.enemy;

import edu.hitsz.aircraft.AbstractEnemy;
import edu.hitsz.aircraft.MobEnemy;
import edu.hitsz.application.ImageManager;

/**
 * 普通敌机工厂
 */
public class MobEnemyFactory extends AbstractEnemyFactory {

    @Override
    public AbstractEnemy createEnemy() {
        return new MobEnemy(
                randomSpawnX(ImageManager.MOB_ENEMY_IMAGE.getWidth()),
                randomSpawnY(),
                0,
                10,
                30);
    }
}
