iOS中方法调用本质是调用了一个函数`objc_msgSend`,这个函数是用汇编实现的.发消息可以分成三个阶段

- 消息发送
- 动态方法解析
- 消息转发

下面就具体说说这三个阶段

## 消息发送

消息发送阶段,会通过receiver找到其isa指向的对象,会先去当前类的方法缓存中查找(cache_t method_cache),然后通过isa找到指向的类对象(或者元类对象)去其中查找方法.

- 如果是给实例对象发消息(调用对象方法),那么就是去类对象中查找方法.
- 如果是给类对象发消息(调用类方法),那么就是去元类对象中查找方法.

如果找不到,那么就会进入动态方法解析阶段.

## 动态方法解析

如果调用的方法并且在消息发送阶段找不到该方法,那么就会触发可以在该方法中动态添加实现.

```objective-c
+ (BOOL)resolveClassMethod:(SEL)sel
- (BOOL)resolveClassMethod:(SEL)sel
```

## 消息转发

如果说动态方法解析阶段什么都不做,那么就会崩溃.如果我们实现了

```objective-c
- (NSMethodSignature *)methodSignatureForSelector:(**SEL**)aSelector;
+ (NSMethodSignature *)methodSignatureForSelector:(**SEL**)aSelector;
```

这两个方法,那么就会触发

```objective-c
- (void)forwardInvocation:(NSInvocation *)anInvocation;
+ (void)forwardInvocation:(NSInvocation *)anInvocation;
```

在`methodSignatureForSelector`中,需要返回一个方法签名.

`NSInvocation`中包装了方法的全部内容.我们可以做想做的事情.

