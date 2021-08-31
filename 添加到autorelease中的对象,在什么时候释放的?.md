在MRC环境,谁创建,谁释放.一个对象在不用的时候需要调用release方法来释放.但是这样我们在调用了release之后又访问了,就会出问题.因而可以调用autorelease,这样对象会被加入自动释放池,由自动释放池来决定释放时机.

MRC情况下:

![image-20210830170959250](https://tva1.sinaimg.cn/large/008i3skNly1gtyxhfjyb9j615q0hgmz902.jpg)

从图中可以看出,如果我们不自己调用release的话对象不会被释放

![image-20210830171130026](https://tva1.sinaimg.cn/large/008i3skNly1gtyxj057mnj616w0nkdjr02.jpg)

调用release就会被释放

或者调用autorelease

![image-20210830171211923](https://tva1.sinaimg.cn/large/008i3skNly1gtyxjqcjifj61460nk0ww02.jpg)

那么自动释放池的原理是什么呢?我们用clang将代码转成c++代码

```c++
  NSLog((NSString *)&__NSConstantStringImpl__var_folders_07_lywlrnd57s387lb3xy4nzwcr0000gp_T_main_50230b_mi_0);

    /* @autoreleasepool */ { __AtAutoreleasePool __autoreleasepool; 

        NSLog((NSString *)&__NSConstantStringImpl__var_folders_07_lywlrnd57s387lb3xy4nzwcr0000gp_T_main_50230b_mi_1);
                            
        Person *p = ((Person *(*)(id, SEL))(void *)objc_msgSend)((id)((Person *(*)(id, SEL))(void *)objc_msgSend)((id)objc_getClass("Person"), sel_registerName("alloc")), sel_registerName("init"));
    }

    NSLog((NSString *)&__NSConstantStringImpl__var_folders_07_lywlrnd57s387lb3xy4nzwcr0000gp_T_main_50230b_mi_2);
```

可以看到,总共5行,4个log操作,一个定义person的.自动释放池中的代码就下面三句.

```c++
 /* @autoreleasepool */ {
 	__AtAutoreleasePool __autoreleasepool; 
   
   
        NSLog((NSString *)&__NSConstantStringImpl__var_folders_07_lywlrnd57s387lb3xy4nzwcr0000gp_T_main_50230b_mi_1);
 	
 	   Person *p = ((Person *(*)(id, SEL))(void *)objc_msgSend)((id)((Person *(*)(id, SEL))(void *)objc_msgSend)((id)objc_getClass("Person"), sel_registerName("alloc")), sel_registerName("init"));
 }
```

在最新的objc源码中找不到这个类型,`__AtAutoreleasePool`,不过通过查看汇编,我们可以发现,底层调用了函数`objc_autoreleasePoolPush`

![image-20210830172506128](https://tva1.sinaimg.cn/large/008i3skNly1gtyxx5okbzj614m0r4aho02.jpg)

源码如下

```c++
void *
objc_autoreleasePoolPush(void)
{
    return AutoreleasePoolPage::push();
}

...
  
      static inline void *push() 
    {
        id *dest;
        if (slowpath(DebugPoolAllocation)) {
            // Each autorelease pool starts on a new pool page.
            dest = autoreleaseNewPage(POOL_BOUNDARY);
        } else {
            dest = autoreleaseFast(POOL_BOUNDARY);
        }
        ASSERT(dest == EMPTY_POOL_PLACEHOLDER || *dest == POOL_BOUNDARY);
        return dest;
    }
```

push的逻辑很清楚,传入一个`POOL_BOUNDARY`,检查有没有自动释放池页,没有就创建一个

```c++
autoreleaseNewPage(POOL_BOUNDARY);
...

    static __attribute__((noinline))
    id *autoreleaseNewPage(id obj)
    {
        AutoreleasePoolPage *page = hotPage();
        if (page) return autoreleaseFullPage(obj, page);
        else return autoreleaseNoPage(obj);
    }

```

可知,自动释放池底层用到的数据类型为**AutoreleasePoolPage**,数据结构如下

```c++
struct AutoreleasePoolPageData
{

	magic_t const magic;
	__unsafe_unretained id *next;
	pthread_t const thread;
	AutoreleasePoolPage * const parent;
	AutoreleasePoolPage *child;
	uint32_t const depth;
	uint32_t hiwat;
};

....
  
  
class AutoreleasePoolPage : private AutoreleasePoolPageData
{
	friend struct thread_data_t;

public:
	static size_t const SIZE =
#if PROTECT_AUTORELEASEPOOL
		PAGE_MAX_SIZE;  // must be multiple of vm page size
#else
		PAGE_MIN_SIZE;  // size and alignment, power of 2
#endif
    
private:
	static pthread_key_t const key = AUTORELEASE_POOL_KEY;
	static uint8_t const SCRIBBLE = 0xA3;  // 0xA3A3A3A3 after releasing
	static size_t const COUNT = SIZE / sizeof(id);
    static size_t const MAX_FAULTS = 2;
}
```

本质上是一个双向链表.

有就调用

```c++
     dest = autoreleaseFast(POOL_BOUNDARY);
     
     ...
     
         static inline id *autoreleaseFast(id obj)
    {
        AutoreleasePoolPage *page = hotPage();
        if (page && !page->full()) {
            return page->add(obj);
        } else if (page) {
            return autoreleaseFullPage(obj, page);
        } else {
            return autoreleaseNoPage(obj);
        }
    }
```



通过查看汇编,也可以知道,在自动释放池结束,调用了`objc_autoreleasePoolPop`方法

![image-20210830172821704](https://tva1.sinaimg.cn/large/008i3skNly1gtyy0k9onej61560f0aek02.jpg)

源代码如下

```c++
void
objc_autoreleasePoolPop(void *ctxt)
{
    AutoreleasePoolPage::pop(ctxt);
}

...
    static inline void
    pop(void *token)
    {
        AutoreleasePoolPage *page;
        id *stop;
        if (token == (void*)EMPTY_POOL_PLACEHOLDER) {
            // Popping the top-level placeholder pool.
            page = hotPage();
            if (!page) {
                // Pool was never used. Clear the placeholder.
                return setHotPage(nil);
            }
            // Pool was used. Pop its contents normally.
            // Pool pages remain allocated for re-use as usual.
            page = coldPage();
            token = page->begin();
        } else {
            page = pageForPointer(token);
        }

        stop = (id *)token;
        if (*stop != POOL_BOUNDARY) {
            if (stop == page->begin()  &&  !page->parent) {
                // Start of coldest page may correctly not be POOL_BOUNDARY:
                // 1. top-level pool is popped, leaving the cold page in place
                // 2. an object is autoreleased with no pool
            } else {
                // Error. For bincompat purposes this is not 
                // fatal in executables built with old SDKs.
                return badPop(token);
            }
        }

        if (slowpath(PrintPoolHiwat || DebugPoolAllocation || DebugMissingPools)) {
            return popPageDebug(token, page, stop);
        }

        return popPage<false>(token, page, stop);
    }
```

我们再调用下autorelease

```
 Person *p = [[[Person alloc]init] autorelease];
```

底层实际调用了`objc_autorelease`

![image-20210830174131739](https://tva1.sinaimg.cn/large/008i3skNly1gtyye9detgj61680r0qag02.jpg)

```c++
id
objc_autorelease(id obj)
{
    if (obj->isTaggedPointerOrNil()) return obj;
    return obj->autorelease();
}

...
  public:
    static inline id autorelease(id obj)
    {
        ASSERT(!obj->isTaggedPointerOrNil());
        id *dest __unused = autoreleaseFast(obj);
        return obj;
    }

...
      static inline id *autoreleaseFast(id obj)
    {
        AutoreleasePoolPage *page = hotPage();
        if (page && !page->full()) {
            return page->add(obj);
        } else if (page) {
            return autoreleaseFullPage(obj, page);
        } else {
            return autoreleaseNoPage(obj);
        }
    }
```

可以看到最终也是调用到`autoreleaseFast`,获取hotpage,

- 如果获取不到,就创建
- 如果获取到了,并且没满,就添加
- 如果获取到了,并且满了,再创建一个节点.

综上,我们可以确定,在

- 创建自动释放池的时候,会调用push
- 在作用域结束,会调用pop
- 在调用autorelease会将对象添加到自动释放池(根据自动释放池的状态,做相应的操作)

自动释放池内部存储了除了自身的变量,剩下的空间,存储的就是被添加到autorelease中的对象的地址.以及边界标记.

有一个系统的函数可以打印自动释放池的状况

```c++
extern void _objc_autoreleasePoolPrint(void);
```

我们可以试试

```c++
#import "Person.h"
extern void _objc_autoreleasePoolPrint(void);
int main(int argc, const char * argv[]) {
    @autoreleasepool {
        Person *p = [[[Person alloc]init] autorelease];
        _objc_autoreleasePoolPrint();
    }
    return 0;
}
/*
objc[8039]: ##############
objc[8039]: AUTORELEASE POOLS for thread 0x1000ebe00
objc[8039]: 2 releases pending.
objc[8039]: [0x10380a000]  ................  PAGE  (hot) (cold)
objc[8039]: [0x10380a038]  ################  POOL 0x10380a038
objc[8039]: [0x10380a040]       0x10053efb0  Person
objc[8039]: ##############
2021-08-30 17:50:09.286930+0800 autoreleaseDemo[8039:760201] -[Person dealloc]
*/
```

可以看到,自动释放池中有两个对象,一个就是我们定义的Person,一个就是`POOL 0x10380a038`,这是一个标记.从尾部清空自动释放池的时候,如果检测到是边界标记,则表示一个自动释放池范围内的对象已经被释放了.

```c++
        // Install the first page.
        AutoreleasePoolPage *page = new AutoreleasePoolPage(nil);
        setHotPage(page);
        
        // Push a boundary on behalf of the previously-placeholder'd pool.
        if (pushExtraBoundary) {
            page->add(POOL_BOUNDARY);
        }
        
        // Push the requested object or pool.
        return page->add(obj);
```

可以看到确实首先添加的是一个标记`POOL_BOUNDARY`,然后才开始添加对象地址的.

我们再大量创建一些对象试试

![QQ20210830-181210-HD](https://tva1.sinaimg.cn/large/008i3skNly1gtyzm3fbntg60go0eeqvf02.gif)

可以看到有两个Page

```
objc[8085]: AUTORELEASE POOLS for thread 0x1000ebe00
objc[8085]: 601 releases pending.
objc[8085]: [0x104809000]  ................  PAGE (full)  (cold)
objc[8085]: [0x104809038]  ################  POOL 0x104809038
objc[8085]: [0x104809040]       0x100506aa0  Person
......
objc[8085]: [0x104809fe8]       0x100616e40  Person
objc[8085]: [0x104809ff0]       0x100616e50  Person
objc[8085]: [0x104809ff8]       0x100616e60  Person
objc[8085]: [0x10300a000]  ................  PAGE  (hot) 
objc[8085]: [0x10300a038]       0x100616e70  Person
objc[8085]: [0x10300a040]       0x100616e80  Person
objc[8085]: [0x10300a048]       0x100616e90  Person
objc[8085]: [0x10300a050]       0x100616ea0  Person
......
objc[8085]: ##############
```

一个page已经满了,另一个没满.

改造下代码

![image-20210830183115021](https://tva1.sinaimg.cn/large/008i3skNly1gtyztzkdcmj60yx0u00zu02.jpg)

可以确认,在自动释放池作用域结束,就会执行pop方法,将里面的对象都释放掉.

那么问题来了,iOS app中自动释放池的结束在程序终结才会走完

```objective-c
int main(int argc, char * argv[]) {
    NSString * appDelegateClassName;
    @autoreleasepool {
        // Setup code that might create autoreleased objects goes here.
        appDelegateClassName = NSStringFromClass([AppDelegate class]);
    }
    return UIApplicationMain(argc, argv, nil, appDelegateClassName);
}

```

啊咧,怎么回事!!!UIApplicationMain没有包在自动释放池里面!!!而且调成MRC情况会直接崩溃.不过手动将return这一行放进autoreleasepool就不会有问题.

我又找了下以前的老项目,发现以前确实是在的

```objective-c

int main(int argc, char * argv[]) {
    @autoreleasepool {
            return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
```

按照之前的分析,程序终止的时候才会将对象释放,但是这肯定是不对的.假如程序一直运行,那么会有大量的对象不会被释放.

那么对象是什么时候被释放的呢?

```objective-c
- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"111");
//     Do any additional setup after loading the view.
    {
        Person *p = [[[Person alloc]init] autorelease];
    }
    NSLog(@"222");
}
/*
2021-08-30 19:02:05.870346+0800 autoreleaseDemoiOS[11071:821395] 111
2021-08-30 19:02:05.870564+0800 autoreleaseDemoiOS[11071:821395] 222
2021-08-30 19:02:05.887948+0800 autoreleaseDemoiOS[11071:821395] -[Person dealloc]
*/
```

当前环境为MRC:

从打印来看,并非是出了作用域,就被释放.

那么是什么时候释放的呢?

系统注册了两个自动释放池相关的观察者,用来处理释放操作.我们打印下

```
observers = (
    "<CFRunLoopObserver 0x6000023085a0 [0x7fff8004b340]>{valid = Yes, activities = 0x1, repeats = Yes, order = -2147483647, callout = _runLoopObserverCallout (0x7fff24192c31), context = (\n    \"<_UIWeakReference: 0x600001008350>\"\n)}",
   ......
    
    "<CFRunLoopObserver 0x600002308460 [0x7fff8004b340]>{valid = Yes, activities = 0xa0, repeats = Yes, order = 2147483647, callout = _runLoopObserverCallout (0x7fff24192c31), context = (\n    \"<_UIWeakReference: 0x600001008350>\"\n)}"
```

啊咧,和以前又不一样

以前是`_wrapRunLoopWithAutoreleasePoolHandler`

不过`activities = 0x1`,`activities = 0xa0`倒是没有变,对应的

```c++
typedef CF_OPTIONS(CFOptionFlags, CFRunLoopActivity) {
    kCFRunLoopEntry = (1UL << 0),       		1    0x1
    kCFRunLoopBeforeTimers = (1UL << 1),  	2
    kCFRunLoopBeforeSources = (1UL << 2),		4
    kCFRunLoopBeforeWaiting = (1UL << 5), 	32
    kCFRunLoopAfterWaiting = (1UL << 6),		64
    kCFRunLoopExit = (1UL << 7),						128
    kCFRunLoopAllActivities = 0x0FFFFFFFU
};
```

`32+128=160=a0`

所以和自动释放池相关的运行时监控了kCFRunLoopEntrykCFRunLoopBeforeWaiting,kCFRunLoopExit.

根据谷歌,

- 在进入运行时的时候调用push

- 在睡眠之前调用pop和push

- 在退出的时候调用pop

所以MRC情况下,应该是对应此运行循环的即将睡眠之前释放对象

监听下主运行循环,发现释放操作的确在即将睡眠之前.不过前面还有其他的状态呢?怎么解释?

```
2021-08-30 20:06:32.557952+0800 autoreleaseDemoiOS[11511:862035] 即将进入runloop
2021-08-30 20:06:32.558111+0800 autoreleaseDemoiOS[11511:862035] 即将处理timer
2021-08-30 20:06:32.558244+0800 autoreleaseDemoiOS[11511:862035] 即将处理input Sources
2021-08-30 20:06:32.573785+0800 autoreleaseDemoiOS[11511:862035] 111
2021-08-30 20:06:32.585354+0800 autoreleaseDemoiOS[11511:862035] -[ViewController viewWillAppear:]
2021-08-30 20:06:32.590492+0800 autoreleaseDemoiOS[11511:862035] -[Person dealloc]
2021-08-30 20:06:32.595233+0800 autoreleaseDemoiOS[11511:862035] 即将处理timer
2021-08-30 20:06:32.595395+0800 autoreleaseDemoiOS[11511:862035] 即将处理input Sources
2021-08-30 20:06:32.596056+0800 autoreleaseDemoiOS[11511:862035] 即将处理timer
2021-08-30 20:06:32.596210+0800 autoreleaseDemoiOS[11511:862035] 即将处理input Sources
2021-08-30 20:06:32.596712+0800 autoreleaseDemoiOS[11511:862035] 即将处理timer
2021-08-30 20:06:32.596869+0800 autoreleaseDemoiOS[11511:862035] 即将处理input Sources
2021-08-30 20:06:32.598555+0800 autoreleaseDemoiOS[11511:862035] 即将处理timer
2021-08-30 20:06:32.598963+0800 autoreleaseDemoiOS[11511:862035] 即将处理input Sources
2021-08-30 20:06:32.599644+0800 autoreleaseDemoiOS[11511:862035] 即将处理timer
2021-08-30 20:06:32.600163+0800 autoreleaseDemoiOS[11511:862035] 即将处理input Sources
2021-08-30 20:06:32.601081+0800 autoreleaseDemoiOS[11511:862035] 即将处理timer
2021-08-30 20:06:32.601582+0800 autoreleaseDemoiOS[11511:862035] 即将处理input Sources
2021-08-30 20:06:32.602317+0800 autoreleaseDemoiOS[11511:862035] 即将处理timer
2021-08-30 20:06:32.602755+0800 autoreleaseDemoiOS[11511:862035] 即将处理input Sources
2021-08-30 20:06:32.603165+0800 autoreleaseDemoiOS[11511:862035] 即将处理timer
2021-08-30 20:06:32.603602+0800 autoreleaseDemoiOS[11511:862035] 即将处理input Sources
2021-08-30 20:06:32.604036+0800 autoreleaseDemoiOS[11511:862035] 即将睡眠
2021-08-30 20:06:32.604461+0800 autoreleaseDemoiOS[11511:862035] -[ViewController viewDidAppear:]
2021-08-30 20:06:32.604870+0800 autoreleaseDemoiOS[11511:862035] 从睡眠中唤醒，处理完唤醒源之前
```

那么在ARC情况下呢?

```objective-c
    NSLog(@"111");
//     Do any additional setup after loading the view.
    {
        Person *p = [[Person alloc]init];
    }
//    NSLog(@"%@",[NSRunLoop mainRunLoop]);
    NSLog(@"222");
    
    - (void)viewWillAppear:(BOOL)animated{
    NSLog(@"%s",__func__);
    [super viewWillAppear:animated];
    
}

- (void)viewDidAppear:(BOOL)animated{
    NSLog(@"%s",__func__);
    [super viewDidAppear:animated];
}


/*
2021-08-30 20:11:47.463140+0800 autoreleaseDemoiOS[11607:866630] 111
2021-08-30 20:11:47.463377+0800 autoreleaseDemoiOS[11607:866630] -[Person dealloc]
2021-08-30 20:11:47.463533+0800 autoreleaseDemoiOS[11607:866630] 222
2021-08-30 20:11:47.473984+0800 autoreleaseDemoiOS[11607:866630] -[ViewController viewWillAppear:]
2021-08-30 20:11:47.488217+0800 autoreleaseDemoiOS[11607:866630] -[ViewController viewDidAppear:]
*/
```

发现在ARC情况下的确是出了作用域就被释放了.



总结:

MRC情况下:运行时来决定释放.

ARC情况下:出了作用域就被释放了.

