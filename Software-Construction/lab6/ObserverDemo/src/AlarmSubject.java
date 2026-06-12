import java.util.ArrayList;
import java.util.List;

public abstract class AlarmSubject {
    protected List<DeviceObserver> devices = new ArrayList<>();

    public void addDevice(DeviceObserver device) {
        devices.add(device);
    }

    public void removeDevice(DeviceObserver device) {
        devices.remove(device);
    }

    public abstract void notifyDevices();

    public abstract void trigger();
}

