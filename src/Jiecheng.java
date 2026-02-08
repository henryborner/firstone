import java.util.Scanner;

public class Jiecheng {
    public static void main(String[] args) {
        Scanner scanner = new Scanner(System.in);
        System.out.print("你好，第一个程序！需要整数：");
        while (!scanner.hasNextInt()) {
            System.out.print("似乎不是整数……重新输入吧：");
            scanner.next();
        }
        int n = scanner.nextInt();
        int sum = 1;
        for (int i = 1; i <= n; i++) {
            sum *= i;
        }
        System.out.println("结果是：" + sum);
        scanner.close();
    }
}
