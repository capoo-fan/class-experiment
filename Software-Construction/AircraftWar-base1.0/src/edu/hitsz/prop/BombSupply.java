package edu.hitsz.prop;

/**
 * 炸弹道具
 */
public class BombSupply extends AbstractProp {

    private int lastScoreReward = 0;

    public BombSupply(int locationX, int locationY, int speedX, int speedY) {
        super(locationX, locationY, speedX, speedY);
    }

    @Override
    public void effect() {
        lastScoreReward = notifyBombObservers();
        System.out.println("BombSupply active!");
    }

    public int consumeScoreReward() {
        int reward = lastScoreReward;
        lastScoreReward = 0;
        return reward;
    }
}
