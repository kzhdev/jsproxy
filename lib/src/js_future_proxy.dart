library jsproxy.future_proxy;

import 'dart:async';
import 'js_object_proxy.dart';

JsObject futureProxy(Future future, [Function customConversionFunc]) {

  var future_proxy = JsProxy(future);

  future_proxy['then'] = (JsFunction jsThenFunc, [JsFunction jsErrorFunc = null]) {
    future.then((data) {
      jsThenFunc.apply([createJsProxy(data, customConversionFunc)]);
    }).catchError((e) {
      if (jsErrorFunc != null) {
        jsErrorFunc.apply([createJsProxy(e, customConversionFunc)]);
      }
    });
  };

  future_proxy['isFuture'] = true;
  return future_proxy;
}
