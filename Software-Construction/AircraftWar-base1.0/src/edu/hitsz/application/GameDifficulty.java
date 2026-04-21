package edu.hitsz.application;

/**
 * 游戏难度配置，仅用于切换对应地图。
 */
public enum GameDifficulty {
    EASY("简单", "bg3.jpg"),
    NORMAL("普通", "bg2.jpg"),
    HARD("困难", "bg5.jpg");

    private final String displayName;
    private final String backgroundFileName;

    GameDifficulty(String displayName, String backgroundFileName) {
        this.displayName = displayName;
        this.backgroundFileName = backgroundFileName;
    }

    public String getDisplayName() {
        return displayName;
    }

    public String getBackgroundFileName() {
        return backgroundFileName;
    }
}
