public interface DeviceObserver {
    // 火灾告警后的反应
    void onFireAlarm();
    // 安防告警后的反应
    void onSecurityAlarm();
}
