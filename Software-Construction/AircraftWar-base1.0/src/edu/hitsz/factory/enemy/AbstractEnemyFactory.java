package edu.hitsz.factory.enemy;

import edu.hitsz.application.Main;

import java.util.concurrent.ThreadLocalRandom;

/**
 * 敌机工厂基类，封装公共的随机生成工具方法
 */
public abstract class AbstractEnemyFactory implements EnemyFactory {

    protected int randomSpawnY() {
        int upperBound = Math.max(1, (int) (Main.WINDOW_HEIGHT * 0.05));
        return ThreadLocalRandom.current().nextInt(upperBound);
    }

    protected int randomSpawnX(int imageWidth) {
        int upperBound = Math.max(1, Main.WINDOW_WIDTH - imageWidth);
        return ThreadLocalRandom.current().nextInt(upperBound);
    }

    protected int randomSideSpeed(int minAbsSpeed, int maxAbsSpeed) {
        int absSpeed = ThreadLocalRandom.current().nextInt(minAbsSpeed, maxAbsSpeed + 1);
        return ThreadLocalRandom.current().nextBoolean() ? absSpeed : -absSpeed;
    }
}
