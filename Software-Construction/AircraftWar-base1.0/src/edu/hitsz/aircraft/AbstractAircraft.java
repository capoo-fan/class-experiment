package edu.hitsz.aircraft;

import edu.hitsz.bullet.BaseBullet;
import edu.hitsz.basic.AbstractFlyingObject;
import java.util.List;

/**
 * 所有种类飞机的抽象父类
 * 
 * @author hitsz
 */
public abstract class AbstractAircraft extends AbstractFlyingObject {

    // 最大生命值
    protected int maxHp;
    protected int hp;

    public AbstractAircraft(int locationX, int locationY, int speedX, int speedY, int hp) {
        super(locationX, locationY, speedX, speedY);
        this.hp = hp;
        this.maxHp = hp;
    }

    public void decreaseHp(int decrease) {
        hp -= decrease;
        if (hp <= 0) {
            hp = 0;
            vanish();
        }
    }

    public int getHp() {
        return hp;
    }

    public void increaseHp(int increase) {
        hp += increase;
        if (hp > maxHp) {
            hp = maxHp;
        }
    }

    public void scaleHp(double factor) {
        if (factor <= 0) {
            return;
        }
        int newMaxHp = Math.max(1, (int) Math.round(maxHp * factor));
        maxHp = newMaxHp;
        hp = Math.min(newMaxHp, Math.max(1, (int) Math.round(hp * factor)));
    }

    /**
     * 飞机射击方法
     * 
     * @return
     *         可射击对象需实现，返回子弹列表
     *         非可射击对象空实现，返回空列表
     */
    public abstract List<BaseBullet> shoot();

}
