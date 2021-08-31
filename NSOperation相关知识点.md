# 思考题:

> 1. 有任务B和C依赖于任务A,B和C可以并发执行,在B和C都执行完毕,执行任务D(主线程更新UI),如何用NSOperation实现?
> 2. GCD如何实现?

工作中其实没怎么用到NSOperation,主要用的还是GCD,NSThread,无奈面试总要问,那就带着问题把它就搞清楚吧.

# 相关的类,API

- NSOperation 

抽象父类,不应该使用他

- NSInvocationOperation

- NSBlockOperation

系统封装的继承自NSOperation的类,可以直接使用

- [`NSOperationQueue`](doc://com.apple.documentation/documentation/foundation/nsoperationqueue?language=occ) 

操作队列,分为主队列和自定义队列.添加到主队列中的任务会放在主线程执行;自定义队列通过设置最大并发数来决定是串行执行还是并发执行.

# 基本使用

## NSInvocationOperation的使用

### 单独使用NSInvocationOperation不会开启新线程

NSOperation是一个抽象类,不直接使用,可以自定义类继承NSOperation,使用这个自定义类;也可以使用系统提供的子类NSInvocationOperation和NSBlockOperation.

![image-20210829211223012](https://tva1.sinaimg.cn/large/008i3skNly1gtxyvc708sj30i809vmy6.jpg)

可以发现,并没有开启新线程.配合[`NSOperationQueue`](doc://com.apple.documentation/documentation/foundation/nsoperationqueue?language=occ) 使用才会开启新线程

### 基本使用

```objective-c
    NSInvocationOperation *operation = [[NSInvocationOperation alloc]initWithTarget:self selector:@selector(task) object:nil];
//    [operation start];
    NSOperationQueue *queue = [[NSOperationQueue alloc]init];
    [queue addOperation:operation];
}

- (void)task{
    NSLog(@"%@",[NSThread currentThread]);
}
//<NSThread: 0x6000007357c0>{number = 4, name = (null)}
```

### block形式添加任务

```objective-c
    NSOperationQueue *queue = [[NSOperationQueue alloc]init];
    [queue addOperationWithBlock:^{
            NSLog(@"--block---%@",[NSThread currentThread]);
    }];
//--block---<NSThread: 0x600000a60e80>{number = 5, name = (null)}
```

### 添加多个任务,并是否阻塞当前线程

```objective-c
    NSOperationQueue *queue = [[NSOperationQueue alloc]init];
    NSInvocationOperation *op1 = [[NSInvocationOperation alloc]initWithTarget:self selector:@selector(op1) object:nil];
    NSInvocationOperation *op2 = [[NSInvocationOperation alloc]initWithTarget:self selector:@selector(op2) object:nil];
    NSInvocationOperation *op3 = [[NSInvocationOperation alloc]initWithTarget:self selector:@selector(op3) object:nil];

    [queue addOperations:@[op1,op2,op3] waitUntilFinished:NO];
    NSLog(@"1111");

- (void)op1{
    NSLog(@"%@",[NSThread currentThread]);
}

- (void)op2{
    NSLog(@"%@",[NSThread currentThread]);

}
- (void)op3{
    NSLog(@"%@",[NSThread currentThread]);
}
/*

2021-08-30 09:27:53.494049+0800 NSOperationDemeOC[4230:402969] 1111
2021-08-30 09:27:53.494161+0800 NSOperationDemeOC[4230:403137] <NSThread: 0x60000189c180>{number = 6, name = (null)}
2021-08-30 09:27:53.494161+0800 NSOperationDemeOC[4230:403141] <NSThread: 0x6000018c7c40>{number = 3, name = (null)}
2021-08-30 09:27:53.494161+0800 NSOperationDemeOC[4230:403139] <NSThread: 0x6000018cbb80>{number = 5, name = (null)}
*/
```

将`waitUntilFinished`参数设置为YES,就会阻塞当前线程

```objective-c
/*
2021-08-30 09:32:33.587490+0800 NSOperationDemeOC[4279:407490] <NSThread: 0x600000a20cc0>{number = 4, name = (null)}
2021-08-30 09:32:33.587490+0800 NSOperationDemeOC[4279:407486] <NSThread: 0x600000a25780>{number = 6, name = (null)}
2021-08-30 09:32:33.587494+0800 NSOperationDemeOC[4279:407491] <NSThread: 0x600000a29200>{number = 3, name = (null)}
2021-08-30 09:32:33.587726+0800 NSOperationDemeOC[4279:407285] 1111
*/
```

## NSBlockOperation的使用

### 只有一个任务的时候不会开启新线程

````objective-c

    NSBlockOperation *op = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"block op %@",[NSThread currentThread]);
    }];
    [op start];
    /*
    block op <NSThread: 0x600001ecc040>{number = 1, name = main}
    */
````

### 追加任务可能会在子线程执行,也可能不是

```objective-c
    NSBlockOperation *op = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"block op %@",[NSThread currentThread]);
    }];
    [op addExecutionBlock:^{
            NSLog(@"add op1%@",[NSThread currentThread]);
    }];
    [op start];
    /*
2021-08-30 09:41:29.968183+0800 NSOperationDemeOC[4357:414400] add op1<NSThread: 0x600000ef0540>{number = 1, name = main}
2021-08-30 09:41:29.968187+0800 NSOperationDemeOC[4357:414631] block op <NSThread: 0x600000eb9900>{number = 7, name = (null)}
    */
```

追加的任务刚好开了,多试几次

![image-20210830094405071](https://tva1.sinaimg.cn/large/008i3skNly1gtykliutm9j613e0jmtfz02.jpg)

可以知道,添加的任务不一定就在子线程.

异步请求回来需要在主线程更新UI,如何做呢?往主队列中添加任务即可

## 子线程请求数据主线程更新UI(线程间通信)

```objective-c
    [[[NSOperationQueue alloc]init]addOperationWithBlock:^{
        NSLog(@"数据请求~~~%@",[NSThread currentThread]);
        sleep(3);
        [[NSOperationQueue mainQueue]addOperationWithBlock:^{
            NSLog(@"更新UI~~~%@",[NSThread currentThread]);
        }];
    }];
/*
2021-08-30 09:53:01.718296+0800 NSOperationDemeOC[4486:424114] 数据请求~~~<NSThread: 0x600001266200>{number = 4, name = (null)}
2021-08-30 09:53:04.722553+0800 NSOperationDemeOC[4486:424069] 更新UI~~~<NSThread: 0x60000125c100>{number = 1, name = main}
*/
```



# 进阶使用

## 并发执行还是串行执行

> maxConcurrentOperationCount

如果不设置,那么添加到队列的任务默认是并发执行的.

```objective-c
    NSOperationQueue *queue = [[NSOperationQueue alloc]init];
//    [queue setMaxConcurrentOperationCount:1];

    NSInvocationOperation *op1 = [[NSInvocationOperation alloc]initWithTarget:self selector:@selector(op1) object:nil];
    NSInvocationOperation *op2 = [[NSInvocationOperation alloc]initWithTarget:self selector:@selector(op2) object:nil];
    NSInvocationOperation *op3 = [[NSInvocationOperation alloc]initWithTarget:self selector:@selector(op3) object:nil];
    [queue addOperations:@[op1,op2,op3] waitUntilFinished:YES];
    NSLog(@"1111");
    
- (void)op1{
    NSLog(@"op1---%@",[NSThread currentThread]);
    sleep(1);
}

- (void)op2{
    NSLog(@"op2---%@",[NSThread currentThread]);
    sleep(1.5);
}

- (void)op3{
    NSLog(@"op3---%@",[NSThread currentThread]);
    sleep(2);
}
/*
2021-08-30 10:08:36.988550+0800 NSOperationDemeOC[4655:436953] op1---<NSThread: 0x600003d1a800>{number = 4, name = (null)}
2021-08-30 10:08:36.988601+0800 NSOperationDemeOC[4655:436959] op3---<NSThread: 0x600003d43b80>{number = 6, name = (null)}
2021-08-30 10:08:36.988601+0800 NSOperationDemeOC[4655:436954] op2---<NSThread: 0x600003d46600>{number = 5, name = (null)}
2021-08-30 10:08:38.992758+0800 NSOperationDemeOC[4655:436895] 1111
*/
```

设置maxConcurrentOperationCount最大并发数

```objective-c
    [queue setMaxConcurrentOperationCount:1];
/*
2021-08-30 10:50:54.322319+0800 NSOperationDemeOC[4832:460152] op1---<NSThread: 0x600001a59840>{number = 6, name = (null)}
2021-08-30 10:50:55.323037+0800 NSOperationDemeOC[4832:460149] op2---<NSThread: 0x600001a25f80>{number = 5, name = (null)}
2021-08-30 10:50:56.323609+0800 NSOperationDemeOC[4832:460149] op3---<NSThread: 0x600001a25f80>{number = 5, name = (null)}
2021-08-30 10:50:58.327120+0800 NSOperationDemeOC[4832:459992] 1111
*/
```

多个子线程任务,串行执行了.实现了线程同步.

## 按照特定顺序执行一些任务

通过addDependency可以实现.

```objective-c
    NSOperationQueue *queue = [[NSOperationQueue alloc]init];
    NSInvocationOperation *op1 = [[NSInvocationOperation alloc]initWithTarget:self selector:@selector(op1) object:nil];
    NSInvocationOperation *op2 = [[NSInvocationOperation alloc]initWithTarget:self selector:@selector(op2) object:nil];
    NSInvocationOperation *op3 = [[NSInvocationOperation alloc]initWithTarget:self selector:@selector(op3) object:nil];
    NSInvocationOperation *op4 = [[NSInvocationOperation alloc]initWithTarget:self selector:@selector(op4) object:nil];
    [op2 addDependency:op1];
    [op3 addDependency:op1];
    [queue addOperations:@[op1,op2,op3] waitUntilFinished:YES];

- (void)op1{
    sleep(5);
    NSLog(@"op1---%@",[NSThread currentThread]);

}
- (void)op2{
    sleep(3);
    NSLog(@"op2---%@",[NSThread currentThread]);

}
- (void)op3{
    sleep(1);
    NSLog(@"op3---%@",[NSThread currentThread]);
}
    /*
2021-08-30 11:27:04.475705+0800 NSOperationDemeOC[5231:490432] op1---<NSThread: 0x600000585440>{number = 3, name = (null)}
2021-08-30 11:27:05.476558+0800 NSOperationDemeOC[5231:490432] op3---<NSThread: 0x600000585440>{number = 3, name = (null)}
2021-08-30 11:27:07.477020+0800 NSOperationDemeOC[5231:490435] op2---<NSThread: 0x600000586e40>{number = 4, name = (null)}
    */
```

此处,我们将任务2,和任务3 的执行都依赖于任务1的执行.除此之外,我们也可以设置一个任务,依赖于两个任务的执行结束.于是我们可以这样实现开篇的思考题1

# 思考题解答

````objective-c
    NSOperationQueue *queue = [[NSOperationQueue alloc]init];
//    [queue addOperation:op];
    NSInvocationOperation *op1 = [[NSInvocationOperation alloc]initWithTarget:self selector:@selector(op1) object:nil];
    NSInvocationOperation *op2 = [[NSInvocationOperation alloc]initWithTarget:self selector:@selector(op2) object:nil];
    NSInvocationOperation *op3 = [[NSInvocationOperation alloc]initWithTarget:self selector:@selector(op3) object:nil];
    NSInvocationOperation *op4 = [[NSInvocationOperation alloc]initWithTarget:self selector:@selector(op4) object:nil];
    [op2 addDependency:op1];
    [op3 addDependency:op1];
    [op4 addDependency:op2];
    [op4 addDependency:op3];
    [queue addOperations:@[op1,op2,op3,op4] waitUntilFinished:YES];
    
    - (void)op1{
    sleep(5);
    NSLog(@"op1---%@",[NSThread currentThread]);

}
- (void)op2{
    sleep(3);
    NSLog(@"op2---%@",[NSThread currentThread]);

}
- (void)op3{
    sleep(1);
    NSLog(@"op3---%@",[NSThread currentThread]);
}
- (void)op4{
    sleep(0);
    NSLog(@"op4---%@",[NSThread currentThread]);
}

    /*
2021-08-30 11:30:21.535846+0800 NSOperationDemeOC[5264:493564] op1---<NSThread: 0x600003282ac0>{number = 7, name = (null)}
2021-08-30 11:30:22.539614+0800 NSOperationDemeOC[5264:493564] op3---<NSThread: 0x600003282ac0>{number = 7, name = (null)}
2021-08-30 11:30:24.541835+0800 NSOperationDemeOC[5264:493557] op2---<NSThread: 0x6000032e5dc0>{number = 3, name = (null)}
2021-08-30 11:30:24.542315+0800 NSOperationDemeOC[5264:493564] op4---<NSThread: 0x600003282ac0>{number = 7, name = (null)}
    */
````

不过此处有一个问题.我们的示例代码中的任务都是同步任务,但是我们项目中用到的任务本身就是异步的.

```objective-c
    NSOperationQueue *queue = [[NSOperationQueue alloc]init];

    NSInvocationOperation *task1 = [[NSInvocationOperation alloc]initWithTarget:self selector:@selector(task1) object:nil];

    NSInvocationOperation *task2 = [[NSInvocationOperation alloc]initWithTarget:self selector:@selector(task2) object:nil];

    NSInvocationOperation *task3 = [[NSInvocationOperation alloc]initWithTarget:self selector:@selector(task3) object:nil];

    NSInvocationOperation *task4 = [[NSInvocationOperation alloc]initWithTarget:self selector:@selector(task4) object:nil];

    [task2 addDependency:task1];
    [task3 addDependency:task1];
    [task4 addDependency:task3];
    [task4 addDependency:task2];

    [queue addOperations:@[task1,task2,task3,task4] waitUntilFinished:YES];
}

- (void)task1{
    dispatch_queue_t queue = dispatch_queue_create("queue1", NULL);
    __weak typeof(self) weakSelf = self;
    dispatch_async(queue, ^{
        NSLog(@"task1---begin");
        sleep(3);
        NSLog(@"task1---end");
        weakSelf.task1Res = @"task1Res";
    });
}

- (void)task2{
    dispatch_queue_t queue = dispatch_queue_create("queue2", NULL);
    __weak typeof(self) weakSelf = self;
    dispatch_async(queue, ^{
        NSLog(@"task2---begin");
        sleep(1);
        NSLog(@"task2---end");
        weakSelf.task1Res = @"task2Res";
    });
}
- (void)task3{
    dispatch_queue_t queue = dispatch_queue_create("queue3", NULL);
    __weak typeof(self) weakSelf = self;
    dispatch_async(queue, ^{
        NSLog(@"task3---begin");
        sleep(1);
        NSLog(@"task3---end");
        weakSelf.task1Res = @"task3Res";
    });
}

- (void)task4{
    NSLog(@"task4---主线程更新UI");
}

/*
2021-08-30 11:56:12.505620+0800 NSOperationDemeOC[5458:510844] task1---begin
2021-08-30 11:56:12.505656+0800 NSOperationDemeOC[5458:510846] task2---begin
2021-08-30 11:56:12.505678+0800 NSOperationDemeOC[5458:510841] task3---begin
2021-08-30 11:56:12.505682+0800 NSOperationDemeOC[5458:510842] task4---主线程更新UI
2021-08-30 11:56:13.507431+0800 NSOperationDemeOC[5458:510841] task3---end
2021-08-30 11:56:13.507431+0800 NSOperationDemeOC[5458:510846] task2---end
2021-08-30 11:56:15.507812+0800 NSOperationDemeOC[5458:510844] task1---end
*/
```

可以发现,并不能满足我们的需求.

## 信号量解决

`dispatch_semaphore_wait`检测到信号量等于0的时候,可以阻塞一个任务.直到信号量大于0.上面的NSOperation添加依赖的做法,改造如下,就可以拦截异步任务.

```objective-c
    _sem = dispatch_semaphore_create(0);
    NSOperationQueue *queue = [[NSOperationQueue alloc]init];
    NSInvocationOperation *task1 = [[NSInvocationOperation alloc]initWithTarget:self selector:@selector(task1) object:nil];
    NSInvocationOperation *task2 = [[NSInvocationOperation alloc]initWithTarget:self selector:@selector(task2) object:nil];
    NSInvocationOperation *task3 = [[NSInvocationOperation alloc]initWithTarget:self selector:@selector(task3) object:nil];
    [task3 addDependency:task1];
    [task3 addDependency:task2];
    [queue addOperations:@[task1,task2,task3] waitUntilFinished:NO];
    
......
    
- (void)task1{
    dispatch_queue_t queue = dispatch_queue_create("queue1", DISPATCH_QUEUE_CONCURRENT);
    __weak typeof(self) weakSelf = self;
    dispatch_async(queue, ^{
        NSLog(@"task1---begin");
        sleep(3);
        NSLog(@"task1---end");
        weakSelf.task1Res = @"task1Res";
        dispatch_semaphore_signal(weakSelf.sem);
    });
    dispatch_semaphore_wait(_sem, DISPATCH_TIME_FOREVER);
}

- (void)task2{
    dispatch_queue_t queue = dispatch_queue_create("queue2", DISPATCH_QUEUE_CONCURRENT);
    __weak typeof(self) weakSelf = self;
    dispatch_async(queue, ^{
        NSLog(@"task2---begin");
        sleep(1);
        NSLog(@"task2---end");
        weakSelf.task1Res = @"task2Res";
        dispatch_semaphore_signal(weakSelf.sem);
    });
    dispatch_semaphore_wait(_sem, DISPATCH_TIME_FOREVER);
}
- (void)task3{
    dispatch_queue_t queue = dispatch_queue_create("queue3", DISPATCH_QUEUE_CONCURRENT);
    __weak typeof(self) weakSelf = self;
    dispatch_async(queue, ^{
        NSLog(@"task3---begin");
        sleep(0);
        NSLog(@"task3---end");
        weakSelf.task1Res = @"task3Res";
    });
}

/*
2021-08-30 13:25:21.726767+0800 NSOperationDemeOC[6169:574316] task1---begin
2021-08-30 13:25:21.726781+0800 NSOperationDemeOC[6169:574319] task2---begin
2021-08-30 13:25:22.730590+0800 NSOperationDemeOC[6169:574319] task2---end
2021-08-30 13:25:24.728830+0800 NSOperationDemeOC[6169:574316] task1---end
2021-08-30 13:25:24.729298+0800 NSOperationDemeOC[6169:574313] task3---begin
2021-08-30 13:25:24.729892+0800 NSOperationDemeOC[6169:574313] task3---end
*/
```

## dispatch_group_enter 和 dispatch_group_leave

```objective-c
   
    dispatch_group_t group = dispatch_group_create();
    __weak typeof(self) weakSelf = self;

    dispatch_queue_t queue = dispatch_queue_create("queue", DISPATCH_QUEUE_CONCURRENT);
    
    dispatch_group_enter(group);
    dispatch_async(queue, ^{
        NSLog(@"task1---begin");
        sleep(3);
        NSLog(@"task1---end");
        weakSelf.task1Res = @"task1Res";
        dispatch_group_leave(group);
    });


    dispatch_group_enter(group);
    dispatch_async(queue, ^{
        NSLog(@"task2---begin");
        sleep(1);
        NSLog(@"task2---end");
        weakSelf.task1Res = @"task2Res";
        dispatch_group_leave(group);
    });

    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        NSLog(@"task3:Both operations completed!");
    });

    /*
2021-08-30 12:52:54.045887+0800 NSOperationDemeOC[5927:550450] task2---begin
2021-08-30 12:52:54.045887+0800 NSOperationDemeOC[5927:550453] task1---begin
2021-08-30 12:52:55.046178+0800 NSOperationDemeOC[5927:550450] task2---end
2021-08-30 12:52:57.050726+0800 NSOperationDemeOC[5927:550453] task1---end
2021-08-30 12:52:57.050976+0800 NSOperationDemeOC[5927:550341] task3:Both operations completed!
    */
```

