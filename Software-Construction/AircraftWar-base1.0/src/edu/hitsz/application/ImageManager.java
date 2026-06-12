package edu.hitsz.application;

import edu.hitsz.aircraft.*;
import edu.hitsz.bullet.EnemyBullet;
import edu.hitsz.bullet.HeroBullet;
import edu.hitsz.prop.*;

import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.HashMap;
import java.util.Map;

/**
 * 综合管理图片的加载，访问
 * 提供图片的静态访问方法
 * 
 * @author hitsz
 */
public class ImageManager {

    /**
     * 类名-图片 映射，存储各基类的图片 <br>
     * 可使用 CLASSNAME_IMAGE_MAP.get( obj.getClass().getName() ) 获得 obj 所属基类对应的图片
     */
    private static final Map<String, BufferedImage> CLASSNAME_IMAGE_MAP = new HashMap<>();

    public static BufferedImage BACKGROUND_IMAGE;
    public static BufferedImage HERO_IMAGE;
    public static BufferedImage HERO_BULLET_IMAGE;
    public static BufferedImage ENEMY_BULLET_IMAGE;
    public static BufferedImage MOB_ENEMY_IMAGE;
    public static BufferedImage ELITE_ENEMY_IMAGE;
    public static BufferedImage ELITE_PLUS_ENEMY_IMAGE;
    public static BufferedImage ELITE_PRO_ENEMY_IMAGE;
    public static BufferedImage BOSS_ENEMY_IMAGE;

    public static BufferedImage BLOOD_SUPPLY_IMAGE;
    public static BufferedImage BOMB_SUPPLY_IMAGE;
    public static BufferedImage FIRE_SUPPLY_IMAGE;
    public static BufferedImage FIRE_PLUS_SUPPLY_IMAGE;
    public static BufferedImage FREEZE_SUPPLY_IMAGE;

    private static final String[] IMAGE_NAMES = {
            "bg.jpg",
            "bg2.jpg",
            "bg3.jpg",
            "bg4.jpg",
            "bg5.jpg",
            "hero.png",
            "mob.png",
            "elite.png",
            "elitePlus.png",
            "elitePro.png",
            "boss.png",
            "prop_blood.png",
            "prop_bomb.png",
            "prop_bullet.png",
            "prop_bulletPlus.png",
            "prop_freeze.png",
            "bullet_hero.png",
            "bullet_enemy.png"
    };

    private static Path imageBaseDir;

    private static BufferedImage loadImage(String fileName) throws IOException {
        // 优先使用 classpath 资源，适配打包后运行
        try (InputStream inputStream = ImageManager.class.getResourceAsStream("/images/" + fileName)) {
            if (inputStream != null) {
                return ImageIO.read(inputStream);
            }
        }

        Path baseDir = resolveImageBaseDir();
        Path imagePath = baseDir.resolve(fileName);
        return ImageIO.read(imagePath.toFile());
    }

    private static Path resolveImageBaseDir() throws IOException {
        if (imageBaseDir != null) {
            return imageBaseDir;
        }

        String customAssetsDir = System.getProperty("aircraftwar.assetsDir");
        if (customAssetsDir != null) {
            Path customDir = Paths.get(customAssetsDir).toAbsolutePath().normalize();
            if (Files.isDirectory(customDir) && hasAllRequiredImages(customDir)) {
                imageBaseDir = customDir;
                return imageBaseDir;
            }
        }

        Path[] quickCandidates = {
                Paths.get("src", "images"),
                Paths.get("Software-Construction", "AircraftWar-base1.0", "src", "images")
        };
        for (Path candidate : quickCandidates) {
            Path absoluteCandidate = candidate.toAbsolutePath().normalize();
            if (Files.isDirectory(absoluteCandidate) && hasAllRequiredImages(absoluteCandidate)) {
                imageBaseDir = absoluteCandidate;
                return imageBaseDir;
            }
        }

        Path cwd = Paths.get("").toAbsolutePath().normalize();
        try (java.util.stream.Stream<Path> pathStream = Files.walk(cwd, 6)) {
            Path matched = pathStream
                    .filter(Files::isDirectory)
                    .filter(path -> path.getFileName() != null && "images".equals(path.getFileName().toString()))
                    .filter(path -> {
                        Path parent = path.getParent();
                        return parent != null
                                && parent.getFileName() != null
                                && "src".equals(parent.getFileName().toString());
                    })
                    .filter(ImageManager::hasAllRequiredImages)
                    .findFirst()
                    .orElse(null);
            if (matched != null) {
                imageBaseDir = matched;
                return imageBaseDir;
            }
        }

        throw new IOException("Cannot locate image assets directory. Expected folder: src/images");
    }

    private static boolean hasAllRequiredImages(Path dir) {
        for (String imageName : IMAGE_NAMES) {
            if (!Files.isRegularFile(dir.resolve(imageName))) {
                return false;
            }
        }
        return true;
    }

    static {
        try {

            BACKGROUND_IMAGE = loadImage("bg.jpg");

            HERO_IMAGE = loadImage("hero.png");
            MOB_ENEMY_IMAGE = loadImage("mob.png");
            ELITE_ENEMY_IMAGE = loadImage("elite.png");
            ELITE_PLUS_ENEMY_IMAGE = loadImage("elitePlus.png");
            ELITE_PRO_ENEMY_IMAGE = loadImage("elitePro.png");
            BOSS_ENEMY_IMAGE = loadImage("boss.png");

            BLOOD_SUPPLY_IMAGE = loadImage("prop_blood.png");
            BOMB_SUPPLY_IMAGE = loadImage("prop_bomb.png");
            FIRE_SUPPLY_IMAGE = loadImage("prop_bullet.png");
            FIRE_PLUS_SUPPLY_IMAGE = loadImage("prop_bulletPlus.png");
            FREEZE_SUPPLY_IMAGE = loadImage("prop_freeze.png");

            HERO_BULLET_IMAGE = loadImage("bullet_hero.png");
            ENEMY_BULLET_IMAGE = loadImage("bullet_enemy.png");

            CLASSNAME_IMAGE_MAP.put(HeroAircraft.class.getName(), HERO_IMAGE);
            CLASSNAME_IMAGE_MAP.put(MobEnemy.class.getName(), MOB_ENEMY_IMAGE);
            CLASSNAME_IMAGE_MAP.put(EliteEnemy.class.getName(), ELITE_ENEMY_IMAGE);
            CLASSNAME_IMAGE_MAP.put(ElitePlusEnemy.class.getName(), ELITE_PLUS_ENEMY_IMAGE);
            CLASSNAME_IMAGE_MAP.put(EliteProEnemy.class.getName(), ELITE_PRO_ENEMY_IMAGE);
            CLASSNAME_IMAGE_MAP.put(BossEnemy.class.getName(), BOSS_ENEMY_IMAGE);

            CLASSNAME_IMAGE_MAP.put(BloodSupply.class.getName(), BLOOD_SUPPLY_IMAGE);
            CLASSNAME_IMAGE_MAP.put(BombSupply.class.getName(), BOMB_SUPPLY_IMAGE);
            CLASSNAME_IMAGE_MAP.put(FireSupply.class.getName(), FIRE_SUPPLY_IMAGE);
            CLASSNAME_IMAGE_MAP.put(FirePlusSupply.class.getName(), FIRE_PLUS_SUPPLY_IMAGE);
            CLASSNAME_IMAGE_MAP.put(FreezeSupply.class.getName(), FREEZE_SUPPLY_IMAGE);

            CLASSNAME_IMAGE_MAP.put(HeroBullet.class.getName(), HERO_BULLET_IMAGE);
            CLASSNAME_IMAGE_MAP.put(EnemyBullet.class.getName(), ENEMY_BULLET_IMAGE);

        } catch (IOException e) {
            e.printStackTrace();
            System.exit(-1);
        }
    }

    public static BufferedImage get(String className) {
        return CLASSNAME_IMAGE_MAP.get(className);
    }

    public static BufferedImage get(Object obj) {
        if (obj == null) {
            return null;
        }
        return get(obj.getClass().getName());
    }

    public static synchronized void switchBackground(String fileName) {
        try {
            BACKGROUND_IMAGE = loadImage(fileName);
        } catch (IOException ex) {
            throw new IllegalStateException("Cannot load background image: " + fileName, ex);
        }
    }

}
