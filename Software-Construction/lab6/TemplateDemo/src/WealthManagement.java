public class WealthManagement extends BankBusiness {
    @Override
    public void prepare() {
        System.out.println("前置准备：填写《风险测评问卷》和《大额交易申报单》。");
    }
    @Override
    public boolean isVip() {
        // 重写钩子，使其走 VIP 逻辑分支
        return true;
    }
    @Override
    public void doBusiness() {
        System.out.println("核心业务：购买 100 万元大额理财产品。");
    }
}
