import 'package:flutter/widgets.dart';
import 'package:flutter_mixin_router/route/base/mixin_router_container.dart';

///@author: YangLang
///@version: v1.0
///@email: yanglang116@gmail.com

typedef MixinRouteInterceptor = bool Function(
    BuildContext context, String pageName, RoutePushType pushType,
    {Map<dynamic, dynamic>? arguments, RoutePredicate? predicate});

///base [RouterContainer]，to intercept route operation
class MixinRouterInterceptContainer extends MixinRouterContainer {
  final Map<String, MixinRouteInterceptor> _routeInterceptorTable = {};

  void registerRouteInterceptor(
      String pageName, MixinRouteInterceptor interceptor) {
    if (_routeInterceptorTable.containsKey(pageName)) return;
    _routeInterceptorTable[pageName] = interceptor;
  }

  void unRegisterRouteInterceptor(String pageName) {
    if (!_routeInterceptorTable.containsKey(pageName)) return;
    _routeInterceptorTable.remove(pageName);
  }

  @override
  Future<T?>? openPage<T>(BuildContext context, String pageName,
      {RoutePushType pushType = RoutePushType.pushNamed,
      Map<dynamic, dynamic>? arguments,
      RoutePredicate? predicate}) {
    if (!_routeInterceptorTable.containsKey(pageName)) {
      return super.openPage(
        context,
        pageName,
        pushType: pushType,
        arguments: arguments,
        predicate: predicate,
      );
    }
    MixinRouteInterceptor interceptor = _routeInterceptorTable[pageName]!;
    bool needIntercept = interceptor.call(
      context,
      pageName,
      pushType,
      arguments: arguments,
      predicate: predicate,
    );
    if (needIntercept) {
      return Future.value(null);
    } else {
      return super.openPage(
        context,
        pageName,
        pushType: pushType,
        arguments: arguments,
        predicate: predicate,
      );
    }
  }
}
