public class SmartSprinkler implements DeviceObserver {

    @Override
    public void onFireAlarm() {
        System.out.println("智能喷淋器：启动自动喷水灭火。");
    }

    @Override
    public void onSecurityAlarm() {
        System.out.println("智能喷淋器：安防报警与灭火无关，保持关闭状态。");
    }
}
