package edu.hitsz.prop;

/**
 * 加血道具
 */
public class BloodSupply extends AbstractProp {

    public BloodSupply(int locationX, int locationY, int speedX, int speedY) {
        super(locationX, locationY, speedX, speedY);
    }

    @Override
    public void effect() {
        System.out.println("BloodSupply active!");
    }
}
