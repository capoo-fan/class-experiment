package edu.hitsz.factory.prop;

import edu.hitsz.prop.AbstractProp;
import edu.hitsz.prop.BloodSupply;
import edu.hitsz.prop.BombSupply;
import edu.hitsz.prop.FirePlusSupply;
import edu.hitsz.prop.FireSupply;
import edu.hitsz.prop.FreezeSupply;

import java.util.concurrent.ThreadLocalRandom;

/**
 * 道具简单工厂
 */
public class PropSimpleFactory {

    private PropSimpleFactory() {
    }

    public static AbstractProp createRandomProp(int locationX, int locationY, int speedX, int speedY) {
        int choice = ThreadLocalRandom.current().nextInt(3);
        switch (choice) {
            case 0:
                return new BloodSupply(locationX, locationY, speedX, speedY);
            case 1:
                return new FireSupply(locationX, locationY, speedX, speedY);
            default:
                return new FirePlusSupply(locationX, locationY, speedX, speedY);
        }
    }

    public static AbstractProp createForElitePlus(int locationX, int locationY, int speedX, int speedY) {
        int choice = ThreadLocalRandom.current().nextInt(4);
        switch (choice) {
            case 0:
                return new BloodSupply(locationX, locationY, speedX, speedY);
            case 1:
                return new BombSupply(locationX, locationY, speedX, speedY);
            case 2:
                return new FireSupply(locationX, locationY, speedX, speedY);
            default:
                return new FirePlusSupply(locationX, locationY, speedX, speedY);
        }
    }

    public static AbstractProp createForElitePro(int locationX, int locationY, int speedX, int speedY) {
        int choice = ThreadLocalRandom.current().nextInt(5);
        switch (choice) {
            case 0:
                return new BloodSupply(locationX, locationY, speedX, speedY);
            case 1:
                return new BombSupply(locationX, locationY, speedX, speedY);
            case 2:
                return new FireSupply(locationX, locationY, speedX, speedY);
            case 3:
                return new FirePlusSupply(locationX, locationY, speedX, speedY);
            default:
                return new FreezeSupply(locationX, locationY, speedX, speedY);
        }
    }

    public static AbstractProp createForBoss(int locationX, int locationY, int speedX, int speedY) {
        int choice = ThreadLocalRandom.current().nextInt(5);
        switch (choice) {
            case 0:
                return new BloodSupply(locationX, locationY, speedX, speedY);
            case 1:
                return new BombSupply(locationX, locationY, speedX, speedY);
            case 2:
                return new FireSupply(locationX, locationY, speedX, speedY);
            case 3:
                return new FirePlusSupply(locationX, locationY, speedX, speedY);
            default:
                return new FreezeSupply(locationX, locationY, speedX, speedY);
        }
    }
}
