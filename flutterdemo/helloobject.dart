main(List<String> args) {
  // final p = Person.withNameAgeHeight("张三", 18, 185.5);
  // print(p.toString());

  //父类引用指向子类对象
  // Object obj = "why";
  //不可以这样使用，编译时候就会报错
  // print(obj.substring(1));

  //编译不报错，但是运行时存在安全隐患
  // dynamic obj = "why";
  // print(obj.substring(1));

  // final p = Person.fromMap({"name": "张三", "age": 19, "height": 190.0});
  // print(p);
}

class Person {
  String? name;
  int? age;
  double? height;

  // Person(this.name, {int age}) : this.age = age ?? 10{

  // };
  //语法糖
  Person(this.name, this.age);
  //命名构造函数
  Person.withNameAgeHeight(this.name, this.age, this.height);

  Person.fromMap(Map<String, dynamic> map) {
    this.name = map["name"];
    this.age = map["age"];
    this.height = map["height"];
  }

  @override
  String toString() {
    return "my name is $name,i am $age years old,i $height tall";
  }
}
