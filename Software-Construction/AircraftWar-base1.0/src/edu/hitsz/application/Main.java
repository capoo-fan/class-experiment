package edu.hitsz.application;

import javax.swing.*;
import java.awt.*;

/**
 * 程序入口
 * 
 * @author hitsz
 */
public class Main {

    public static final int WINDOW_WIDTH = 512;
    public static final int WINDOW_HEIGHT = 768;

    public static void main(String[] args) {

        System.out.println("Hello Aircraft War");

        GameDifficulty difficulty = chooseDifficulty();
        ImageManager.switchBackground(difficulty.getBackgroundFileName());

        // 获得屏幕的分辨率，初始化 Frame
        Dimension screenSize = Toolkit.getDefaultToolkit().getScreenSize();
        JFrame frame = new JFrame("Aircraft War - " + difficulty.getDisplayName());
        frame.setSize(WINDOW_WIDTH, WINDOW_HEIGHT);
        frame.setResizable(false);
        // 设置窗口的大小和位置,居中放置
        frame.setBounds(((int) screenSize.getWidth() - WINDOW_WIDTH) / 2, 0,
                WINDOW_WIDTH, WINDOW_HEIGHT);
        frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);

        Game game = new Game(difficulty);
        frame.add(game);
        frame.setVisible(true);
        game.action();
    }

    private static GameDifficulty chooseDifficulty() {
        GameDifficulty[] options = GameDifficulty.values();
        String[] labels = new String[options.length];
        for (int i = 0; i < options.length; i++) {
            labels[i] = options[i].getDisplayName();
        }

        int selectedIndex = JOptionPane.showOptionDialog(
                null,
                "请选择游戏难度",
                "难度选择",
                JOptionPane.DEFAULT_OPTION,
                JOptionPane.QUESTION_MESSAGE,
                null,
                labels,
                labels[1]);

        if (selectedIndex < 0 || selectedIndex >= options.length) {
            return GameDifficulty.NORMAL;
        }
        return options[selectedIndex];
    }
}
