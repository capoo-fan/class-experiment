public abstract class BankBusiness {
    // 模板方法：定义了办理业务的固定骨架
    public final void process() {
        prepare(); // 钩子方法1
        takeNumber(); // 固定步骤
        // 逻辑钩子判断
        if (isVip()) {
            System.out.println("VIP通道：无需等待，直接前往窗口。");
        } else {
            System.out.println("普通通道：请在休息区等候叫号...");
        }
        doBusiness(); // 抽象方法：具体业务内容
        evaluate(); // 固定步骤
    }
    // 钩子方法1：默认不需要准备材料，子类可挂载
    public void prepare() {}
    // 钩子方法2：默认不是VIP，子类可重写返回逻辑
    public boolean isVip() {return false; }
    // 固定步骤：取号
    private void takeNumber() {System.out.println("第1步：取号排队。");}
    // 抽象方法：子类必须实现具体的业务逻辑
    public abstract void doBusiness();
    // 固定步骤：评价
    private void evaluate() {System.out.println("最后一步：反馈评价。");}
}

