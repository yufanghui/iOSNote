main(List<String> args) {
  // print("hello dart");

  // final p1 = Person("why");
  // final p2 = Person("why");
  // print(identical(p1, p2));
  const p1 = Person("why");
  const p2 = Person("why");
  const p3 = Person("why1");
  // print(identical(p1, p3));

  var flag = true;
  if (flag) {}

  //字符串
  var str1 = '1212';
  var str2 = "1234";
  var str3 = """
  232323
  2323
  """;
  // print(str3);

  var name = "张三";
  //字符串拼接
  final des = "my name is ${name}";
  final des2 = "my name is $name";
  final des3 = "my name is $name,type is ${name.runtimeType}";

  print(des);
  print(des.runtimeType);

  //集合类型，列表list，集合set(元素不能重复，常用于数组去重)，字典map
  //字面量创建
  var names = ["a", "b", "c", "a"];
  names.add("d");
  print(names);
  print(Set.from(names).toList());
  var sets = {"1", "2", "3"};
  print(sets);
  var infos = {"name": "张三", "age": 19};
  print(infos);

  // print(sum(1, 2));
  // sayHello("hello world!");
  // sayHello2("hello", 1, "22");
  // sayHello3("hello");

  // test(bar);
  //匿名函数
  test(() {
    print("匿名函数被调用");
    return 10;
  });

  //箭头函数（函数体只有一行）
  test(() => print("箭头函数被调用"));

  // test2(sum);
  print(test3()(1, 2));
}

//函数定义
int sum(int num, int num2) {
  return num2 + num;
}

//函数返回值可以省略，开发中不推荐
// sum(int num, int num2) {
//   return num2 + num;
// }

//函数的可选参数
//必选参数
void sayHello(String hello) {
  print(hello);
}

//注意：dart中没有函数重载
// void sayHello(String hello) {
//   print(hello);
// }

//可选参数：
// -位置可选参数
void sayHello2(String hello, [int? age, String? name]) {
  print("$hello $age $name");
}

//可选参数：
// -命名可选参数
void sayHello3(String hello, {int? age, String? name}) {
  print("$hello $age $name");
}

//参数默认值，只有可选参数才有默认值
void sayHello21(String hello, [int age = 1, String name = "22"]) {
  print("$hello $age $name");
}

void sayHello31(String hello, {int? age, String? name = "31"}) {
  print("$hello $age $name");
}

void sayHello32(String hello, {int? age, String name = "31"}) {
  print("$hello $age $name");
}

//函数是一等公民，可以作为类型，参数，返回值
// 作为参数

void test(Function foo) {
  foo();
}

//作为类型
typedef SumFunc = int Function(int num1, int num2);
void test2(SumFunc sumf) {
  print("test2 begin");
  print(sumf(20, 39));
  print("test2 end");
}

//作为返回值
SumFunc test3() {
  return (int a, int b) {
    return a + b;
  };
}

void bar() {
  print("hello bar");
}

class Person {
  final String name;
  const Person(this.name);
}
