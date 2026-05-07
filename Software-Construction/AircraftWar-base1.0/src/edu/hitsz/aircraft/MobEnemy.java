package edu.hitsz.aircraft;

import edu.hitsz.bullet.BaseBullet;

import java.util.LinkedList;
import java.util.List;

/**
 * 普通敌机
 * 不可射击、不掉落道具
 * 
 * @author hitsz
 */
public class MobEnemy extends AbstractEnemy {

    public MobEnemy(int locationX, int locationY, int speedX, int speedY, int hp) {
        super(locationX, locationY, speedX, speedY, hp);
    }

    @Override
    public List<BaseBullet> shoot() {
        return new LinkedList<>();
    }

    @Override
    public void onFreezeEffect() {
        if (notValid()) {
            return;
        }
        freezeForever();
    }

}
