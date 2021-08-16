# runloop是什么？

顾名思义，跑着的圈。

正常来说，程序完毕就退出了，但是app如果执行完毕就退出，那么用户就无法使用。

runloop本质就是一个“死“循环，以确保程序活着并能够响应用户操作，当有事情的时候干事，没事情的时候休息。

## runloop

看看官方的api介绍

> There is exactly one run loop per thread. You neither create nor destroy a thread’s run loop. Core Foundation automatically creates it for you as needed. You obtain the current thread’s run loop with [`CFRunLoopGetCurrent()`](https://developer.apple.com/documentation/corefoundation/1542428-cfrunloopgetcurrent). Call [`CFRunLoopRun()`](https://developer.apple.com/documentation/corefoundation/1542011-cfrunlooprun) to run the current thread’s run loop in the default mode until the run loop is stopped with [`CFRunLoopStop(_:)`](https://developer.apple.com/documentation/corefoundation/1541796-cfrunloopstop). You can also call [`CFRunLoopRunInMode(_:_:_:)`](https://developer.apple.com/documentation/corefoundation/1541988-cfrunloopruninmode) to run the current thread’s run loop in a specified mode for a set period of time (or until the run loop is stopped). A run loop can only run if the requested mode has at least one source or timer to monitor.

大意如下

1. 一个线程对应一个runloop
2. 不能手动创建和销毁runloop，cf会为我们创建，如果我们需要
3. 获取当前线程的runloop使用`CFRunLoopGetCurrent()`
4. 调用`CFRunLoopRun()`来运行当前线程的runloop,此种方式运行起来的runloop是是运行在默认模式下的。你可以通过调用`CFRunLoopStop(_:)`来暂停这个runloop
5. 如果想启动一个runloop在特定模式,特定的时间段下面，可以使用`CFRunLoopRunInMode(_:_:_:)`
6. 当且仅当runloop至少有一个timer或者source可以被监控，咱们才能开启运行循环。



再看更多的关于runloop的介绍

> A run loop receives events from two different types of sources. *Input sources* deliver asynchronous events, usually messages from another thread or from a different application. *Timer sources* deliver synchronous events, occurring at a scheduled time or repeating interval. Both types of source use an application-specific handler routine to process the event when it arrives.

1. 一个runloop接收两种类型的事件，input源和timer源
2. input源是异步事件。
3. 两种类型的事件源都使用一个application相关的回调来处理

> In addition to handling sources of input, run loops also generate notifications about the run loop’s behavior. Registered *run-loop observers* can receive these notifications and use them to do additional processing on the thread. You use Core Foundation to install run-loop observers on your threads.

1. 除了处理输入源，runloop也会产生关于runloop行为的通知，我们可以通过注册观察者来接收到这些通知。
2. 咱们在自己的线程里面可以注册runloop的观察者



## run loop mode

> A *run loop mode* is a collection of input sources and timers to be monitored and a collection of run loop observers to be notified. Each time you run your run loop, you specify (either explicitly or implicitly) a particular “mode” in which to run. During that pass of the run loop, only sources associated with that mode are monitored and allowed to deliver their events。(Similarly, only observers associated with that mode are notified of the run loop’s progress. Sources associated with other modes hold on to any new events until subsequent passes through the loop in the appropriate mode.

1. 一个run loop mode是一个input源和timer源以及observers的集合
2. 每次，你开启你的运行循环，都是在一个特定的模式下运行。
3. 在运行循环过程中，仅仅和这个mode相关联的source可以被监控，并且被允许传递他们的事件。
4. 类似的，只有和这个mode相关联的观察者会被通知，当前runloop的状况
5. 和其他模式相关联的时间会被hold on,直到后续事件以适当的模式传递给runloop

> In your code, you identify modes by name. Both Cocoa and Core Foundation define a default mode and several commonly used modes, along with strings for specifying those modes in your code. You can define custom modes by simply specifying a custom string for the mode name. Although the names you assign to custom modes are arbitrary, the contents of those modes are not. You must be sure to add one or more input sources, timers, or run-loop observers to any modes you create for them to be useful.

1. 我们根据名称来区分不同的模式
2. Cocoa和Core Foundation定义了一个模式的模式和一些常用的模式，传入不同的字符串来指定模式
3. 你可以自定义模式，通过设置自定义的字符串
4. 设置模式的字符串可以是任意的，但是模式要想能运行起来，那么必须要添加事件源，（timer,source,observer）

下面是系统提供的模式

![image-20210813163611504](https://tva1.sinaimg.cn/large/008i3skNly1gtf8z2ikemj61rw0nsqb302.jpg)

上面有两个模式我们比较熟悉

一个是模式的模式，大多数情况下都是这个

一个是tracking模式，滑动页面的时候用的这个

还有一个比较特殊的模式` common modes`

> This is a configurable group of commonly used modes. Associating an input source with this mode also associates it with each of the modes in the group. For Cocoa applications, this set includes the default, modal, and event tracking modes by default. Core Foundation includes just the default mode initially. You can add custom modes to the set using the `CFRunLoopAddCommonMode` function.

1. 这是一组常用模式的可配置组。
2. 将输入源与此模式关联也将其与组中的每个模式关联。
3. 对于Cocoa应用程序，该集合默认包括默认、模式和事件跟踪模式。
4. Core Foundation最初只包含默认模式。您可以使用' CFRunLoopAddCommonMode '函数向集合添加自定义模式。

## input source

输入源有两个

> Port-based input sources monitor your application’s Mach ports. Custom input sources monitor custom sources of events

1. 一个是基于端口的
2.  一个是自定义的

> The only difference between the two sources is how they are signaled. Port-based sources are signaled automatically by the kernel, and custom sources must be signaled manually from another thread.

两种source的区别在于

1. 基于端口的source是由内核自动的发出信号
2. 自定义source则需要在另一个线程手动触发

### Port-Based Sources





# runloop的实现机制

runloop的API有两层，Foundation层面的和Core Foundation层面的。

Foundation主要是NSRunloop，是对Core Foundation的封装。

咱们主要需要了解的是Core Foundation 是一套c的api。

![1619068-1852c5434bdbff0e.png](https://tva1.sinaimg.cn/large/008i3skNly1gteyhld5qcj60kb0akq3802.jpg)

从图片中，我们可以了解到runloop相关的主要的类以及相互关系。

1. 线程和runloop是一对一的
2. 一个runloop中有多个mode
3. 一个mode中可以添加多个sourece，timeer，observer

app启动之后就会默认开一个主运行循环，和主线程相对应。

程序启动会在多种mode下运行。启动的时候有一个initial mode，默认是一个default mode，滚动scrollview的时候。从一种mode切换到另一种mode，需要退出，然后重新开始一个mode。

mode中会添加诸如timer，source，observer，如果什么都没有，runloop是跑不起来的

```c
typedef struct __CFRunLoop * CFRunLoopRef;

struct __CFRunLoop {
    CFRuntimeBase _base;
    pthread_mutex_t _lock;			/* locked for accessing mode list */
    __CFPort _wakeUpPort;			// used for CFRunLoopWakeUp 
    Boolean _unused;
    volatile _per_run_data *_perRunData;              // reset for runs of the run loop
    pthread_t _pthread;
    uint32_t _winthread;
    CFMutableSetRef _commonModes;
    CFMutableSetRef _commonModeItems;
    CFRunLoopModeRef _currentMode;
    CFMutableSetRef _modes;
    struct _block_item *_blocks_head;
    struct _block_item *_blocks_tail;
    CFAbsoluteTime _runTime;
    CFAbsoluteTime _sleepTime;
    CFTypeRef _counterpart;
};
```

CFRunloopRef是一个结构体指针。指向的结构体为__CFRunLoop，其内部成员有,咱们比较熟悉的

```c
    pthread_mutex_t _lock;  //锁
    pthread_t _pthread;// 线程
    CFRunLoopModeRef _currentMode;//当前模式
    CFMutableSetRef _commonModes;//通用模式
    CFMutableSetRef _commonModeItems;// 通用模式条目
    CFMutableSetRef _modes;//模式集合
```

## timer

其实就是我们平时用到的timer

```c
typedef struct CF_BRIDGED_MUTABLE_TYPE(NSTimer) __CFRunLoopTimer * CFRunLoopTimerRef;

struct __CFRunLoopTimer {
    CFRuntimeBase _base;
    uint16_t _bits;
    pthread_mutex_t _lock;//锁
    CFRunLoopRef _runLoop;//
    CFMutableSetRef _rlModes;
    CFAbsoluteTime _nextFireDate;//下次触发的时间
    CFTimeInterval _interval;		/* immutable */
    CFTimeInterval _tolerance;          /* mutable */
    uint64_t _fireTSR;			/* TSR units */
    CFIndex _order;			/* immutable */
    CFRunLoopTimerCallBack _callout;	/* immutable */  回调
    CFRunLoopTimerContext _context;	/* immutable, except invalidation */
};
```

`CFRunLoopTimerCallBack`回调的定义

```c
typedef void (*CFRunLoopTimerCallBack)(CFRunLoopTimerRef timer, void *info);
```

## source

有两个版本的source:source0和source1。

```c
typedef struct __CFRunLoopSource * CFRunLoopSourceRef;

struct __CFRunLoopSource {
    CFRuntimeBase _base;
    uint32_t _bits;
    pthread_mutex_t _lock;
    CFIndex _order;			/* immutable */
    CFMutableBagRef _runLoops;
    union {
	CFRunLoopSourceContext version0;	/* immutable, except invalidation */ 版本0
        CFRunLoopSourceContext1 version1;	/* immutable, except invalidation */ 版本1
    } _context;
};
```

## observer

```c
typedef struct __CFRunLoopObserver * CFRunLoopObserverRef;

struct __CFRunLoopObserver {
    CFRuntimeBase _base;
    pthread_mutex_t _lock;
    CFRunLoopRef _runLoop;
    CFIndex _rlCount;
    CFOptionFlags _activities;		/* immutable */
    CFIndex _order;			/* immutable */
    CFRunLoopObserverCallBack _callout;	/* immutable */  观察者回调
    CFRunLoopObserverContext _context;	/* immutable, except invalidation */
};
```

观察者回调的定义

```c
typedef void (*CFRunLoopObserverCallBack)(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info);
```



# runloop的应用？

# 自动释放池和runloop的关系

# runloop的挂起和唤醒

