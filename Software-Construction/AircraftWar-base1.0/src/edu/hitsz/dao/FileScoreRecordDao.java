package edu.hitsz.dao;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardOpenOption;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

/**
 * File-based DAO implementation for leaderboard records.
 */
public class FileScoreRecordDao implements ScoreRecordDao {

    private final Path storageFile;

    public FileScoreRecordDao() {
        this.storageFile = resolveStorageFile();
    }

    @Override
    public List<ScoreRecord> getAllRecords() {
        List<ScoreRecord> records = new ArrayList<>();
        if (!Files.exists(storageFile)) {
            return records;
        }

        try {
            List<String> lines = Files.readAllLines(storageFile, StandardCharsets.UTF_8);
            for (String line : lines) {
                ScoreRecord record = ScoreRecord.fromStorageLine(line);
                if (record != null) {
                    records.add(record);
                }
            }
        } catch (IOException ex) {
            throw new IllegalStateException("Cannot read leaderboard data: " + storageFile, ex);
        }

        records.sort(leaderboardOrder());
        return records;
    }

    @Override
    public void addRecord(ScoreRecord record) {
        if (record == null) {
            return;
        }

        List<ScoreRecord> records = getAllRecords();
        records.add(record);
        records.sort(leaderboardOrder());

        try {
            Files.createDirectories(storageFile.getParent());
            List<String> lines = new ArrayList<>(records.size());
            for (ScoreRecord item : records) {
                lines.add(item.toStorageLine());
            }
            Files.write(storageFile,
                    lines,
                    StandardCharsets.UTF_8,
                    StandardOpenOption.CREATE,
                    StandardOpenOption.TRUNCATE_EXISTING,
                    StandardOpenOption.WRITE);
        } catch (IOException ex) {
            throw new IllegalStateException("Cannot write leaderboard data: " + storageFile, ex);
        }
    }

    private Comparator<ScoreRecord> leaderboardOrder() {
        return Comparator
                .comparingInt(ScoreRecord::getScore)
                .reversed()
                .thenComparing(ScoreRecord::getRecordTime, Comparator.reverseOrder());
    }

    private Path resolveStorageFile() {
        String customPath = System.getProperty("aircraftwar.scoreboard.path");
        if (customPath != null && !customPath.isBlank()) {
            return Paths.get(customPath).toAbsolutePath().normalize();
        }

        Path projectRoot = locateProjectRoot();
        return projectRoot.resolve(Paths.get("src", "data", "leaderboard.txt")).toAbsolutePath().normalize();
    }

    private Path locateProjectRoot() {
        Path cwd = Paths.get("").toAbsolutePath().normalize();

        Path current = cwd;
        while (current != null) {
            if (isProjectRoot(current)) {
                return current;
            }
            current = current.getParent();
        }

        Path[] quickCandidates = {
                cwd.resolve("Software-Construction").resolve("AircraftWar-base1.0"),
                cwd.resolve("AircraftWar-base1.0")
        };
        for (Path candidate : quickCandidates) {
            if (isProjectRoot(candidate)) {
                return candidate;
            }
        }

        return cwd;
    }

    private boolean isProjectRoot(Path path) {
        return Files.isRegularFile(path.resolve(Paths.get("src", "edu", "hitsz", "application", "Main.java")));
    }
}
