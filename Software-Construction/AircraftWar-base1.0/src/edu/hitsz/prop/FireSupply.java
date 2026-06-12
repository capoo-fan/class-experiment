package edu.hitsz.prop;

import edu.hitsz.aircraft.HeroAircraft;
import edu.hitsz.aircraft.strategy.ScatterShootStrategy;

/**
 * 火力道具
 */
public class FireSupply extends AbstractProp {

    private static final long EFFECT_DURATION_MS = 8_000L;

    public FireSupply(int locationX, int locationY, int speedX, int speedY) {
        super(locationX, locationY, speedX, speedY);
    }

    @Override
    public void effect() {
        HeroAircraft heroAircraft = HeroAircraft.getInstance();
        if (heroAircraft != null) {
            heroAircraft.setShootStrategyForDuration(new ScatterShootStrategy(), EFFECT_DURATION_MS);
        }
        System.out.println("FireSupply active! Hero strategy -> ScatterShootStrategy");
    }
}
