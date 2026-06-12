package edu.hitsz.application;

/**
 * Normal difficulty game.
 */
public class NormalGame extends Game {

    public NormalGame() {
        super(GameDifficulty.NORMAL);
    }

    @Override
    protected void initDifficultySettings() {
        enemyMaxNumber = 5;
        enemySpawnCycle = 20;
        heroShootCycle = 20;
        enemyShootCycle = 20;
        enemySpawnWeights = new double[] { 0.35, 0.25, 0.20, 0.20 };
        enemySpeedScale = 1.00;
        enemyHpScale = 1.00;
        difficultyIncreaseIntervalMs = 20_000L;
    }

    @Override
    protected void updateDifficultyProgress() {
        if (!shouldIncreaseDifficulty()) {
            return;
        }
        difficultyLevel += 1;
        enemySpawnCycle = Math.max(12, enemySpawnCycle - 1);
        enemySpeedScale = Math.min(1.60, enemySpeedScale + 0.05);
        enemyHpScale = Math.min(1.60, enemyHpScale + 0.05);

        System.out.printf(
                "普通难度提升：等级=%d, 敌机周期=%d, 速度倍率=%.2f, 血量倍率=%.2f%n",
                difficultyLevel, enemySpawnCycle, enemySpeedScale, enemyHpScale);
    }
}
