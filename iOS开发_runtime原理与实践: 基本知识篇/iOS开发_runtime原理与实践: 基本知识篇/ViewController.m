//
//  ViewController.m
//  iOS开发_runtime原理与实践: 基本知识篇
//
//  Created by Mac-Qke on 2019/7/15.
//  Copyright © 2019 Mac-Qke. All rights reserved.
//

#import "ViewController.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import "Person.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

//1 .运行时
//1.1 基本概念: 运行时
//1.1.1 Runtime 的概念 Runtime 又叫运行时，是一套底层的 C 语言 API，其为 iOS 内部的核心之一，我们平时编写的 OC 代码，底层都是基于它来实现的。
- (void)test1{
    //发送消息
    //[receiver message];
    
    // 底层运行时会被编译器转化为：
   // objc_msgSend(receiver, selector)
    
    // 如果其还有参数比如：
    //[receiver message:(id)arg...]
    
    // 底层运行时会被编译器转化为：
    //objc_msgSend(receiver,selector,arg1,arg2)
}

//1.1.2 Runtime 的作用
//Objc 在三种层面上与 Runtime 系统进行交互：
//
//通过 Objective-C 源代码
//通过 Foundation 框架的 NSObject 类定义的方法
//通过对 Runtime 库函数的直接调用

//1.2 各种基本概念的C表达
//1.2.1 类 类对象(Class)是由程序员定义并在运行时由编译器创建的，它没有自己的实例变量，这里需要注意的是类的成员变量和实例方法列表是属于实例对象的，但其存储于类对象当中的
// Class
//  An opaque type that represents an Objective-C class.

//  typedef struct objc_class *Class;

//  类是由Class类型来表示的，它是一个objc_class结构类型的指针

// objc_class

/*
 
 struct objc_class {
 Class _Nonnull isa  OBJC_ISA_AVAILABILITY;
 
 #if !__OBJC2__
 Class _Nullable super_class                              OBJC2_UNAVAILABLE;
 const char * _Nonnull name                               OBJC2_UNAVAILABLE;
 long version                                             OBJC2_UNAVAILABLE;
 long info                                                OBJC2_UNAVAILABLE;
 long instance_size                                       OBJC2_UNAVAILABLE;
 struct objc_ivar_list * _Nullable ivars                  OBJC2_UNAVAILABLE;
 struct objc_method_list * _Nullable * _Nullable methodLists                    OBJC2_UNAVAILABLE;
 struct objc_cache * _Nonnull cache                       OBJC2_UNAVAILABLE;
 struct objc_protocol_list * _Nullable protocols          OBJC2_UNAVAILABLE;
 #endif
 
 } OBJC2_UNAVAILABLE;  // Use `Class` instead of `struct objc_class *`
 
*/

// 参数解析
// isa指针是和Class同类型的objc_class结构指针，类对象的指针指向其所属的类，即元类。元类中存储着类对象的类方法，当访问某个类的类方法时会通过该isa指针从元类中寻找方法对应的函数指针。

//super_class指针指向该类所继承的父类对象，如果该类已经是最顶层的根类(如NSObject或NSProxy), 则 super_class为NULL。

// cache：用于缓存最近使用的方法。一个接收者对象接收到一个消息时，它会根据isa指针去查找能够响应这个消息的对象。在实际使用中，这个对象只有一部分方法是常用的，很多方法其实很少用或者根本用不上。这种情况下，如果每次消息来时，我们都是methodLists中遍历一遍，性能势必很差。这时，cache就派上用场了。在我们每次调用过一个方法后，这个方法就会被缓存到cache列表中，下次调用的时候runtime就会优先去cache中查找，如果cache没有，才去methodLists中查找方法。这样，对于那些经常用到的方法的调用，但提高了调用的效率。

// version：我们可以使用这个字段来提供类的版本信息。这对于对象的序列化非常有用，它可是让我们识别出不同类定义版本中实例变量布局的改变。

// protocols：当然可以看出这一个objc_protocol_list的指针。关于objc_protocol_list的结构体构成后面会讲。


// 获取类的类名
//const char * class_getName (Class cls)

//动态创建类

- (void)test2 {
    // 创建一个新类和元类
    Class objc_allocateClassPair (Class superClass, const char *name, size_t extraBytes); //如果创建的是root class，则superclass为Nil。extraBytes通常为0
    
    // 销毁一个类及其相关联的类
    void objc_disposeClassPair (Class cls);//在运行中还存在或存在子类实例，就不能够调用这个。
    
    // 在应用中注册由objc_allocateClassPair创建的类
    void objc_registerClassPair (Class cls);
//创建了新类后，然后使用class_addMethod，class_addIvar函数为新类添加方法，实例变量和属性后再调用这个来注册类，再之后就能够用了。
}


//1.2.2  对象
//实例对象是我们对类对象alloc或者new操作时所创建的，在这个过程中会拷贝实例所属的类的成员变量，但并不拷贝类定义的方法。调用实例方法时，系统会根据实例的isa指针去类的方法列表及父类的方法列表中寻找与消息对应的selector指向的方法
/// Represents an instance of a class.
//struct objc_object {
//    Class _Nonnull isa  OBJC_ISA_AVAILABILITY;
//};
//这个结构体只有一个isa变量，指向实例对象所属的类。任何带有以指针开始并指向类结构的结构都可以被视作objc_object, 对象最重要的特点是可以给其发送消息。 NSObject类的alloc和allocWithZone:方法使用函数class_createInstance来创建objc_object数据结构。


// /// A pointer to an instance of a class.
//typedef struct objc_object *id;
//#endif
//id类型，它是一个objc_object结构类型的指针。该类型的对象可以转换为任何一种对象，类似于C语言中void *指针类型的作用。

// 对对象的类操作
- (void)test3{
    // 返回给定对象的类名
   // const char * object_getClassName (id obj);
    
    // 返回对象的类
    //Class object_getClass (id obj);
    
    //  设置对象的类
   // Class object_setClass (id obj, Class cls);
    
}

// 获取对象的类定义
- (void)test4{
   // 获取已注册的类定义的列表
    //int objc_getClassList (Class *buffer, int bufferCount);
    
    // 创建并返回一个指向所有已注册类的指针列表
   // Class * objc_copyClassList(<#unsigned int * _Nullable outCount#>);
    
    // 返回指定类的类定义
   // Class  objc_lookUpClass(<#const char * _Nonnull name#>)
   // Class objc_getClass(<#const char * _Nonnull name#>)
   // Class objc_getRequiredClass(<#const char * _Nonnull name#>)
    
   // 返回指定类的元类
   // Class objc_getMetaClass (const char *name)
}

// 动态创建对象
- (void)test5{
    // 创建类实例
  // id  class_createInstance(<#Class  _Nullable __unsafe_unretained cls#>, <#size_t extraBytes#>) //会在heap里给类分配内存。这个方法和+alloc方法类似。

  // 在指定位置创建类实例
  // id  objc_consstructInstance (Class cls , void *bytes);
    
    // 销毁类实例
  // void * objc_destructInstance (id obj); //不会释放移除任何相关引用
    
    
}

//1.2.3 元类
// 元类(Metaclass)就是类对象的类，每个类都有自己的元类，也就是objc_class结构体里面isa指针所指向的类. Objective-C的类方法是使用元类的根本原因，因为其中存储着对应的类对象调用的方法即类方法。

// 当向对象发消息，runtime会在这个对象所属类方法列表中查找发送消息对应的方法，但当向类发送消息时，runtime就会在这个类的meta class方法列表里查找。所有的meta class，包括Root class，Superclass，Subclass的isa都指向Root class的meta class，这样能够形成一个闭环。

// 元类，就像之前的类一样，它也是一个对象，也可以调用它的方法。所以这就意味着它必须也有一个类。所有的元类都使用根元类作为他们的类。比如所有NSObject的子类的元类都会以NSObject的元类作为他们的类。

// 根据这个规则，所有的元类使用根元类作为他们的类，根元类的元类则就是它自己。也就是说基类的元类的isa指针指向他自己。

// 操作函数
// 获取类的父类
- (void)test6{
   // super_class和meta-class
    
  // 获取类的父类
  // Class  class_getSuperclass(<#Class  _Nullable __unsafe_unretained cls#>)
    
  // 判断给定的Class是否是一个meta class
  // BOOL  class_isMetaClass(<#Class  _Nullable __unsafe_unretained cls#>)
    
    // instance_size
    
    // 获取实例大小
   // size_t class_getInstanceSize(<#Class  _Nullable __unsafe_unretained cls#>)
}


//1.2.4 属性
// 在Objective-C中，属性(property)和成员变量是不同的。那么，属性的本质是什么？它和成员变量之间有什么区别？简单来说属性是添加了存取方法的成员变量
//  @property = ivar + getter + setter;
// 我们每定义一个@property都会添加对应的ivar, getter和setter到类结构体objc_class中。具体来说，系统会在objc_ivar_list中添加一个成员变量的描述，然后在methodLists中分别添加setter和getter方法的描述。下面的objc_property_t是声明的属性的类型，是一个指向objc_property结构体的指针。
//遍历获取所有属性Property
- (void)getAllProperty {
    unsigned int propertyCount = 0;
    objc_property_t *propertyList = class_copyPropertyList([Person class], &propertyCount);
    for (unsigned int i = 0; i < propertyCount; i++) {
        objc_property_t *thisProperty = &propertyList[i];
        const char* propertyName = property_getName(*thisProperty);
        NSLog(@"Person拥有的属性为: '%s'", propertyName);
    }
}

// objc_property_t
// /// An opaque type that represents an Objective-C declared property.
//  typedef struct objc_property *objc_property_t;


//objc_property_attribute_t
//typedef struct {
//const char * _Nonnull name;           /**< The name of the attribute */
//const char * _Nonnull value;          /**< The value of the attribute (usually empty) */
//} objc_property_attribute_t;

//属性类型  name值：T  value：变化
//编码类型  name值：C(copy) &(strong) W(weak)空(assign) 等 value：无
//非/原子性 name值：空(atomic) N(Nonatomic)  value：无
//变量名称  name值：V  value：变化

- (void)test7{
    objc_property_attribute_t nonatomic = {"N",""};
    objc_property_attribute_t strong = {"&",""};
    objc_property_attribute_t type = {"T","@\"NSString\""};
    objc_property_attribute_t ivar = {"V","_country"};
    objc_property_attribute_t attributes[] = {nonatomic,strong,type,ivar};
    
    BOOL result = class_addProperty([Person class], "name", attributes, 4);
    
    
}

// 操作函数
- (void)test8{
    // 获取属性名
    // const char * property_getName(<#objc_property_t  _Nonnull property#>)
    
    // 获取属性特性描述字符串
    // const char * property_getAttributes(<#objc_property_t  _Nonnull property#>)
    
    //获取属性中指定的特性
    // char *   property_copyAttributeValue(<#objc_property_t  _Nonnull property#>, <#const char * _Nonnull attributeName#>)
    // 获取属性的特性列表
    // objc_property_attribute_t * property_copyAttributeList(<#objc_property_t  _Nonnull property#>, <#unsigned int * _Nullable outCount#>)
}

//1.2.5 成员变量
// Ivar: 实例变量类型，是一个指向objc_ivar结构体的指针

/// An opaque type that represents an instance variable.
//typedef struct objc_ivar *Ivar;

//- struct objc_ivar {
//    char * _Nullable ivar_name                               OBJC2_UNAVAILABLE;
//    char * _Nullable ivar_type                               OBJC2_UNAVAILABLE;
//    int ivar_offset                                          OBJC2_UNAVAILABLE;
//#ifdef __LP64__
//    int space                                                OBJC2_UNAVAILABLE;
//#endif
//}

// ivar_offset。它表示基地址偏移字节。

// 操作函数
- (void)test9{
    //成员变量操作函数
    // 修改类实例的实例变量的值
   //Ivar object_setInstanceVariable ( id obj, const char *name, void *value );
    
    // 获取对象实例变量的值
   // Ivar object_getInstanceVariable ( id obj, const char *name, void **outValue );
    
   // 返回指向给定对象分配的任何额外字节的指针
    //void * object_getIndexedIvars ( id obj );
    
    // 返回对象中实例变量的值
   // id object_getIvar(<#id  _Nullable obj#>, <#Ivar  _Nonnull ivar#>)
    
    // 设置对象中实例变量的值
    // object_setIvar(<#id  _Nullable obj#>, <#Ivar  _Nonnull ivar#>, <#id  _Nullable value#>)
    
    
    
    // 获取类成员变量的信息
    //Ivar class_getClassVariable(<#Class  _Nullable __unsafe_unretained cls#>, <#const char * _Nonnull name#>)
    
    // 添加成员变量
    // BOOL class_addIvar(<#Class  _Nullable __unsafe_unretained cls#>, <#const char * _Nonnull name#>, <#size_t size#>, <#uint8_t alignment#>, <#const char * _Nullable types#>) //这个只能够向在runtime时创建的类添加成员变量
    
    // 获取整个成员变量列表
    // Ivar * class_copyPropertyList(<#Class  _Nullable __unsafe_unretained cls#>, <#unsigned int * _Nullable outCount#>) //必须使用free()来释放这个数组
}

//1.2.6 成员变量列表
// 在objc_class中，所有的成员变量、属性的信息是放在链表ivars中的。ivars是一个数组，数组中每个元素是指向Ivar(变量信息)的指针。

// objc_ivar_list
//struct objc_ivar_list {
//int ivar_count                                           OBJC2_UNAVAILABLE;
//#ifdef __LP64__
//int space                                                OBJC2_UNAVAILABLE;
//#endif
///* variable length structure */
//struct objc_ivar ivar_list[1]                            OBJC2_UNAVAILABLE;
//}

////遍历获取Person类所有的成员变量IvarList
- (void)getAllIvarList{
    unsigned int methodCount = 0;
    Ivar *ivars = class_copyIvarList([Person class], &methodCount);
    for (unsigned int i = 0; i < methodCount; i ++) {
        Ivar ivar = ivars[i];
        const char *name = ivar_getName(ivar);
        const char *type = ivar_getTypeEncoding(ivar);
        NSLog(@"Person拥有的成员变量的类型为%s，名字为 %s ",type, name);
    }
    free(ivars);
}

//1.2.7 方法
// Method 代表类中某个方法的类型

// Method
///// An opaque type that represents a method in a class definition.
//typedef struct objc_method *Method;

// objc_method 存储了方法名，方法类型和方法实现：
//objc_method
//struct objc_method {
//SEL _Nonnull method_name                                 OBJC2_UNAVAILABLE;
//char * _Nullable method_types                            OBJC2_UNAVAILABLE;
//IMP _Nonnull method_imp                                  OBJC2_UNAVAILABLE;
//}                                                            OBJC2_UNAVAILABLE;

//方法名类型为 SEL
//方法类型 method_types 是个 char 指针，存储方法的参数类型和返回值类型
//method_imp 指向了方法的实现，本质是一个函数指针

// Method = SEL + IMP + method_types，相当于在SEL和IMP之间建立了一个映射。

// 操作函数
// 调用指定方法的实现，返回的是方法实现时的返回，参数receiver不能为空，这个比method_getImplementation和method_getName快
- (void)test10{
//调用指定方法的实现，返回的是方法实现时的返回，参数receiver不能为空，这个比method_getImplementation和method_getName快
  // id method_invoke ( id receiver, Method m, ... );
    
   // 调用返回一个数据结构的方法的实现
   // void method_invoke_stret ( id receiver, Method m, ... );
    
    // 获取方法名，希望获得方法明的C字符串，使用sel_getName(method_getName(method))
  // SEL  method_getName(<#Method  _Nonnull m#>)
    
    //// 返回方法的实现
  // IMP method_getImplementation(<#Method  _Nonnull m#>)
    
    // 获取描述方法参数和返回值类型的字符串
   //  const char *  method_getTypeEncoding(<#Method  _Nonnull m#>)
    
    //// 获取方法的返回值类型的字符串
    // char * method_copyReturnType ( Method m );
    
    // 获取方法的指定位置参数的类型字符串
     //void method_copyArgumentType(<#Method  _Nonnull m#>, <#unsigned int index#>)
    
    //// 返回方法的参数的个数
    // unsigned int method_getNumberOfArguments(<#Method  _Nonnull m#>)
    
    // // 通过引用返回方法指定位置参数的类型字符串
    // void  method_getArgumentType(<#Method  _Nonnull m#>, <#unsigned int index#>, <#char * _Nullable dst#>, void)
    
    // // 返回指定方法的方法描述结构体
    //  struct objc_method_description * method_getDescription ( Method m );
    
    // 设置方法的实现
    // IMP method_setImplementation(<#Method  _Nonnull m#>, <#IMP  _Nonnull imp#>)
    
    // 交换两个方法的实现
   // void method_exchangeImplementations(<#Method  _Nonnull m1#>, <#Method  _Nonnull m2#>)
    
    
}

//1.2.8
// 方法调用是通过查询对象的isa指针所指向归属类中的methodLists来完成。

//objc_method_list
//struct objc_method_list {
//struct objc_method_list * _Nullable obsolete             OBJC2_UNAVAILABLE;
//
//int method_count                                         OBJC2_UNAVAILABLE;
//#ifdef __LP64__
//int space                                                OBJC2_UNAVAILABLE;
//#endif
///* variable length structure */
//struct objc_method method_list[1]                        OBJC2_UNAVAILABLE;
//}


// 操作函数

- (void)test11{
    // 添加方法
//和成员变量不同的是可以为类动态添加方法。如果有同名会返回NO，修改的话需要使用method_setImplementation
  // BOOL class_addMethod(<#Class  _Nullable __unsafe_unretained cls#>, <#SEL  _Nonnull name#>, <#IMP  _Nonnull imp#>, <#const char * _Nullable types#>)
    
    // 获取实例方法
  // Method class_getInstanceMethod(<#Class  _Nullable __unsafe_unretained cls#>, <#SEL  _Nonnull name#>)
    
    // 获取类方法
  // Method  class_getClassMethod(<#Class  _Nullable __unsafe_unretained cls#>, <#SEL  _Nonnull name#>)
    
    
    
}

@end
