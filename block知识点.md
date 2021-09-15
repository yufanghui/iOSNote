## block的底层数据结构?本质是什么?

转成c++代码.

```c++
struct __block_impl {
  void *isa;
  int Flags;
  int Reserved;
  void *FuncPtr;
};

//block
struct __main_block_impl_0 {
  struct __block_impl impl;
  struct __main_block_desc_0* Desc;
  __main_block_impl_0(void *fp, struct __main_block_desc_0 *desc, int flags=0) {
    impl.isa = &_NSConcreteStackBlock;
    impl.Flags = flags;
    impl.FuncPtr = fp;
    Desc = desc;
  }
};

//block内部要执行的代码(被封装成了一个函数)
static void __main_block_func_0(struct __main_block_impl_0 *__cself) {

            NSLog((NSString *)&__NSConstantStringImpl__var_folders_07_lywlrnd57s387lb3xy4nzwcr0000gp_T_main_f55c99_mi_0);
        }

//c++,block中的成员
static struct __main_block_desc_0 {
  size_t reserved;
  size_t Block_size;
} __main_block_desc_0_DATA = { 0, sizeof(struct __main_block_impl_0)};

//main函数
int main(int argc, const char * argv[]) {

        MyBlock block = &__main_block_impl_0(__main_block_func_0, &__main_block_desc_0_DATA));
  
        block)->FuncPtr(block);

    return 0;
}
```

可以看出block的定义,实际上就是初始化了`__main_block_impl_0`并取地址赋值,__main_block_impl_0就是block 的底层实现.这个结构体内部有两个成员

```c++
  struct __block_impl impl;//成员1
  struct __main_block_desc_0* Desc;//成员2
  //构造函数
  __main_block_impl_0(void *fp, struct __main_block_desc_0 *desc, int flags=0) {
    impl.isa = &_NSConcreteStackBlock;
    impl.Flags = flags;
    impl.FuncPtr = fp;
    Desc = desc;
  }
```

而`struct __block_impl`内部有个isa

```c++
struct __block_impl {
  void *isa;
  int Flags;
  int Reserved;
  void *FuncPtr;
};
```

可以推测block本质是对象类型的.

打印看下

```objective-c
        MyBlock block = ^(){
            NSLog(@"hello world");
        };
//        block();
        NSLog(@"%@",[block class]);
        NSLog(@"%@",[block superclass]);
        NSLog(@"%@",[[block superclass]superclass]);

/*
2021-08-31 10:20:39.431805+0800 blockDemo[2000:72345] __NSGlobalBlock__
2021-08-31 10:20:39.433066+0800 blockDemo[2000:72345] NSBlock
2021-08-31 10:20:39.433148+0800 blockDemo[2000:72345] NSObject
*/
```

果然如此.

总结,block本质上是一个oc对象,可以通过打印class和superclass证实.

## block捕获变量



按变量类型分

- 基础类型
- 对象类型

按作用域区分

- 自动变量
- 静态变量
- 全局变量

### 基本类型的捕获

block内部常常会访问外部变量.看下面这道题,会打印什么呢?

```objective-c
        int age = 10;
        MyBlock block = ^(){
            NSLog(@"age %d",age);
        };
        age = 20;
/*
10
*/
```

为什么是10而不是20呢?

如果改成static修饰呢?

```objective-c
        static int age = 10;
        MyBlock block = ^(){
            NSLog(@"age %d",age);
        };
        age = 20;
/*
20
*/
```

为何此时又是20呢?

如果将变量放到全局呢?

```objective-c
int age = 10;
int main(int argc, const char * argv[]) {
    @autoreleasepool {
        
        MyBlock block = ^(){
            NSLog(@"age %d",age);
        };
        age = 20;
        block();
        }
}
/*
20
*/
```

那么这是为什么呢?

转成c++代码看看

#### 自动变量类型捕获

```c++
struct __main_block_impl_0 {
  struct __block_impl impl;
  struct __main_block_desc_0* Desc;
  int age;
  __main_block_impl_0(void *fp, struct __main_block_desc_0 *desc, int _age, int flags=0) : age(_age) {
    impl.isa = &_NSConcreteStackBlock;
    impl.Flags = flags;
    impl.FuncPtr = fp;
    Desc = desc;
  }
};
static void __main_block_func_0(struct __main_block_impl_0 *__cself) {
  int age = __cself->age; // bound by copy

            NSLog((NSString *)&__NSConstantStringImpl__var_folders_07_lywlrnd57s387lb3xy4nzwcr0000gp_T_main_a717db_mi_0,age);
        }


static struct __main_block_desc_0 {
  size_t reserved;
  size_t Block_size;
} __main_block_desc_0_DATA = { 0, sizeof(struct __main_block_impl_0)};
int main(int argc, const char * argv[]) {
    /* @autoreleasepool */ { __AtAutoreleasePool __autoreleasepool; 
        int age = 10;
        MyBlock block = ((void (*)())&__main_block_impl_0((void *)__main_block_func_0, &__main_block_desc_0_DATA, age));
        ((void (*)(__block_impl *))((__block_impl *)block)->FuncPtr)((__block_impl *)block);

    }
    return 0;
}

```

发现__main_block_impl_0内部也会生成一个age的成员变量.传递的时候是值传递

所以后面即使改了,再打印,也仍旧是之前传进去的10

#### 静态变量的捕获

对应c++代码如下,发现`__main_block_impl_0`内部生成了一个`int *age`的成员变量发现传递进去的是指针.这也解释了为什么打印的值是20,因为是引用传递.

```c++
struct __main_block_impl_0 {
  struct __block_impl impl;
  struct __main_block_desc_0* Desc;
  int *age;
  __main_block_impl_0(void *fp, struct __main_block_desc_0 *desc, int *_age, int flags=0) : age(_age) {
    impl.isa = &_NSConcreteStackBlock;
    impl.Flags = flags;
    impl.FuncPtr = fp;
    Desc = desc;
  }
};
static void __main_block_func_0(struct __main_block_impl_0 *__cself) {
  int *age = __cself->age; // bound by copy

            NSLog((NSString *)&__NSConstantStringImpl__var_folders_07_lywlrnd57s387lb3xy4nzwcr0000gp_T_main_9c4741_mi_0,(*age));
        }

static struct __main_block_desc_0 {
  size_t reserved;
  size_t Block_size;
} __main_block_desc_0_DATA = { 0, sizeof(struct __main_block_impl_0)};
int main(int argc, const char * argv[]) {
    /* @autoreleasepool */ { __AtAutoreleasePool __autoreleasepool; 
        static int age = 10;
        MyBlock block = ((void (*)())&__main_block_impl_0((void *)__main_block_func_0, &__main_block_desc_0_DATA, &age));
        age = 20;
        ((void (*)(__block_impl *))((__block_impl *)block)->FuncPtr)((__block_impl *)block);



    }
    return 0;
}
```

#### 在block中访问全局变量

可以看到,没有捕获发生,__main_block_impl_0中没有生成age相关的变量,直接在函数内部访问

```c++
int age = 10;

struct __main_block_impl_0 {
  struct __block_impl impl;
  struct __main_block_desc_0* Desc;
  __main_block_impl_0(void *fp, struct __main_block_desc_0 *desc, int flags=0) {
    impl.isa = &_NSConcreteStackBlock;
    impl.Flags = flags;
    impl.FuncPtr = fp;
    Desc = desc;
  }
};
static void __main_block_func_0(struct __main_block_impl_0 *__cself) {

            NSLog((NSString *)&__NSConstantStringImpl__var_folders_07_lywlrnd57s387lb3xy4nzwcr0000gp_T_main_9a002f_mi_0,age);
        }

static struct __main_block_desc_0 {
  size_t reserved;
  size_t Block_size;
} __main_block_desc_0_DATA = { 0, sizeof(struct __main_block_impl_0)};
int main(int argc, const char * argv[]) {
    /* @autoreleasepool */ { __AtAutoreleasePool __autoreleasepool; 

        MyBlock block = ((void (*)())&__main_block_impl_0((void *)__main_block_func_0, &__main_block_desc_0_DATA));
        age = 20;
        ((void (*)(__block_impl *))((__block_impl *)block)->FuncPtr)((__block_impl *)block);
    }
    return 0;
}
```

### 对象类型的捕获

```objective-c
        Person *p = [[Person alloc]init];
        p.age = 10;
        MyBlock block = ^(){
            NSLog(@"age %d",p.age);
        };
        block();
```

可以看到,对象类型的,直接就是捕获该对象.除此之外,值得注意的是.相比于基本类型的,多生成了两个函数`__main_block_copy_0,``__main_block_dispose_0`.这是因为传入了对象类型的,我们知道MRC的时候,对象的内存管理是,谁持有,谁释放.

```c++
struct __main_block_impl_0 {
  struct __block_impl impl;
  struct __main_block_desc_0* Desc;
  Person *__strong p;
  __main_block_impl_0(void *fp, struct __main_block_desc_0 *desc, Person *__strong _p, int flags=0) : p(_p) {
    impl.isa = &_NSConcreteStackBlock;
    impl.Flags = flags;
    impl.FuncPtr = fp;
    Desc = desc;
  }
};
static void __main_block_func_0(struct __main_block_impl_0 *__cself) {
  Person *__strong p = __cself->p; // bound by copy

            NSLog((NSString *)&__NSConstantStringImpl__var_folders_07_lywlrnd57s387lb3xy4nzwcr0000gp_T_main_08b3fd_mi_0,((int (*)(id, SEL))(void *)objc_msgSend)((id)p, sel_registerName("age")));
        }
static void __main_block_copy_0(struct __main_block_impl_0*dst, struct __main_block_impl_0*src) {_Block_object_assign((void*)&dst->p, (void*)src->p, 3/*BLOCK_FIELD_IS_OBJECT*/);}

static void __main_block_dispose_0(struct __main_block_impl_0*src) {_Block_object_dispose((void*)src->p, 3/*BLOCK_FIELD_IS_OBJECT*/);}

static struct __main_block_desc_0 {
  size_t reserved;
  size_t Block_size;
  void (*copy)(struct __main_block_impl_0*, struct __main_block_impl_0*);
  void (*dispose)(struct __main_block_impl_0*);
} __main_block_desc_0_DATA = { 
  0, 
  sizeof(struct __main_block_impl_0),
  __main_block_copy_0, 
  __main_block_dispose_0
};

int main(int argc, const char * argv[]) {
  
    /* @autoreleasepool */ { __AtAutoreleasePool __autoreleasepool; 
                            
        Person *p = ((Person *(*)(id, SEL))(void *)objc_msgSend)((id)((Person *(*)(id, SEL))(void *)objc_msgSend)((id)objc_getClass("Person"), sel_registerName("alloc")), sel_registerName("init"));
                            
        ((void (*)(id, SEL, int))(void *)objc_msgSend)((id)p, sel_registerName("setAge:"), 10);
                            
        MyBlock block = ((void (*)())&__main_block_impl_0((void *)__main_block_func_0, &__main_block_desc_0_DATA, p, 570425344));
        ((void (*)(__block_impl *))((__block_impl *)block)->FuncPtr)((__block_impl *)block);


    }
    return 0;
}
```

可以看到默认情况下,block内部是强引用了Person.

weak修饰的变量 

```c++
struct __main_block_impl_0 {
  struct __block_impl impl;
  struct __main_block_desc_0* Desc;
  Person *__weak weakP;
  __main_block_impl_0(void *fp, struct __main_block_desc_0 *desc, Person *__weak _weakP, int flags=0) : weakP(_weakP) {
    impl.isa = &_NSConcreteStackBlock;
    impl.Flags = flags;
    impl.FuncPtr = fp;
    Desc = desc;
  }
};
static void __main_block_func_0(struct __main_block_impl_0 *__cself) {
  Person *__weak weakP = __cself->weakP; // bound by copy

                NSLog((NSString *)&__NSConstantStringImpl__var_folders_07_lywlrnd57s387lb3xy4nzwcr0000gp_T_main_45968c_mi_0,((int (*)(id, SEL))(void *)objc_msgSend)((id)weakP, sel_registerName("age")));
            }
static void __main_block_copy_0(struct __main_block_impl_0*dst, struct __main_block_impl_0*src) {_Block_object_assign((void*)&dst->weakP, (void*)src->weakP, 3/*BLOCK_FIELD_IS_OBJECT*/);}

static void __main_block_dispose_0(struct __main_block_impl_0*src) {_Block_object_dispose((void*)src->weakP, 3/*BLOCK_FIELD_IS_OBJECT*/);}

static struct __main_block_desc_0 {
  size_t reserved;
  size_t Block_size;
  void (*copy)(struct __main_block_impl_0*, struct __main_block_impl_0*);
  void (*dispose)(struct __main_block_impl_0*);
} __main_block_desc_0_DATA = { 0, sizeof(struct __main_block_impl_0), __main_block_copy_0, __main_block_dispose_0};
int main(int argc, const char * argv[]) {
    /* @autoreleasepool */ { __AtAutoreleasePool __autoreleasepool; 
        MyBlock block;
        {
            Person *p = ((Person *(*)(id, SEL))(void *)objc_msgSend)((id)((Person *(*)(id, SEL))(void *)objc_msgSend)((id)objc_getClass("Person"), sel_registerName("alloc")), sel_registerName("init"));
            ((void (*)(id, SEL, int))(void *)objc_msgSend)((id)p, sel_registerName("setAge:"), 10);
            __attribute__((objc_ownership(weak))) typeof(p) weakP = p;
            block = ((void (*)())&__main_block_impl_0((void *)__main_block_func_0, &__main_block_desc_0_DATA, weakP, 570425344));
        }
        ((void (*)(__block_impl *))((__block_impl *)block)->FuncPtr)((__block_impl *)block);
    }
    return 0;
}
```

可以看到,block中捕获的对象类型的变量的内存管理类型取决于.外部变量是用什么修饰的.并且,此时是block来管理捕获变量的内存,因而在,变量捕获的时候会调用`__main_block_copy_0`来进行引用计数+1, block销毁时候,会调用`__main_block_dispose_0`进行内存计数-1.

内存示意图如下,红色箭头指向的引用是强引用还是弱引用取决于外面用到的修饰符是啥.

![image-20210831153029049](https://tva1.sinaimg.cn/large/008i3skNly1gu0087st3hj60uq0pijs602.jpg)

#### 特别注意

不过需要注意的是,上述的内存管理,只针对拷贝到了堆上面的block.如果block在栈上,那么即使内部持有了对象类型的成员变量,也不会,进行内存管理.

看下面的代码,MRC环境

![image-20210831145843850](https://tva1.sinaimg.cn/large/008i3skNly1gtzzb5w076j610s0q6td302.jpg)

可以发现,此时是person所在的作用域已经结束,但是person并没有被释放

假如我们去掉copy,那么block就会变成栈上的block,block就不会对person对象retain,所以出了{},person就被释放了

![image-20210831150034827](https://tva1.sinaimg.cn/large/008i3skNly1gtzzd3tzl8j61560n078202.jpg)



## block的类型

### global

最开始的时候,我们说了block其实是对象,并且打印发现的确,最终是继承自NSObject.

```objective-c
        MyBlock block = ^(){
            NSLog(@"hello world");
        };
//        block();
        NSLog(@"%@",[block class]);
        NSLog(@"%@",[block superclass]);
        NSLog(@"%@",[[block superclass]superclass]);

/*
2021-08-31 10:20:39.431805+0800 blockDemo[2000:72345] __NSGlobalBlock__
2021-08-31 10:20:39.433066+0800 blockDemo[2000:72345] NSBlock
2021-08-31 10:20:39.433148+0800 blockDemo[2000:72345] NSObject
*/
```

不过block的类型不止这一种.还有stack类型的,malloc类型的.

- 没有访问了auto变量的,是global类型
- 访问了auto变量的,是stack类型
- stack类型调用了copy函数,就是malloc类型的

上面的block的确没有访问auto变量

### stack

```objective-c
Person *p = [[Person alloc]init];
p.age = 10;
MyBlock block = ^(){
  NSLog(@"%d",p.age);
};
block();
NSLog(@"%@",[block class]);
NSLog(@"%@",[block superclass]);
NSLog(@"%@",[[block superclass]superclass]);
/*
2021-08-31 12:16:17.232693+0800 blockDemo[2804:135783] 10
2021-08-31 12:16:17.233276+0800 blockDemo[2804:135783] __NSMallocBlock__
2021-08-31 12:16:17.233620+0800 blockDemo[2804:135783] NSBlock
2021-08-31 12:16:17.233690+0800 blockDemo[2804:135783] NSObject
2021-08-31 12:16:17.233742+0800 blockDemo[2804:135783] -[Person dealloc]
*/
```

上面不是说,是访问了自动变量的应该是stack类型的block吗?但是为何打印出来的是malloc呢?

这是因为是ARC导致的.ARC特定的情况下,编译器会自动将stack类型的block拷贝到堆上.

我们可以先调成MRC看看上面的情况应该是stack类型的block

```objective-c
2021-08-31 14:17:46.230177+0800 blockDemo[3203:165010] 10
2021-08-31 14:17:46.230708+0800 blockDemo[3203:165010] __NSStackBlock__
2021-08-31 14:17:46.230778+0800 blockDemo[3203:165010] NSBlock
2021-08-31 14:17:46.230831+0800 blockDemo[3203:165010] NSObject
```

发现在MRC情况下的确是stack类型的block

**MRC下调用copy**

```objective-c
        MyBlock block = [^(){
            NSLog(@"%d",p.age);
        } copy];
        /*
2021-08-31 14:19:54.010844+0800 blockDemo[3224:166442] 10
2021-08-31 14:19:54.011813+0800 blockDemo[3224:166442] __NSMallocBlock__
2021-08-31 14:19:54.011896+0800 blockDemo[3224:166442] NSBlock
2021-08-31 14:19:54.011953+0800 blockDemo[3224:166442] NSObject
        */
```

仍旧调成ARC.

```objective-c
        __weak MyBlock block = ^(){
            NSLog(@"%d",p.age);
        };
        block();
        /*
2021-08-31 14:21:32.211373+0800 blockDemo[3248:167801] 10
2021-08-31 14:21:32.212369+0800 blockDemo[3248:167801] __NSStackBlock__
2021-08-31 14:21:32.212497+0800 blockDemo[3248:167801] NSBlock
2021-08-31 14:21:32.212659+0800 blockDemo[3248:167801] NSObject
2021-08-31 14:21:32.212731+0800 blockDemo[3248:167801] -[Person dealloc]
        */
```

可以发现,当没有强指针指向的时候,的确是stack类型的block

### malloc

主要有如下的情况

- block作为函数返回值

```objective-c

MyBlock test1(){
    int a = 10;
    return  ^(){
        NSLog(@"hello world %d",a);
    };
}

......
MyBlock block = test1();
.....
/*
2021-08-31 14:26:25.732344+0800 blockDemo[3315:171031] hello world 10
2021-08-31 14:26:25.733020+0800 blockDemo[3315:171031] __NSMallocBlock__
2021-08-31 14:26:25.733403+0800 blockDemo[3315:171031] NSBlock
2021-08-31 14:26:25.733507+0800 blockDemo[3315:171031] NSObject
2021-08-31 14:26:25.733571+0800 blockDemo[3315:171031] -[Person dealloc]
*/
```

- block赋值给_strong指针(参见上面stack目录下代码)
- block作为Cocoa API中方法名含有usingBlock的方法的参数

```objective-c
        void (^testBlock)(id obj,NSUInteger idx,BOOL *stop) = ^(id obj,NSUInteger idx,BOOL *stop){
            NSLog(@"obj:%@,idx:%ld",obj,idx);
        };
        [[NSMutableArray arrayWithArray:@[@1,@2]] enumerateObjectsUsingBlock:testBlock];
        /*
2021-08-31 14:31:11.315402+0800 blockDemo[3340:173601] hello world 10
2021-08-31 14:31:11.316661+0800 blockDemo[3340:173601] __NSMallocBlock__
2021-08-31 14:31:11.316831+0800 blockDemo[3340:173601] NSBlock
2021-08-31 14:31:11.317005+0800 blockDemo[3340:173601] NSObject
2021-08-31 14:31:11.317187+0800 blockDemo[3340:173601] obj:1,idx:0
2021-08-31 14:31:11.317257+0800 blockDemo[3340:173601] obj:2,idx:1
2021-08-31 14:31:11.317330+0800 blockDemo[3340:173601] -[Person dealloc]
        */
```

- block作为GCD API的参数

```objective-c
        int a = 10;
        MyBlock block = ^(){
            NSLog(@"hello world %d",a);
        };
        block();
        ...
				dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), block);
/*
2021-08-31 14:42:00.857665+0800 blockDemo[3445:180495] hello world 10
2021-08-31 14:42:00.864244+0800 blockDemo[3445:180495] __NSMallocBlock__
2021-08-31 14:42:00.864349+0800 blockDemo[3445:180495] NSBlock
2021-08-31 14:42:00.864422+0800 blockDemo[3445:180495] NSObject
*/
```

## __block的底层实现是什么?本质是?

有时候,我们想在block内部修改局部变量,发现无法直接修改

![image-20210831144359622](https://tva1.sinaimg.cn/large/008i3skNly1gtzyvvqjdnj610406i3za02.jpg)

当然,我们可以使用静态变量,但是缺点是静态变量在程序运行期间一直保存着.

### __block修饰变量类型

使用`__block`可以解决

```objective-c
        __block int age = 10;
        MyBlock block = ^(){
            age = 20;
            NSLog(@"hello world %d",age);
       };
        block();
/*
2021-08-31 15:04:33.331051+0800 blockDemo[3798:197912] hello world 20
*/
```

为什么呢?转成c++代码

```objective-c
struct __Block_byref_age_0 {
  void *__isa;
__Block_byref_age_0 *__forwarding;
 int __flags;
 int __size;
 int age;
};

struct __main_block_impl_0 {
  struct __block_impl impl;
  struct __main_block_desc_0* Desc;
  __Block_byref_age_0 *age; // by ref
  __main_block_impl_0(void *fp, struct __main_block_desc_0 *desc, __Block_byref_age_0 *_age, int flags=0) : age(_age->__forwarding) {
    impl.isa = &_NSConcreteStackBlock;
    impl.Flags = flags;
    impl.FuncPtr = fp;
    Desc = desc;
  }
};
static void __main_block_func_0(struct __main_block_impl_0 *__cself) {
  __Block_byref_age_0 *age = __cself->age; // bound by ref

            (age->__forwarding->age) = 20;
            NSLog((NSString *)&__NSConstantStringImpl__var_folders_07_lywlrnd57s387lb3xy4nzwcr0000gp_T_main_e5425b_mi_0,(age->__forwarding->age));
       }
static void __main_block_copy_0(struct __main_block_impl_0*dst, struct __main_block_impl_0*src) {_Block_object_assign((void*)&dst->age, (void*)src->age, 8/*BLOCK_FIELD_IS_BYREF*/);}

static void __main_block_dispose_0(struct __main_block_impl_0*src) {_Block_object_dispose((void*)src->age, 8/*BLOCK_FIELD_IS_BYREF*/);}

static struct __main_block_desc_0 {
  size_t reserved;
  size_t Block_size;
  void (*copy)(struct __main_block_impl_0*, struct __main_block_impl_0*);
  void (*dispose)(struct __main_block_impl_0*);
} __main_block_desc_0_DATA = { 
  0, 
  sizeof(struct __main_block_impl_0), 
  __main_block_copy_0, 
  __main_block_dispose_0
};

int main(int argc, const char * argv[]) {
    /* @autoreleasepool */ { __AtAutoreleasePool __autoreleasepool; 
     
    __Block_byref_age_0 age = {(void*)0,(__Block_byref_age_0 *)&age, 0, sizeof(__Block_byref_age_0), 10};
                            
        MyBlock block = &__main_block_impl_0(__main_block_func_0, &__main_block_desc_0_DATA, (__Block_byref_age_0 *)&age, 570425344));
        block->FuncPtr(block);
    }
    return 0;
}
```

可以发现,原先定义的int age,在底层被包装成了`__Block_byref_age_0`对象.里面封装了`int age`

调用的时候是访问了对象中的成员age,这样我们就可以理解为啥加上__block之后就可以修改了

### __block修饰对象类型?

正常来说,对象类型的可以直接在block中访问(我们访问一个对象主要是访问属性),但是假如真的要给这个对象重新赋值呢?

![image-20210831151742734](https://tva1.sinaimg.cn/large/008i3skNly1gtzzux9dd8j615g0ekq4q02.jpg)

发现也不可以直接修改.

那么被__block修饰的对象类型的底层结构长什么样子呢?

```c++
struct __Block_byref_p_0 {
  void *__isa;
__Block_byref_p_0 *__forwarding;
 int __flags;
 int __size;
 void (*__Block_byref_id_object_copy)(void*, void*);
 void (*__Block_byref_id_object_dispose)(void*);
 Person *__strong p;
};

struct __main_block_impl_0 {
  struct __block_impl impl;
  struct __main_block_desc_0* Desc;
  __Block_byref_p_0 *p; // by ref
  __main_block_impl_0(void *fp, struct __main_block_desc_0 *desc, __Block_byref_p_0 *_p, int flags=0) : p(_p->__forwarding) {
    impl.isa = &_NSConcreteStackBlock;
    impl.Flags = flags;
    impl.FuncPtr = fp;
    Desc = desc;
  }
};
static void __main_block_func_0(struct __main_block_impl_0 *__cself) {
  __Block_byref_p_0 *p = __cself->p; // bound by ref

            (p->__forwarding->p) = ((Person *(*)(id, SEL))(void *)objc_msgSend)((id)objc_getClass("Person"), sel_registerName("new"));
            NSLog((NSString *)&__NSConstantStringImpl__var_folders_07_lywlrnd57s387lb3xy4nzwcr0000gp_T_main_3291d2_mi_0,(p->__forwarding->p));
  
       }
static void __main_block_copy_0(struct __main_block_impl_0*dst, struct __main_block_impl_0*src) {_Block_object_assign((void*)&dst->p, (void*)src->p, 8/*BLOCK_FIELD_IS_BYREF*/);}

static void __main_block_dispose_0(struct __main_block_impl_0*src) {_Block_object_dispose((void*)src->p, 8/*BLOCK_FIELD_IS_BYREF*/);}

static struct __main_block_desc_0 {
  size_t reserved;
  size_t Block_size;
  void (*copy)(struct __main_block_impl_0*, struct __main_block_impl_0*);
  void (*dispose)(struct __main_block_impl_0*);
} __main_block_desc_0_DATA = { 0, sizeof(struct __main_block_impl_0), __main_block_copy_0, __main_block_dispose_0};
int main(int argc, const char * argv[]) {
    /* @autoreleasepool */ { __AtAutoreleasePool __autoreleasepool; 
  __Block_byref_p_0 p = {
    0,
    (__Block_byref_p_0 *)&p, 
    33554432, 
    sizeof(__Block_byref_p_0), 
    __Block_byref_id_object_copy_131, 
    __Block_byref_id_object_dispose_131, 
    ((Person *(*)(id, SEL))(void *)objc_msgSend)((id)((Person *(*)(id, SEL))(void *)objc_msgSend)((id)objc_getClass("Person"), sel_registerName("alloc")), sel_registerName("init"))};
                            
        MyBlock block = &__main_block_impl_0((void *)__main_block_func_0, &__main_block_desc_0_DATA, (__Block_byref_p_0 *)&p, 570425344));
        block->FuncPtr(block);
    }
    return 0;
}
```

可以发现,也是person也是被包装成了`__Block_byref_p_0`里面的成员.并且block默认对`__Block_byref_p_0`是强引用.__Block_byref_p_0对person 的引用,(下图中红色箭头指向的这个引用)则取决于person被如何修饰.

如果用weak修饰person

```c++
struct __Block_byref_p_0 {
  void *__isa;
__Block_byref_p_0 *__forwarding;
 int __flags;
 int __size;
 void (*__Block_byref_id_object_copy)(void*, void*);
 void (*__Block_byref_id_object_dispose)(void*);
 Person *__weak p;
};

struct __main_block_impl_0 {
  struct __block_impl impl;
  struct __main_block_desc_0* Desc;
  __Block_byref_p_0 *p; // by ref
  __main_block_impl_0(void *fp, struct __main_block_desc_0 *desc, __Block_byref_p_0 *_p, int flags=0) : p(_p->__forwarding) {
    impl.isa = &_NSConcreteStackBlock;
    impl.Flags = flags;
    impl.FuncPtr = fp;
    Desc = desc;
  }
};
```

则`__Block_byref_p_0`对p也是弱引用,内存引用结构如下.

![image-20210831152844953](https://tva1.sinaimg.cn/large/008i3skNly1gu006e3w24j60qc0jogm902.jpg)



## 循环引用

block的循环引用非常的常见,控制器引用了一个block,block内部又引用控制器

ARC下的解法是`__weak`,鉴于有可能执行block的时候,self被释放了,weakself就是nil,所以我们通常会在block内部声明一个强引用.以便于让block内部的代码可以执行完毕.

![image-20210831154418435](https://tva1.sinaimg.cn/large/008i3skNly1gu00mljwzdj60ta09s0te02.jpg)



MRC下的解法是`__unsafe_unretain`,鉴于__block修饰的话,生成的包装对象不会对person进行retain操作,所以MRC情况下通过`__block`也可以可以解决循环引用问题.

`__unsafe_unretain`和`__weak`的区别是被__weak修饰的变量在释放后,weak指针会自动设置为nil,而前者不会,前者是不安全的.

