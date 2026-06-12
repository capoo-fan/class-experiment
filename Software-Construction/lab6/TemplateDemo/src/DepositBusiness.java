public class DepositBusiness extends BankBusiness {
    @Override
    public void doBusiness() {
        System.out.println("核心业务：办理现金存款 5000 元。");
    }
    // 采用父类默认的钩子：不准备材料，非VIP
}

