import 'package:flutter/widgets.dart';

///@author: YangLang
///@version: v1.0
///@email: yanglang116@gmail.com

enum RoutePushType {
  ///see [Navigator.pushNamed(context, routeName)]
  pushNamed,

  ///see [Navigator.pushReplacementNamed(context, routeName)]
  pushReplacementNamed,

  ///see [Navigator.popAndPushNamed(context, routeName)]
  popAndPushNamed,

  ///see [Navigator.pushAndRemoveUntil(context, newRoute, (route) => false)]
  pushAndRemoveUntil,
}

//combine all router in application
class MixinRouterContainer {
  ///init router
  Map<String, WidgetBuilder> installRouters() => {};

  ///open page
  Future<T?>? openPage<T>(BuildContext context, String pageName,
      {RoutePushType pushType = RoutePushType.pushNamed,
      Map<dynamic, dynamic>? arguments,
      RoutePredicate? predicate}) {
    Map<String, dynamic> args = {'args': arguments};
    switch (pushType) {
      case RoutePushType.pushNamed:
        return Navigator.pushNamed(context, pageName, arguments: args);
      case RoutePushType.pushReplacementNamed:
        return Navigator.pushReplacementNamed(context, pageName,
            arguments: args);
      case RoutePushType.popAndPushNamed:
        return Navigator.popAndPushNamed(context, pageName, arguments: args);
      case RoutePushType.pushAndRemoveUntil:
        assert(predicate != null);
        return Navigator.pushNamedAndRemoveUntil(
          context,
          pageName,
          predicate!,
          arguments: args,
        );
    }
  }
}
