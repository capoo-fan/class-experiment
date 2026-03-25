package edu.hitsz.prop;

/**
 * 炸弹道具
 */
public class BombSupply extends AbstractProp {

    public BombSupply(int locationX, int locationY, int speedX, int speedY) {
        super(locationX, locationY, speedX, speedY);
    }

    @Override
    public void effect() {
        System.out.println("BombSupply active!");
    }
}
