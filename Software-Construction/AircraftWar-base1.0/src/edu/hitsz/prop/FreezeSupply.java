package edu.hitsz.prop;

/**
 * 冰冻道具
 */
public class FreezeSupply extends AbstractProp {

    public FreezeSupply(int locationX, int locationY, int speedX, int speedY) {
        super(locationX, locationY, speedX, speedY);
    }

    @Override
    public void effect() {
        System.out.println("FreezeSupply active!");
    }
}
