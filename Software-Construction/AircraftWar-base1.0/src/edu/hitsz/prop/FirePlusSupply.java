package edu.hitsz.prop;

import edu.hitsz.aircraft.HeroAircraft;
import edu.hitsz.aircraft.strategy.CircleShootStrategy;

/**
 * 超级火力道具
 */
public class FirePlusSupply extends AbstractProp {

    public FirePlusSupply(int locationX, int locationY, int speedX, int speedY) {
        super(locationX, locationY, speedX, speedY);
    }

    @Override
    public void effect() {
        HeroAircraft heroAircraft = HeroAircraft.getInstance();
        if (heroAircraft != null) {
            heroAircraft.setShootStrategy(new CircleShootStrategy(20, 7));
        }
        System.out.println("FirePlusSupply active! Hero strategy -> CircleShootStrategy");
    }
}
