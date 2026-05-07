public class SmartDoorLock implements DeviceObserver {
    @Override
    public void onFireAlarm() {
        System.out.println("智能门锁：自动解锁，方便人员逃生。");
    }
    @Override
    public void onSecurityAlarm() {
        System.out.println("智能门锁：自动上锁，防止入侵。");
    }
}


