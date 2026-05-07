package edu.hitsz.application;

import edu.hitsz.factory.enemy.BossEnemyFactory;

/**
 * Hard difficulty game.
 */
public class HardGame extends Game {

    private static final int BOSS_HP_STEP = 30;
    private int bossSpawnCount = 0;

    public HardGame() {
        super(GameDifficulty.HARD);
    }

    @Override
    protected void initDifficultySettings() {
        enemyMaxNumber = 6;
        enemySpawnCycle = 18;
        heroShootCycle = 22;
        enemyShootCycle = 18;
        enemySpawnWeights = new double[] { 0.20, 0.25, 0.25, 0.30 };
        enemySpeedScale = 1.10;
        enemyHpScale = 1.10;
        difficultyIncreaseIntervalMs = 18_000L;
    }

    @Override
    protected int getNextBossHp() {
        return BossEnemyFactory.DEFAULT_HP + bossSpawnCount * BOSS_HP_STEP;
    }

    @Override
    protected void onBossSpawned() {
        bossSpawnCount += 1;
    }

    @Override
    protected void updateDifficultyProgress() {
        if (!shouldIncreaseDifficulty()) {
            return;
        }
        difficultyLevel += 1;
        enemySpawnCycle = Math.max(10, enemySpawnCycle - 1);
        enemySpeedScale = Math.min(1.80, enemySpeedScale + 0.07);
        enemyHpScale = Math.min(1.80, enemyHpScale + 0.07);
        heroShootCycle = Math.min(30, heroShootCycle + 1);
        enemyShootCycle = Math.max(10, enemyShootCycle - 1);

        System.out.printf(
                "困难难度提升：等级=%d, 敌机周期=%d, 速度倍率=%.2f, 血量倍率=%.2f, 英雄射击周期=%d, 敌机射击周期=%d%n",
                difficultyLevel, enemySpawnCycle, enemySpeedScale, enemyHpScale, heroShootCycle, enemyShootCycle);
    }
}
