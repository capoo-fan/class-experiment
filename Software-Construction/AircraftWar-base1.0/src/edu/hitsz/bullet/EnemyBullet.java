package edu.hitsz.bullet;

import edu.hitsz.observer.PropObserver;

/**
 * 敌机子弹
 * @Author hitsz
 */
public class EnemyBullet extends BaseBullet implements PropObserver {

    private static final long FREEZE_DURATION_MS = 5_000L;

    public EnemyBullet(int locationX, int locationY, int speedX, int speedY, int power) {
        super(locationX, locationY, speedX, speedY, power);
    }

    @Override
    public int onBombEffect() {
        if (notValid()) {
            return 0;
        }
        vanish();
        return 0;
    }

    @Override
    public void onFreezeEffect() {
        if (notValid()) {
            return;
        }
        applyFreeze(FREEZE_DURATION_MS);
    }

}
