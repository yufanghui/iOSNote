block的底层数据结构

oc代码

```objective-c
        void (^block)(void) = ^(void){
            NSLog(@"hello world");
        };
        block();
```

c++代码（简化后，去掉了强转）

```c++
        //定义block
				void (*block)(void) = &__main_block_impl_0(
          __main_block_func_0, &__main_block_desc_0_DATA
        );
				//调用block
       (block)->FuncPtr(block);
```

  __main_block_impl_0的数据结构

```objective-c
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
```

## 变量捕获

### 局部变量

会被捕获。

#### 自动变量

值传递

#### 静态变量

引用传递

#### 两种传递方式差异的原因

因为函数执行完毕，自动变量，就销毁了。访问的时候，就已经销毁了，所以需要直接把值传进去。



### 全局变量

不会捕获，直接访问

#### 自动变量

#### 静态变量

