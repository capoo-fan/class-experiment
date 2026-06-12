package edu.hitsz.factory.enemy;

import edu.hitsz.aircraft.AbstractEnemy;
import edu.hitsz.aircraft.BossEnemy;
import edu.hitsz.application.ImageManager;

/**
 * Boss 敌机工厂
 */
public class BossEnemyFactory extends AbstractEnemyFactory {

    public static final int DEFAULT_HP = 220;

    @Override
    public AbstractEnemy createEnemy() {
        return createEnemyWithHp(DEFAULT_HP);
    }

    public AbstractEnemy createEnemyWithHp(int hp) {
        return new BossEnemy(
                randomSpawnX(ImageManager.BOSS_ENEMY_IMAGE.getWidth()),
                randomSpawnY(),
                randomSideSpeed(2, 3),
                0,
                hp);
    }
}
