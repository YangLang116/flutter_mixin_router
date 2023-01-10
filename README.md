<!-- 
使用Dart mixin机制实现PageRoute模块化
-->

## 1、项目背景

几乎所有的Flutter应用都是采用路由表的方式对路由进行管理，即在应用初始化时，提前把**路由名称**和对应的页面注册到路由表中，应用内部通过**路由名称**跳转到相应的页面。以如下Demo项目为例：

### 1.1、项目目录结构

![image.png](https://p1-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/cc95703c255c4560b22549f5a9766754~tplv-k3u1fbpfcp-watermark.image?)

整个项目包含三个页面(大厅页面、设置页面A、设置页面B) 以及 一个入口文件(main.dart)

### 1.2、项目代码说明

A、B 设置页面（屏幕正中间展示当前页面名称）

```
class APage extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('APage'),
    );
  }
}


class BPage extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('BPage'),
    );
  }
}
```

大厅页面（屏幕正中间展示页面名称，点击名称跳转到页面A）

```
class HomePage extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/setting_a'),  //路由跳转
        child: Text('HomePage'),
      ),
    );
  }
}
```

入口文件（注册应用路由表）

```
class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      ...
      initialRoute: '/home',
      routes: {
        '/home': (context) => HomePage(),    //路由注册
        '/setting_a': (context) => APage(),
        '/setting_b': (context) => BPage(),
      },
    );
  }
}
```

## 2、项目问题

随着项目的不断开发迭代，会有越来越多的页面被添加到应用中。由于新增加的页面都需要提前注册到路由表中，此时入口文件(main.dart）会变得越来越臃肿：

```
routes: {
        '/home': (context) => HomePage(),
        '/setting_a': (context) => APage(),
        '/setting_b': (context) => BPage(),
        ...
        ...
},
```

不容小觑的还有另外一个问题，项目正在变得越来越**扁平化！！！** ，毕竟项目路由并没有分结构进行管理：

![image.png](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/ff7f37326cc44a06aa0ef85cac346a84~tplv-k3u1fbpfcp-watermark.image?)

## 3、解决方案

### 3.1、路由注册方案改造

![image.png](https://p1-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/d2e334ef56d44f72851d0a10889545f1~tplv-k3u1fbpfcp-watermark.image?)

在项目的入口文件中，只需要添加对应的业务模块，而页面的注册过程就交给对应的模块完成，保证项目结构化的同时，也极大避免了入口文件臃肿问题。

### 3.2、模块管理基类创建

```
class MixinRouterContainer {
  ///init router
  Map<String, WidgetBuilder> installRouters() => {};

  ///open page
  Future<T?>? openPage<T>(BuildContext context, String pageName, ... Map<dynamic, dynamic>? arguments,...}) {
    Map<String, dynamic> args = {'args': arguments};
    switch (pushType) {
      case RoutePushType.pushNamed:
        return Navigator.pushNamed(context, pageName, arguments: args);
      ...
    }
  }
}
```

整个基类的核心包括**两个**方法：
-   **installRouters**:  配置属于该模块的路由表
-   **openPage**: 打开相应的路由页面

### 3.3、模块页面注册：

```
mixin HomeRouteContainer on MixinRouterContainer {
  @override
  Map<String, WidgetBuilder> installRouters() {
    Map<String, WidgetBuilder> originRoutes = super.installRouters();
    Map<String, WidgetBuilder> newRoutes = {};
    newRoutes['/home'] = (context) => HomePage(); //注册大厅页面
    newRoutes.addAll(originRoutes);
    return newRoutes;
  }
}

mixin SettingRouteContainer on MixinRouterContainer {
  @override
  Map<String, WidgetBuilder> installRouters() {
    Map<String, WidgetBuilder> originRoutes = super.installRouters();
    Map<String, WidgetBuilder> newRoutes = {};
    newRoutes['/setting_a'] = (context) => APage();  //注册A页面  
    newRoutes['/setting_b'] = (context) => BPage();  //注册B页面
    newRoutes.addAll(originRoutes);
    return newRoutes;
  }
}
```

可以看到HomeRouteContainer 把 HomePage添加到自己的路由表中，同样SettingRouteContainer管理了SettingA、SettingB两个页面。

### 3.4、App模块注册：

```
class AppRouteContainer extends MixinRouterContainer
    with HomeRouteContainer, SettingRouteContainer {  //通过mixin机制粘合项目各个路由模块
  AppRouteContainer._();

  static AppRouteContainer _instance = AppRouteContainer._();

  static AppRouteContainer get share => _instance;
}


class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      ...
      initialRoute: '/home',
      routes: AppRouteContainer.share.installRouters(),  //注册总路由表
    );
  }
}
```

要注意的是，需要创建一个新的类，来粘合项目所有的路由模块，如上面的AppRouteContainer所示，声明成一个单例，方便在项目中使用：

-   注册项目路由表：AppRouteContainer.share.installRouters()
-   页面跳转：AppRouteContainer.share.openPage(context, '/setting_a')


## 4、方案延伸

### 情况一：

说明： 在项目开发过程中，除了简单的页面跳转外，还存在路由拦截。比如：用户在没登录的情况下，想打开个人主页，那么就需要拦截这一过程，并跳转到登录页面。

解决方案：只需在原有的路由管理模块的基类( MixinRouterContainer )上，做进一步的封装。通过添加拦截路由表，并重写路由跳转过程：

```
typedef MixinRouteInterceptor = bool Function(BuildContext context, String pageName, ...);

class MixinRouterInterceptContainer extends MixinRouterContainer {
  
  final Map<String, MixinRouteInterceptor> _routeInterceptorTable = {};

  void registerRouteInterceptor(String pageName, MixinRouteInterceptor interceptor) {
    _routeInterceptorTable[pageName] = interceptor;
  }

  void unRegisterRouteInterceptor(String pageName) {
    _routeInterceptorTable.remove(pageName);
  }

  @override
  Future<T?>? openPage<T>(BuildContext context, String pageName,...) {
    if (!_routeInterceptorTable.containsKey(pageName)) {
      return super.openPage(context,pageName,...);
    }
    MixinRouteInterceptor interceptor = _routeInterceptorTable[pageName]!;
    bool needIntercept = interceptor.call(context,pageName,...);
    if (needIntercept) {
      return Future.value(null);
    } else {
      return super.openPage(context,pageName,...);
    }
  }
}
```

例如：在打开大厅页面之前，判断用户是否登录，如未登录则跳转到登录页面。

```
mixin HomeRouteContainer on MixinRouterInterceptContainer {
  @override
  Map<String, WidgetBuilder> installRouters() {
    registerRouteInterceptor('/home', (...) => if(!isLogin) openLoginPage());  //注册拦截路由表
    Map<String, WidgetBuilder> originRoutes = super.installRouters();
    Map<String, WidgetBuilder> newRoutes = {};
    newRoutes['/home'] = (context) => HomePage();
    newRoutes.addAll(originRoutes);
    return newRoutes;
  }
}
```

### 情况二：

说明：为了通过外链能打开对应的页面，很多项目都是Url统跳。

解决方案：只需要对原有的 AppRouteContainer 进行扩展，代理默认的页面打开方法，实现url解析：

```
class AppRouteContainer extends MixinRouterContainer
    with HomeRouteContainer, SettingRouteContainer {  //通过mixin机制粘合项目各个路由模块
    
   Future<T?>? urlToPage<T>(BuildContext context, String urlStr, ...) {
  	Uri? url = Uri.tryParse(urlStr);
  	if (url == null) return Future.error('parse url fail');
  	Map<String, String> args = {};
    args.addAll(url.queryParameters);
    args['_url'] = urlStr;
    String pageName = url.host;
    super.openPage(context,'/' + pageName ...);
  }
}
```

在进行url统跳时，调用urlToPage即可打开相应的flutter页面。

## 5、深入探索

对项目的路由改造到此就结束了么？回过头来再想想，发现还是存在一些问题：

-   需要手动创建并维护不同的路由管理模块(HomeRouteContainer、SettingRouteContainer）
-   新的页面都需要在对应的模块类中进行手动注册

客户端原生项目对于这类问题，可以通过注解的方式解决，类似阿里的ARouter，那么Flutter也可以借鉴此方式完成进一步的优化，利用注解去生成对应的路由模块管理文件，避免手动维护，具体如下：

### 5.1、注解子路由表

```
const String HOME_ROUTE_TABLE = 'HomeRouteTable';
const String SETTING_ROUTE_TABLE = 'SettingsRouteTable';

//tDescription: 仅仅作为生成类的注释
@RouterTableList(
  tableList: [
    RouterTable(tName: HOME_ROUTE_TABLE, tDescription: '大厅路由模块'),
    RouterTable(tName: SETTING_ROUTE_TABLE, tDescription: '设置路由模块'),
  ],
)


//with HomeRouterTable, MineRouterTable，即上面声明的两个路由表的名字
class AppRouteContainer extends MixinRouterInterceptContainer
    with HomeRouteTable, SettingsRouteTable {
  AppRouteContainer._();

  static AppRouteContainer _instance = AppRouteContainer._();

  static AppRouteContainer get share => _instance;
}
```

### 5.2、注解普通路由

```
@MixinRoute(tName: SETTING_ROUTE_TABLE, path: '/setting_a')
class APage extends StatelessWidget {
  const APage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('APage'),
    );
  }
}
```

### 5.3、注解拦截路由

```
@MixinRoute(tName: SETTING_ROUTE_TABLE, path: '/setting_b')
class BPage extends StatelessWidget {
  const BPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('BPage'),
    );
  }
}

@MixinInterceptRoute(tName: SETTING_ROUTE_TABLE, path: '/setting_b')
bool interceptorMinePage(context, pageName, pushType, {arguments, predicate}) { //函数签名固定写法
  print('toLogin');
  return true;
}
```

## 6、集成使用

在项目的pubspec.yaml中添加依赖，即可开启注解路由之旅

```
dependencies:
  flutter:
    sdk: flutter
  flutter_mixin_router: ^1.0.0      # 添加路由模块管理基类
  flutter_mixin_router_ann: 1.0.0   # 添加注解类

dev_dependencies:
  build_runner: 2.1.8               # 添加依赖
  flutter_mixin_router_gen: 1.0.1   # 添加代码生成工具库
```

在项目页面上添加对应的注解后，执行以下命令生成对应的路由代码
```
# 清除增量编译缓存
flutter packages pub run build_runner clean

# 重新生成代码
flutter packages pub run build_runner build --delete-conflicting-outputs
```