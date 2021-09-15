## 使用流程图，尽可能详细的描述一个vc从初始化到展示屏幕上的过程



## 代码删除链表中重复的元素



## 写一个函数，递归删除制定路径下的所有文件

## wkwebview有啥优势

- 内存开销大大降低了.

- 提供了进度属性

  

  

## +load与+initialize的区别

- 加载时机不同

load是runtime时候调用

initialize是第一次给对象发消息的时候调用

- 调用方式不同

load是直接找到imp调用的

initialize是走的objc_MsgSend

- 因而调用逻辑也不太一样

load是先调用类的,再调用分类的.先调用父类的,再调用子类的.同级之间,取决于编译顺序

initialize是先调用父类的



## 通知多次add会接受几次

添加几次,接收几次

## 栈与链表的优缺点

栈:先进后出

链表:

## 自动释放池数据结构，为什么是双向链表。

因为自动释放池在释放对象的时候,是从尾部开始释放的,假如当一个自动释放池页都释放完了,还没有遇到边界标记,那么就需要找到前面的一个节点,这时候指向parent的指针就排上用处了,可以直接拿到上一个节点.假如是单链表的话,则需要遍历比对.用双向链表来实现的话,找到上一个节点的时间复杂度就是O(1),高效.

## category方法覆盖，可以做到指定吗？

可以,改变编译顺序即可.



## atomic

setter,getter加锁了.保证了属性设值取值是原子性的.是线程同步的.但是不保证使用的时候是线程安全的.比如还需要对属性进行其他操作,逻辑操作,比如数组,使用了atomic,只是给数组赋值的时候是安全的,假如多线程添加删除元素,那么就可能出现问题.

![image-20210830145134059](https://tva1.sinaimg.cn/large/008i3skNly1gtyts5rbykj60q00by3z902.jpg)

Getter

![image-20210830145154790](https://tva1.sinaimg.cn/large/008i3skNly1gtyts8asoij613a0c2myd02.jpg)

## weak的实现原理

底层维护了一个哈希表.Key是所指对象的地址，Value是weak指针的地址（这个地址的值是所指对象指针的地址）数组。

1. 初始化时：runtime会调用objc_initWeak函数，初始化一个新的weak指针指向对象的地址。
2. 添加引用时：objc_initWeak函数会调用 objc_storeWeak() 函数， objc_storeWeak() 的作用是更新指针指向，创建对应的弱引用表。
3. 释放时，调用clearDeallocating函数。clearDeallocating函数首先根据对象地址获取所有weak指针地址的数组，然后遍历这个数组把其中的数据设为nil，最后把这个entry从weak表中删除，最后清理对象的记录。





## boss直聘面试相关

1. FMDB如何实现读写安全

答到了pthread_rw_lock,或者异步栅栏

1. UIButton state有哪些?
2. 崩溃监控是如何做的?
3. 苹果是如何优化NSUserDefault的?

缓存

1. A,B,C,D四个控制器,Pop到B如何做?

直接移除后面的控制器,将当前控制器设置为B

1. MJExtension和YYModel对比.

YYModel的性能更好.因为MJExtension容器用的NSArray和NSDictionary,以及KVC,YYModel用的是Core Foundation容器,以及objc_MsgSend发消息.

1. 字典转模型如何处理int等基本类型的赋值操作

kvc已经处理了,不用处理.





## 搜狐视频面试

- 客户端如何进行证书认证的?

- 一道题.frame,bounds,anchorPoint

- 删除给定路径下的全部文件

- self.view = aView?
- srollview的实现原理.
- 
- 

## 怦然心动面试

- frame,bounds

frame是视图在父视图中的参考位置.

bounds是子视图看待当前视图左上角的位置.这点可能会引起误解.

修改bounds的size,中心点不变,但是size会缩放.



- srollview的实现原理.
- uiview和calayer的关系





属性

copy.strong

NSString





