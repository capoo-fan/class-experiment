package edu.hitsz.application;

/**
 * Easy difficulty game.
 */
public class EasyGame extends Game {

    public EasyGame() {
        super(GameDifficulty.EASY);
    }

    @Override
    protected void initDifficultySettings() {
        enemyMaxNumber = 4;
        enemySpawnCycle = 24;
        heroShootCycle = 18;
        enemyShootCycle = 26;
        enemySpawnWeights = new double[] { 0.60, 0.20, 0.15, 0.05 };
        enemySpeedScale = 0.90;
        enemyHpScale = 0.90;
        difficultyIncreaseIntervalMs = Long.MAX_VALUE;
    }

    @Override
    protected boolean isBossEnabled() {
        return false;
    }
}
