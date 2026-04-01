package edu.hitsz.aircraft;

import edu.hitsz.bullet.BaseBullet;
import edu.hitsz.bullet.EnemyBullet;

import java.util.LinkedList;
import java.util.List;

/**
 * 强化精英敌机
 */
public class ElitePlusEnemy extends AbstractEnemy {

    private int shootNum = 2;
    private int power = 15;
    private int direction = 1;

    public ElitePlusEnemy(int locationX, int locationY, int speedX, int speedY, int hp) {
        super(locationX, locationY, speedX, speedY, hp);
    }

    @Override
    public List<BaseBullet> shoot() {
        List<BaseBullet> res = new LinkedList<>();
        int x = this.getLocationX();
        int y = this.getLocationY() + direction * 2;
        int speedY = this.getSpeedY() + direction * 5;
        for (int i = 0; i < shootNum; i++) {
            int bulletX = x + (i * 2 - shootNum + 1) * 10;
            BaseBullet bullet = new EnemyBullet(bulletX, y, 0, speedY, power);
            res.add(bullet);
        }
        return res;
    }
}
