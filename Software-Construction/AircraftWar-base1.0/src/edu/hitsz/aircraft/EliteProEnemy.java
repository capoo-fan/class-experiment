package edu.hitsz.aircraft;

import edu.hitsz.bullet.BaseBullet;
import edu.hitsz.bullet.EnemyBullet;

import java.util.LinkedList;
import java.util.List;

/**
 * 进阶精英敌机
 */
public class EliteProEnemy extends AbstractEnemy {

    private int shootNum = 3;
    private int power = 18;
    private int direction = 1;
    private int spreadSpeedX = 2;

    public EliteProEnemy(int locationX, int locationY, int speedX, int speedY, int hp) {
        super(locationX, locationY, speedX, speedY, hp);
    }

    @Override
    public List<BaseBullet> shoot() {
        List<BaseBullet> res = new LinkedList<>();
        int x = this.getLocationX();
        int y = this.getLocationY() + direction * 2;
        int speedY = this.getSpeedY() + direction * 5;
        for (int i = 0; i < shootNum; i++) {
            int bulletX = x + (i - shootNum / 2) * 10;
            int bulletSpeedX = (i - shootNum / 2) * spreadSpeedX;
            BaseBullet bullet = new EnemyBullet(bulletX, y, bulletSpeedX, speedY, power);
            res.add(bullet);
        }
        return res;
    }
}
