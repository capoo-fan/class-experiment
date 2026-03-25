package edu.hitsz.prop;

/**
 * 火力道具
 */
public class FireSupply extends AbstractProp {

    public FireSupply(int locationX, int locationY, int speedX, int speedY) {
        super(locationX, locationY, speedX, speedY);
    }

    @Override
    public void effect() {
        System.out.println("FireSupply active!");
    }
}
