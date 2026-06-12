public class SmartLight implements DeviceObserver {
    @Override
    public void onFireAlarm() {
        System.out.println("智能灯：打开应急照明。");
    }
    @Override
    public void onSecurityAlarm() {
        System.out.println("智能灯：开启闪烁警示。");
    }
}


