# category相关知识点

## category和类扩展有啥区别？

### **本质区别**

分类里面可以添加方法，属性，协议；类扩展中可以添加方法声明，属性，成员变量，仅仅添加在类扩展中的属性和方法是私有的
分类的底层数据结构是category_t,类扩展不是。添加在分类中的方法列表，属性列表，协议列表，会保存在这个结构体中

```objective-c
struct category_t {
    const char *name;
    classref_t cls;
    WrappedPtr<method_list_t, PtrauthStrip> instanceMethods;
    WrappedPtr<method_list_t, PtrauthStrip> classMethods;
    struct protocol_list_t *protocols;
    struct property_list_t *instanceProperties;
    // Fields below this point are not always present on disk.
    struct property_list_t *_classProperties;
		method_list_t *methodsForMeta(bool isMeta) {
    if (isMeta) return classMethods;
    else return instanceMethods;
}

property_list_t *propertiesForMeta(bool isMeta, struct header_info *hi);

protocol_list_t *protocolsForMeta(bool isMeta) {
    if (isMeta) return nullptr;
    else return protocols;
}
};
```


然后会在runtime加载的时候将分类的方法添加到类的方法列表中。
- 分类的方法在前面，类原始的方法在后面。
- 不同分类之间，后编译的会先添加，因而后编译的分类方法在前面

所以当类，分类中都有相同方法的时候，会调用分类的。
当多个分类有相同方法的时候，会调用后编译的。

### **使用场景：**

分类可以用于将代码拆分。
类扩展用于隐藏私有属性。

load方法和initialize的区别

### **调用方式不同：**

load是直接调用函数
initialize走的是objc_MsgSend

### **调用时机不同：**

load是运行时调用的，而且只会调用一次。
initialize是第一次给一个类发消息时候调用的。

### **调用顺序：**

load

1. 先调用类的，再调用分类的。
2. 先调用父类的，再调用子类的
3. 类同级之间，按照编译顺序调用
4. 分类之间，也按照编译顺序调用(不区分子类父类顺序，只参考编译顺序)



load的函数调用

```c++
load_images(const char *path __unused, const struct mach_header *mh)
{
    ......
    // Call +load methods (without runtimeLock - re-entrant)
    call_load_methods();
}

void call_load_methods(void)
{
    do {
        // 1. Repeatedly call class +loads until there aren't any more
        while (loadable_classes_used > 0) {
            call_class_loads();
        }

     // 2. Call category +loads ONCE
        more_categories = call_category_loads();
    
        // 3. Run more +loads if there are classes OR more untried categories
    } while (loadable_classes_used > 0  ||  more_categories);

}
```



`call_class_loads`

```c++
// Call all +loads for the detached list.
for (i = 0; i < used; i++) {
    Category cat = cats[i].cat;
    load_method_t load_method = (load_method_t)cats[i].method;
    Class cls;
    if (!cat) continue;
    cls = _category_getClass(cat);
    if (cls  &&  cls->isLoadable()) {
        (*load_method)(cls, @selector(load));
        cats[i].cat = nil;
    }
}

call_category_loads:
for (i = 0; i < used; i++) {
    Category cat = cats[i].cat;
    load_method_t load_method = (load_method_t)cats[i].method;
    Class cls;
    if (!cat) continue;

    cls = _category_getClass(cat);
    if (cls  &&  cls->isLoadable()) {
        (*load_method)(cls, @selector(load));
        cats[i].cat = nil;
    }

}
```



#####################准备类和分类的load方法列表###################

```c++
void prepare_load_methods(const headerType *mhdr)
{
    size_t count, i;

    runtimeLock.assertLocked();
    
    classref_t const *classlist =
        _getObjc2NonlazyClassList(mhdr, &count);
    for (i = 0; i < count; i++) {
        schedule_class_load(remapClass(classlist[i]));
    }
    
    category_t * const *categorylist = _getObjc2NonlazyCategoryList(mhdr, &count);
    .....

}


static void schedule_class_load(Class cls)
{
    if (!cls) return;
    ASSERT(cls->isRealized());  // _read_images should realize

    if (cls->data()->flags & RW_LOADED) return;
    
    //先添加父类的。然后才添加当前类
    // Ensure superclass-first ordering
    schedule_class_load(cls->getSuperclass());
    //添加方法到loadable_list列表中。
    add_class_to_loadable_list(cls);
    cls->setInfo(RW_LOADED);

}
```

测试

```
/*
 此时调用顺序为：
 Person
 Dog
 Student
 PersonStudy
 StudentTest1
 PersonEat
 StudentTest2
 */
```

**initialize的调用顺序**

1. 先调用父类的，再调用自身的
2. 如果自身没有，因为消息发送机制，最终还是会调用到父类的，造成一种父类多次调用的现象。
3. 有分类的，优先调用先编译的分类的。
    initialize的函数调用

```c++
void initializeNonMetaClass(Class cls)
{
 Class supercls;
 // Make sure super is done initializing BEFORE beginning to initialize cls.
 // See note about deadlock above.
 //拿到父类
 supercls = cls->getSuperclass();
 //先调用父类的
 if (supercls  &&  !supercls->isInitialized()) {
     initializeNonMetaClass(supercls);
 }

 {
     //调用自身的
     callInitialize(cls);
 }
}
```

示例

```
/*
[Person alloc];
[Person alloc];
[Dog alloc];
[Student alloc];
所以调用顺序为
 PersonStudy
 Dog
 StudentTest1
*/
```

