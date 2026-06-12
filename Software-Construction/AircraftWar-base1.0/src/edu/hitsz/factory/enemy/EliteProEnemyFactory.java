package edu.hitsz.factory.enemy;

import edu.hitsz.aircraft.AbstractEnemy;
import edu.hitsz.aircraft.EliteProEnemy;
import edu.hitsz.application.ImageManager;

/**
 * 王牌敌机工厂
 */
public class EliteProEnemyFactory extends AbstractEnemyFactory {

    @Override
    public AbstractEnemy createEnemy() {
        return new EliteProEnemy(
                randomSpawnX(ImageManager.ELITE_PRO_ENEMY_IMAGE.getWidth()),
                randomSpawnY(),
                randomSideSpeed(3, 4),
                6,
                65);
    }
}
