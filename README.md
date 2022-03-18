<!-- 
使用Dart mixin机制实现PageRoute模块化
-->

## 库说明

`flutter_mixin_router` 库与其说是一个路由框架，还不如称之为一种思想，利于`Dart`的mixin特性，参考`flutter`源码中`WidgetsFlutterBinding`所总结出来的。
库本身代码核心类仅仅只有两个`MixinRouterContainer`、`MixinRouterInterceptContainer`。前者用于粘合各模块的`PageRoute`列表，后者用于拦截`PageRoute`跳转，
比如拦截用户未登录情况下打开个人中心页面。

## 使用说明

项目结构如下：

```

 --- Home                           : 大厅业务模块
 
  ---- home_page_1.dart             : 大厅页面1
  
  ---- home_page_2.dart             : 大厅页面2
  
  ---- home_router_table.dart       : 使用mixin_router创建的文件，用于聚合该模块所有路由，即：大厅子路由表
  
 --- Mine                           : 个人业务模块     
 
  ---- mine_page.dart               : 个人页面1
  
  ---- mine_router_table.dart       : 使用mixin_router创建的文件，用于聚合该模块所有路由，即：个人子路由表
 
 main.dart                          : 启动文件(entry-point)
 
 app_router_center.dart             : 使用mixin_router创建的文件，用于聚合所有模块(大厅业务模块 和 个人业务模块)，即：路由总表
```

页面相关的代码这里就不再说明了，重点文件`main.dart`、`app_router_center.dart`、`home_router_table.dart` 和 `mine_router_table.dart`。

main.dart:

```dart
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mixin Route Test',
      //配置初始化路由，建议定义静态字段
      initialRoute: '/home_page_1',
      //从路由总表中获取App所有路由
      routes: AppRouterCenter.share.installRouters(),
    );
  }
}
```

app_router_center.dart

```dart

//使用mixin机制，将各路由模块组装
class AppRouterCenter extends MixinRouterInterceptContainer
    with HomeRouterTable, MineRouterTable {
  AppRouterCenter._();

  static final AppRouterCenter _instance = AppRouterCenter._();

  static AppRouterCenter get share => _instance;
}
```

home_router_table.dart

```dart

//使用mixin定义大厅路由子表
mixin HomeRouterTable on MixinRouterContainer {
  @override
  Map<String, WidgetBuilder> installRouters() {
    Map<String, WidgetBuilder> superRouteList = super.installRouters();
    //添加本模块路由
    Map<String, WidgetBuilder> routeList = {
      '/home_page_1': (context) => Home1Page(),
      '/home_page_2': (context) => Home2Page(),
    };
    routeList.addAll(superRouteList);
    return routeList;
  }
}
```

mine_router_table.dart

```dart

//使用mixin定义个人路由子表，与大厅路由子表定义不同，此处继承MixinRouterInterceptContainer，支持拦截
//而 MixinRouterInterceptContainer extends MixinRouterContainer
mixin MineRouterTable on MixinRouterInterceptContainer {

  @override
  Map<String, WidgetBuilder> installRouters() {
    //注册路由拦截，return true 表示消费本次跳转，否则进行路由跳转
    registerRouteInterceptor('/mine_page', (context, pageName, pushType,
        {arguments, predicate}) {
      if (isLogin) {
        return false;
      }
      print('toLogin');
      return true;
    });
    Map<String, WidgetBuilder> superRouteList = super.installRouters();
    //添加本模块路由
    Map<String, WidgetBuilder> routeList = {
      '/mine_page': (context) => MinePage(),
    };
    routeList.addAll(superRouteList);
    return routeList;
  }
}
```

打开指定页面：

```dart
//可配置打开router的方式，pushName, pushReplacementNamed...
//可配置打开router的参数
AppRouteCenter.share.openPage(context, '/mine_page', ...)
```

页面参数获取

```dart
String? name = getMixinArg(context)?['name'];
int? age = getMixinArg(context)?['age'];
```

## 扩展

- 内置扩展

    如果`AppRouterCenter` extends `UriRouterInterceptContainer`，则上面打开指定页面的方式，可以支持Uri，

    ```dart
    AppRouteCenter.share.urlToPage(context, 'appscheme://mine_page?name=1&age=2')
    
    String? name = getMixinArg(context)?['name'];
    
    //通过uri的方式打开页面，参数都是string类型
    String? age = getMixinArg(context)?['age'];
    ```
- 自定义扩展

    开发者可参考`UriRouterInterceptContainer`自定Container，并使得 `AppRouterCenter` extends `自定义Container`


## 注解处理器支持

[flutter_mixin_router_ann](https://pub.dev/packages/flutter_mixin_router_ann)


