package edu.hitsz.aircraft;

import edu.hitsz.aircraft.strategy.ScatterShootStrategy;
import edu.hitsz.bullet.BaseBullet;
import edu.hitsz.bullet.HeroBullet;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.lang.reflect.Field;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertSame;
import static org.junit.jupiter.api.Assertions.assertTrue;

class HeroAircraftTest {

    @BeforeEach
    void setUp() throws Exception {
        resetHeroSingleton();
    }

    @AfterEach
    void tearDown() throws Exception {
        resetHeroSingleton();
    }

    @Test
    @DisplayName("getInstance should always return the same singleton object")
    void testGetInstanceSingleton() {
        HeroAircraft hero1 = HeroAircraft.getInstance(200, 600, 0, 0, 100);
        HeroAircraft hero2 = HeroAircraft.getInstance(300, 500, 1, 1, 80);

        assertNotNull(hero1);
        assertSame(hero1, hero2);
        // First creation arguments are retained because instance is singleton.
        assertEquals(200, hero2.getLocationX());
        assertEquals(600, hero2.getLocationY());
        assertEquals(100, hero2.getHp());
    }

    @Test
    @DisplayName("shoot should create one straight hero bullet by default")
    void testShootWithDefaultStrategy() {
        HeroAircraft hero = HeroAircraft.getInstance(256, 700, 0, 0, 100);

        List<BaseBullet> bullets = hero.shoot();

        assertEquals(1, bullets.size());
        BaseBullet bullet = bullets.get(0);
        assertTrue(bullet instanceof HeroBullet);
        assertEquals(256, bullet.getLocationX());
        assertEquals(698, bullet.getLocationY());
        assertEquals(-5, bullet.getSpeedY());
        assertEquals(30, bullet.getPower());
    }

    @Test
    @DisplayName("setShootStrategy should switch bullet pattern to scatter")
    void testSetShootStrategyToScatter() {
        HeroAircraft hero = HeroAircraft.getInstance(256, 700, 0, 0, 100);
        hero.setShootStrategy(new ScatterShootStrategy());

        List<BaseBullet> bullets = hero.shoot();

        assertEquals(5, bullets.size());
        List<Integer> xList = new ArrayList<>();
        for (BaseBullet bullet : bullets) {
            assertTrue(bullet instanceof HeroBullet);
            xList.add(bullet.getLocationX());
        }
        Collections.sort(xList);
        assertEquals(List.of(236, 246, 256, 266, 276), xList);
    }

    @Test
    @DisplayName("increaseHp from parent class should not exceed max HP")
    void testIncreaseHpShouldBeCappedByMaxHp() {
        HeroAircraft hero = HeroAircraft.getInstance(100, 200, 0, 0, 100);
        hero.decreaseHp(40);

        hero.increaseHp(60);

        assertEquals(100, hero.getHp());
        assertFalse(hero.notValid());
    }

    @Test
    @DisplayName("decreaseHp from parent class should set object invalid when HP reaches zero")
    void testDecreaseHpToZeroShouldVanish() {
        HeroAircraft hero = HeroAircraft.getInstance(100, 200, 0, 0, 100);

        hero.decreaseHp(200);

        assertEquals(0, hero.getHp());
        assertTrue(hero.notValid());
    }

    @Test
    @DisplayName("forward should not move hero because movement is controlled by mouse")
    void testForwardShouldNotMove() {
        HeroAircraft hero = HeroAircraft.getInstance(120, 640, 5, -3, 100);
        hero.setLocation(260, 500);

        hero.forward();

        assertEquals(260, hero.getLocationX());
        assertEquals(500, hero.getLocationY());
    }

    private void resetHeroSingleton() throws Exception {
        Field instanceField = HeroAircraft.class.getDeclaredField("instance");
        instanceField.setAccessible(true);
        instanceField.set(null, null);
    }
}
