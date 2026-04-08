package edu.hitsz.factory.enemy;

import edu.hitsz.aircraft.AbstractEnemy;
import edu.hitsz.aircraft.BossEnemy;
import edu.hitsz.application.ImageManager;

/**
 * Boss 敌机工厂
 */
public class BossEnemyFactory extends AbstractEnemyFactory {

    @Override
    public AbstractEnemy createEnemy() {
        return new BossEnemy(
                randomSpawnX(ImageManager.BOSS_ENEMY_IMAGE.getWidth()),
                randomSpawnY(),
                randomSideSpeed(2, 3),
                0,
                220);
    }
}
