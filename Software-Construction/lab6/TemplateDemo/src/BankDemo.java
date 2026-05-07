public class BankDemo {
    public static void main(String[] args) {

        System.out.println("=== 场景一：用户1办存款 ===");
        BankBusiness user1 = new DepositBusiness();
        user1.process();

        System.out.println("\n=== 场景二：用户2办理财 ===");
        BankBusiness user2 = new WealthManagement();
        user2.process();
    }
}


