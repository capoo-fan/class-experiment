package edu.hitsz.application;

import edu.hitsz.dao.ScoreRecord;
import edu.hitsz.dao.ScoreRecordDao;

import javax.swing.JButton;
import javax.swing.JDialog;
import javax.swing.JLabel;
import javax.swing.JOptionPane;
import javax.swing.JPanel;
import javax.swing.JScrollPane;
import javax.swing.JTable;
import javax.swing.JTextField;
import javax.swing.ListSelectionModel;
import javax.swing.WindowConstants;
import javax.swing.table.DefaultTableModel;
import java.awt.BorderLayout;
import java.awt.FlowLayout;
import java.awt.Window;
import java.time.LocalDateTime;
import java.util.List;

/**
 * 游戏结束后的排行榜界面，支持录入本局成绩与删除历史记录。
 */
public class LeaderboardDialog extends JDialog {

    private static final String DEFAULT_PLAYER_NAME = "Player";

    private final ScoreRecordDao scoreRecordDao;
    private final int currentScore;

    private final JTextField nameField = new JTextField(DEFAULT_PLAYER_NAME, 12);
    private final JButton saveCurrentScoreButton = new JButton("记录本局得分");
    private final JButton deleteSelectedButton = new JButton("删除选中记录");
    private final DefaultTableModel tableModel = new DefaultTableModel(
            new Object[] { "排名", "姓名", "分数", "时间" },
            0) {
        @Override
        public boolean isCellEditable(int row, int column) {
            return false;
        }
    };
    private final JTable table = new JTable(tableModel);

    private boolean currentScoreSaved = false;

    public LeaderboardDialog(Window owner, ScoreRecordDao scoreRecordDao, int currentScore) {
        super(owner, "排行榜", ModalityType.MODELESS);
        this.scoreRecordDao = scoreRecordDao;
        this.currentScore = currentScore;

        initUi(owner);
        bindActions();
        refreshTable();
    }

    public void promptForPlayerNameAndSave() {
        String name = JOptionPane.showInputDialog(this, "请输入玩家姓名", DEFAULT_PLAYER_NAME);
        if (name == null) {
            return;
        }
        nameField.setText(name.trim());
        saveCurrentScore();
    }

    private void initUi(Window owner) {
        setLayout(new BorderLayout(8, 8));

        JPanel topPanel = new JPanel(new FlowLayout(FlowLayout.LEFT));
        topPanel.add(new JLabel("本局得分: " + currentScore));
        topPanel.add(new JLabel("姓名:"));
        topPanel.add(nameField);
        topPanel.add(saveCurrentScoreButton);
        add(topPanel, BorderLayout.NORTH);

        table.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
        table.getTableHeader().setReorderingAllowed(false);
        add(new JScrollPane(table), BorderLayout.CENTER);

        JButton closeButton = new JButton("关闭");
        closeButton.addActionListener(e -> dispose());

        JPanel bottomPanel = new JPanel(new FlowLayout(FlowLayout.RIGHT));
        bottomPanel.add(deleteSelectedButton);
        bottomPanel.add(closeButton);
        add(bottomPanel, BorderLayout.SOUTH);

        setDefaultCloseOperation(WindowConstants.DISPOSE_ON_CLOSE);
        setSize(560, 420);
        setLocationRelativeTo(owner);
    }

    private void bindActions() {
        saveCurrentScoreButton.addActionListener(e -> saveCurrentScore());
        deleteSelectedButton.addActionListener(e -> deleteSelectedRecord());
    }

    private void saveCurrentScore() {
        if (currentScoreSaved) {
            JOptionPane.showMessageDialog(this, "本局得分已记录。", "提示", JOptionPane.INFORMATION_MESSAGE);
            return;
        }

        String playerName = nameField.getText().trim();
        if (playerName.isEmpty()) {
            playerName = DEFAULT_PLAYER_NAME;
            nameField.setText(playerName);
        }

        try {
            scoreRecordDao.addRecord(new ScoreRecord(playerName, currentScore, LocalDateTime.now()));
            currentScoreSaved = true;
            saveCurrentScoreButton.setEnabled(false);
            refreshTable();
        } catch (RuntimeException ex) {
            JOptionPane.showMessageDialog(this,
                    "记录分数失败: " + ex.getMessage(),
                    "错误",
                    JOptionPane.ERROR_MESSAGE);
        }
    }

    private void deleteSelectedRecord() {
        int selectedRow = table.getSelectedRow();
        if (selectedRow < 0) {
            JOptionPane.showMessageDialog(this, "请先选中一条记录。", "提示", JOptionPane.INFORMATION_MESSAGE);
            return;
        }

        int confirm = JOptionPane.showConfirmDialog(
                this,
                "确认删除选中的历史得分记录吗？",
                "删除确认",
                JOptionPane.YES_NO_OPTION,
                JOptionPane.WARNING_MESSAGE);
        if (confirm != JOptionPane.YES_OPTION) {
            return;
        }

        try {
            scoreRecordDao.deleteRecord(selectedRow);
            refreshTable();
        } catch (RuntimeException ex) {
            JOptionPane.showMessageDialog(this,
                    "删除记录失败: " + ex.getMessage(),
                    "错误",
                    JOptionPane.ERROR_MESSAGE);
        }
    }

    private void refreshTable() {
        tableModel.setRowCount(0);
        List<ScoreRecord> records = scoreRecordDao.getAllRecords();
        for (int i = 0; i < records.size(); i++) {
            ScoreRecord record = records.get(i);
            tableModel.addRow(new Object[] {
                    i + 1,
                    record.getPlayerName(),
                    record.getScore(),
                    record.getRecordTimeText()
            });
        }
    }
}
