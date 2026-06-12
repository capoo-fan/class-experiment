public class FireAlarm extends AlarmSubject {
    @Override
    public void notifyDevices() {
        for (DeviceObserver device : devices) {
            device.onFireAlarm();
        }
    }
    @Override
    public void trigger() {
        System.out.println("==== 火灾报警器触发！====");
        notifyDevices();
    }
}


