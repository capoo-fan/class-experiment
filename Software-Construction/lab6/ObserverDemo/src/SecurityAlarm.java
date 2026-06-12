public class SecurityAlarm extends AlarmSubject {
    @Override
    public void notifyDevices() {
        for (DeviceObserver device : devices) {
            device.onSecurityAlarm();
        }
    }
    @Override
    public void trigger() {
        System.out.println("==== 安防报警器触发！====");
        notifyDevices();
    }
}

