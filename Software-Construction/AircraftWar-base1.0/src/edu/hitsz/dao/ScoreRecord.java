package edu.hitsz.dao;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

/**
 * Value object for leaderboard entries.
 */
public class ScoreRecord {

    private static final DateTimeFormatter TIME_FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    private final String playerName;
    private final int score;
    private final LocalDateTime recordTime;

    public ScoreRecord(String playerName, int score, LocalDateTime recordTime) {
        this.playerName = playerName;
        this.score = score;
        this.recordTime = recordTime;
    }

    public String getPlayerName() {
        return playerName;
    }

    public int getScore() {
        return score;
    }

    public LocalDateTime getRecordTime() {
        return recordTime;
    }

    public String getRecordTimeText() {
        return recordTime.format(TIME_FORMATTER);
    }

    public String toStorageLine() {
        return playerName + "," + score + "," + getRecordTimeText();
    }

    public static ScoreRecord fromStorageLine(String line) {
        if (line == null || line.isBlank()) {
            return null;
        }

        String[] parts = line.split(",", 3);
        if (parts.length != 3) {
            return null;
        }

        try {
            String player = parts[0].trim();
            int points = Integer.parseInt(parts[1].trim());
            LocalDateTime time = LocalDateTime.parse(parts[2].trim(), TIME_FORMATTER);
            return new ScoreRecord(player, points, time);
        } catch (RuntimeException ex) {
            return null;
        }
    }
}
