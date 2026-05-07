public class SmartHomeDemo {
    public static void main(String[] args) {
        // 1. 初始化两个观察目标
        AlarmSubject fireAlarm = new FireAlarm();
        AlarmSubject securityAlarm = new SecurityAlarm();

        // 2. 初始化三个个观察者
        DeviceObserver light = new SmartLight();
        DeviceObserver doorLock = new SmartDoorLock();
        DeviceObserver sprinkler = new SmartSprinkler();
        // 3. 将观察者注册到观察目标中
        fireAlarm.addDevice(light);
        fireAlarm.addDevice(doorLock);
        fireAlarm.addDevice(sprinkler);

        securityAlarm.addDevice(light);
        securityAlarm.addDevice(doorLock);
        securityAlarm.addDevice(sprinkler);
        // 4. 触发告警
        fireAlarm.trigger();
        securityAlarm.trigger();

    }
}




