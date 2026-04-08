package edu.hitsz.prop;

import edu.hitsz.aircraft.HeroAircraft;
import edu.hitsz.aircraft.strategy.ScatterShootStrategy;

/**
 * 火力道具
 */
public class FireSupply extends AbstractProp {

    public FireSupply(int locationX, int locationY, int speedX, int speedY) {
        super(locationX, locationY, speedX, speedY);
    }

    @Override
    public void effect() {
        HeroAircraft heroAircraft = HeroAircraft.getInstance();
        if (heroAircraft != null) {
            heroAircraft.setShootStrategy(new ScatterShootStrategy());
        }
        System.out.println("FireSupply active! Hero strategy -> ScatterShootStrategy");
    }
}
