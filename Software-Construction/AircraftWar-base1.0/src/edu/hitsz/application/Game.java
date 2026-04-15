package edu.hitsz.application;

import edu.hitsz.aircraft.*;
import edu.hitsz.bullet.BaseBullet;
import edu.hitsz.basic.AbstractFlyingObject;
import edu.hitsz.factory.enemy.BossEnemyFactory;
import edu.hitsz.factory.enemy.EliteEnemyFactory;
import edu.hitsz.factory.enemy.ElitePlusEnemyFactory;
import edu.hitsz.factory.enemy.EliteProEnemyFactory;
import edu.hitsz.factory.enemy.EnemyFactory;
import edu.hitsz.factory.enemy.MobEnemyFactory;
import edu.hitsz.factory.prop.PropSimpleFactory;
import edu.hitsz.prop.AbstractProp;
import edu.hitsz.prop.BloodSupply;
import edu.hitsz.dao.FileScoreRecordDao;
import edu.hitsz.dao.ScoreRecord;
import edu.hitsz.dao.ScoreRecordDao;

import javax.swing.*;
import java.awt.*;
import java.awt.image.BufferedImage;
import java.time.LocalDateTime;
import java.util.*;
import java.util.List;
import java.util.Timer;
import java.util.concurrent.ThreadLocalRandom;

/**
 * 游戏主面板，游戏启动
 * 
 * @author hitsz
 */
public class Game extends JPanel {

    private int backGroundTop = 0;

    // 调度器, 用于定时任务调度
    private final Timer timer;
    // 时间间隔(ms)，控制刷新频率
    private final int timeInterval = 40;

    private final HeroAircraft heroAircraft;
    private final List<AbstractAircraft> enemyAircrafts;
    private final List<BaseBullet> heroBullets;
    private final List<BaseBullet> enemyBullets;
    private final List<AbstractProp> props;

    // 工厂方法：各类敌机工厂
    private final EnemyFactory[] enemyFactories;
    private final EnemyFactory bossEnemyFactory;
    private final double[] enemySpawnWeights = { 0.35, 0.25, 0.20, 0.20 };

    // 屏幕中出现的敌机最大数量
    private final int enemyMaxNumber = 5;

    // 敌机生成周期
    protected double enemySpawnCycle = 20;
    private int enemySpawnCounter = 0;

    // 英雄机和敌机射击周期
    protected double shootCycle = 20;
    private int shootCounter = 0;

    // 道具掉落概率（仅精英敌机）
    private final double elitePropDropRate = 0.35;

    // 血包恢复量
    private final int bloodSupplyRecover = 25;

    // 当前玩家分数
    private int score = 0;

    private final int bossScoreThreshold = 100;
    private int nextBossScore = bossScoreThreshold;

    // 游戏结束标志
    private boolean gameOverFlag = false;

    private static final String DEFAULT_PLAYER_NAME = "Player";

    private final ScoreRecordDao scoreRecordDao;

    public Game() {
        heroAircraft = HeroAircraft.getInstance(
                Main.WINDOW_WIDTH / 2,
                Main.WINDOW_HEIGHT - ImageManager.HERO_IMAGE.getHeight(),
                0, 0, 100);

        enemyAircrafts = new LinkedList<>();
        heroBullets = new LinkedList<>();
        enemyBullets = new LinkedList<>();
        props = new LinkedList<>();
        enemyFactories = new EnemyFactory[] {
                new MobEnemyFactory(),
                new EliteEnemyFactory(),
                new ElitePlusEnemyFactory(),
                new EliteProEnemyFactory()
        };
        bossEnemyFactory = new BossEnemyFactory();
        scoreRecordDao = new FileScoreRecordDao();

        // 启动英雄机鼠标监听
        new HeroController(this, heroAircraft);

        this.timer = new Timer("game-action-timer", true);

    }

    /**
     * 游戏启动入口，执行游戏逻辑
     */
    public void action() {

        // 定时任务：绘制、对象产生、碰撞判定、及结束判定
        TimerTask task = new TimerTask() {
            @Override
            public void run() {

                enemySpawnCounter++;
                if (enemySpawnCounter >= enemySpawnCycle) {
                    enemySpawnCounter = 0;
                    // 按周期随机产生普通敌机或精英敌机
                    if (enemyAircrafts.size() < enemyMaxNumber) {
                        enemyAircrafts.add(createRandomEnemy());
                    }
                }

                // 分数达到阈值后生成 Boss，且同屏仅存在一台 Boss
                trySpawnBossEnemy();

                // 飞机发射子弹
                shootAction();
                // 子弹移动
                bulletsMoveAction();
                // 飞机移动
                aircraftsMoveAction();
                // 撞击检测
                crashCheckAction();
                // 后处理
                postProcessAction();
                // 重绘界面
                repaint();
                // 游戏结束检查
                checkResultAction();
            }
        };
        // 以固定延迟时间进行执行：本次任务执行完成后，延迟 timeInterval 再执行下一次
        timer.schedule(task, 0, timeInterval);

    }

    // ***********************
    // Action 各部分
    // ***********************

    private void shootAction() {
        shootCounter++;
        if (shootCounter >= shootCycle) {
            shootCounter = 0;
            // 英雄机射击
            heroBullets.addAll(heroAircraft.shoot());

            // 敌机按周期发射子弹
            for (AbstractAircraft enemyAircraft : enemyAircrafts) {
                enemyBullets.addAll(enemyAircraft.shoot());
            }
        }
    }

    private void bulletsMoveAction() {
        for (BaseBullet bullet : heroBullets) {
            bullet.forward();
        }
        for (BaseBullet bullet : enemyBullets) {
            bullet.forward();
        }
    }

    private void aircraftsMoveAction() {
        for (AbstractAircraft enemyAircraft : enemyAircrafts) {
            enemyAircraft.forward();
        }

        for (AbstractProp prop : props) {
            prop.forward();
        }
    }

    private void tryGenerateProp(AbstractAircraft enemyAircraft) {
        int x = enemyAircraft.getLocationX();
        int y = enemyAircraft.getLocationY();
        int speedY = 4;

        if (enemyAircraft instanceof BossEnemy) {
            for (int i = 0; i < 3; i++) {
                int speedX = ThreadLocalRandom.current().nextInt(-2, 3);
                props.add(PropSimpleFactory.createForBoss(x, y, speedX, speedY));
            }
            return;
        }

        if (!(enemyAircraft instanceof ElitePlusEnemy || enemyAircraft instanceof EliteProEnemy)) {
            return;
        }
        if (Math.random() > elitePropDropRate) {
            return;
        }

        int speedX = 0;

        if (enemyAircraft instanceof EliteProEnemy) {
            props.add(PropSimpleFactory.createForElitePro(x, y, speedX, speedY));
            return;
        }
        props.add(PropSimpleFactory.createForElitePlus(x, y, speedX, speedY));
    }

    private EnemyFactory chooseEnemyFactory() {
        double random = Math.random();
        double cumulative = 0.0;
        for (int i = 0; i < enemyFactories.length; i++) {
            cumulative += enemySpawnWeights[i];
            if (random < cumulative) {
                return enemyFactories[i];
            }
        }
        return enemyFactories[enemyFactories.length - 1];
    }

    private AbstractAircraft createRandomEnemy() {
        return chooseEnemyFactory().createEnemy();
    }

    private boolean hasBossEnemy() {
        for (AbstractAircraft enemyAircraft : enemyAircrafts) {
            if (enemyAircraft instanceof BossEnemy && !enemyAircraft.notValid()) {
                return true;
            }
        }
        return false;
    }

    private void trySpawnBossEnemy() {
        if (score < nextBossScore || hasBossEnemy()) {
            return;
        }
        enemyAircrafts.add(bossEnemyFactory.createEnemy());
        nextBossScore += bossScoreThreshold;
    }

    /**
     * 碰撞检测：
     * 1. 敌机攻击英雄
     * 2. 英雄攻击/撞击敌机
     * 3. 英雄获得补给
     */
    private void crashCheckAction() {
        // 敌机子弹攻击英雄机
        for (BaseBullet bullet : enemyBullets) {
            if (bullet.notValid() || heroAircraft.notValid()) {
                continue;
            }
            if (heroAircraft.crash(bullet) || bullet.crash(heroAircraft)) {
                heroAircraft.decreaseHp(bullet.getPower());
                bullet.vanish();
            }
        }

        // 英雄子弹攻击敌机
        for (BaseBullet bullet : heroBullets) {
            if (bullet.notValid()) {
                continue;
            }
            for (AbstractAircraft enemyAircraft : enemyAircrafts) {
                if (enemyAircraft.notValid()) {
                    // 已被其他子弹击毁的敌机，不再检测
                    // 避免多个子弹重复击毁同一敌机的判定
                    continue;
                }
                if (enemyAircraft.crash(bullet)) {
                    // 敌机撞击到英雄机子弹
                    // 敌机损失一定生命值
                    enemyAircraft.decreaseHp(bullet.getPower());
                    bullet.vanish();
                    if (enemyAircraft.notValid()) {
                        // 获得分数，精英敌机坠毁有概率掉落道具
                        score += 10;
                        tryGenerateProp(enemyAircraft);
                    }
                }
                // 英雄机 与 敌机 相撞，均损毁
                if (enemyAircraft.crash(heroAircraft) || heroAircraft.crash(enemyAircraft)) {
                    enemyAircraft.vanish();
                    heroAircraft.decreaseHp(Integer.MAX_VALUE);
                    tryGenerateProp(enemyAircraft);
                }
            }
        }

        // 英雄机拾取道具后生效并消失
        for (AbstractProp prop : props) {
            if (prop.notValid()) {
                continue;
            }
            if (prop.crash(heroAircraft) || heroAircraft.crash(prop)) {
                if (prop instanceof BloodSupply) {
                    heroAircraft.increaseHp(bloodSupplyRecover);
                } else {
                    prop.effect();
                }
                prop.vanish();
            }
        }

    }

    /**
     * 后处理：
     * 1. 删除无效的子弹
     * 2. 删除无效的敌机
     * 3. 删除无效的道具
     */
    private void postProcessAction() {
        enemyBullets.removeIf(AbstractFlyingObject::notValid);
        heroBullets.removeIf(AbstractFlyingObject::notValid);
        enemyAircrafts.removeIf(AbstractFlyingObject::notValid);
        props.removeIf(AbstractFlyingObject::notValid);
    }

    /**
     * 检查游戏是否结束，若结束：关闭线程池
     */
    private void checkResultAction() {
        // 游戏结束检查英雄机是否存活
        if (heroAircraft.getHp() <= 0 && !gameOverFlag) {
            timer.cancel(); // 取消定时器并终止所有调度任务
            gameOverFlag = true;
            System.out.println("Game Over!");
            saveAndPrintLeaderboard();
        }
    };

    private void saveAndPrintLeaderboard() {
        try {
            scoreRecordDao.addRecord(new ScoreRecord(DEFAULT_PLAYER_NAME, score, LocalDateTime.now()));
            List<ScoreRecord> records = scoreRecordDao.getAllRecords();

            System.out.println("======== Leaderboard ========");
            System.out.printf("%-6s %-14s %-8s %-19s%n", "Rank", "Name", "Score", "Time");
            for (int i = 0; i < records.size(); i++) {
                ScoreRecord record = records.get(i);
                System.out.printf("%-6d %-14s %-8d %-19s%n",
                        i + 1,
                        record.getPlayerName(),
                        record.getScore(),
                        record.getRecordTimeText());
            }
            System.out.println("=============================");
        } catch (RuntimeException ex) {
            System.err.println("Failed to save leaderboard: " + ex.getMessage());
        }
    }

    // ***********************
    // Paint 各部分
    // ***********************
    /**
     * 重写 paint方法
     * 通过重复调用paint方法，实现游戏动画
     */
    @Override
    public void paint(Graphics g) {
        super.paint(g);

        // 绘制背景,图片滚动
        g.drawImage(ImageManager.BACKGROUND_IMAGE, 0, this.backGroundTop - Main.WINDOW_HEIGHT, null);
        g.drawImage(ImageManager.BACKGROUND_IMAGE, 0, this.backGroundTop, null);
        this.backGroundTop += 1;
        if (this.backGroundTop == Main.WINDOW_HEIGHT) {
            this.backGroundTop = 0;
        }

        // 先绘制子弹，后绘制飞机
        // 这样子弹显示在飞机的下层
        paintImageWithPositionRevised(g, enemyBullets);
        paintImageWithPositionRevised(g, heroBullets);
        paintImageWithPositionRevised(g, enemyAircrafts);
        paintImageWithPositionRevised(g, props);

        g.drawImage(ImageManager.HERO_IMAGE, heroAircraft.getLocationX() - ImageManager.HERO_IMAGE.getWidth() / 2,
                heroAircraft.getLocationY() - ImageManager.HERO_IMAGE.getHeight() / 2, null);

        // 绘制得分和生命值
        paintScoreAndLife(g);

    }

    private void paintImageWithPositionRevised(Graphics g, List<? extends AbstractFlyingObject> objects) {
        if (objects.isEmpty()) {
            return;
        }

        for (AbstractFlyingObject object : objects) {
            BufferedImage image = object.getImage();
            assert image != null : objects.getClass().getName() + " has no image! ";
            g.drawImage(image, object.getLocationX() - image.getWidth() / 2,
                    object.getLocationY() - image.getHeight() / 2, null);
        }
    }

    private void paintScoreAndLife(Graphics g) {
        int x = 10;
        int y = 25;
        g.setColor(Color.RED);
        g.setFont(new Font("SansSerif", Font.BOLD, 22));
        g.drawString("SCORE: " + this.score, x, y);
        y = y + 20;
        g.drawString("LIFE: " + this.heroAircraft.getHp(), x, y);
    }

}
