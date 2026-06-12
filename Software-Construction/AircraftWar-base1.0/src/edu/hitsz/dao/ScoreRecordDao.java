package edu.hitsz.dao;

import java.util.List;

/**
 * DAO interface for leaderboard data access.
 */
public interface ScoreRecordDao {

    List<ScoreRecord> getAllRecords();

    void addRecord(ScoreRecord record);

    void deleteRecord(int index);
}
