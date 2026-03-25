package edu.hitsz.prop;

/**
 * 超级火力道具
 */
public class FirePlusSupply extends AbstractProp {

    public FirePlusSupply(int locationX, int locationY, int speedX, int speedY) {
        super(locationX, locationY, speedX, speedY);
    }

    @Override
    public void effect() {
        System.out.println("FirePlusSupply active!");
    }
}
