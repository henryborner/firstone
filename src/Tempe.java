import java.util.Scanner;

public class Tempe {
    public static void main(String[] args) {
        Scanner scanner = new Scanner(System.in);
        while (true) {
            System.out.println("=== 温度转换器 ===");
            System.out.println("1. 摄氏度转华氏度");
            System.out.println("2. 华氏度转摄氏度");
            System.out.println("3. 退出");
            System.out.print("请选择 (1-3):");
            int choice = -1;
            boolean type = true;
            type = scanner.hasNextInt();
            if (type) {
                choice = scanner.nextInt();
                if (choice < 1 || choice > 3)
                    type = false;
            }
            while (!type) {
                System.out.print("输入无效，请重新选择 (1-3):");
                scanner.next();
                type = true;
                type = scanner.hasNextInt();
                if (type) {
                    choice = scanner.nextInt();
                    if (choice < 1 || choice > 3)
                        type = false;
                }
            }
            switch (choice) {
                case 1:
                    System.out.print("请输入摄氏度:");
                    while (!scanner.hasNextDouble()) {
                        System.out.print("输入无效，请重新输入摄氏度:");
                        scanner.next();
                    }
                    double c = scanner.nextDouble();
                    double f = c * 9 / 5 + 32;
                    System.out.printf("%.1f°C = %.1f°F\n\n", c, f);
                    break;
                case 2:
                    System.out.print("请输入华氏度:");
                    while (!scanner.hasNextDouble()) {
                        System.out.print("输入无效，请重新输入华氏度:");
                        scanner.next();
                    }
                    double f2 = scanner.nextDouble();
                    double c2 = (f2 - 32) * 5 / 9;
                    System.out.printf("%.1f°F = %.1f°C\n\n", f2, c2);
                    break;
                case 3:
                    System.out.println("程序退出，再见！");
                    scanner.close();
                    return;
            }
        }
    }
}
