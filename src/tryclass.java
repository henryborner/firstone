import java.util.Scanner;

class NewClass {
    private int internal;
    public NewClass(int value){
        this.internal=value;
    }
    public int getInternal(){
        return internal;
    }
}

public class tryclass {
    public static void main(String[] args){
        Scanner scanner=new Scanner(System.in);
        System.out.print("请输入一个整数：");
        while (!scanner.hasNextInt()){
            System.out.print("输入无效，请重新输入一个整数：");
            scanner.next();
        }
        int n=scanner.nextInt();
        NewClass onetry=new NewClass(n);
        System.out.println("通过内部调用，得到整数："+onetry.getInternal());
        scanner.close();
    }
}
