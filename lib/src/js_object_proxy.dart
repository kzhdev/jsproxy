library jsproxy.object_proxy;

import 'dart:html';
import 'dart:async';
import 'dart:indexed_db';
import 'dart:typed_data';

import 'dart:js';
export 'dart:js';

import 'js_future_proxy.dart';

final JsObject jsObject = context['Object'];

JsObject JsProxy(Object obj) {
  var jsproxy =  new JsObject(context['Object'], []);
  jsproxy['__isJsProxy'] = true;
  jsproxy['__dartObj'] = obj;
  return jsproxy;
}

void defineProperties(JsObject proxy, Map properties) {
  jsObject.callMethod('defineProperties', [proxy, new JsObject.jsify(properties)]);
}

void addGetter(JsObject proxy, String name, getter) {
  defineProperties(proxy, {name: {'get': () => getter is Function ? getter() : getter}});
}

void addSetter(JsObject proxy, String name, setter) {
  defineProperties(proxy, {name: {'set': (arg) => setter is Function ? setter(arg) : setter = arg}});
}

void addSetterAndGetter(JsObject proxy, String name, setter, getter) {
  defineProperties(proxy, {name: {
    'set' : (arg) => setter is Function ? setter(arg) : setter = arg,
    'get' : () => getter is Function ? getter() : getter
  }});
}

createJsProxy(Object obj, [Function customConversionFunc]) {

  if (_isPrimaryType(obj)) {
    return obj;
  } else if (obj is Future) {
    return futureProxy(obj, customConversionFunc);
  } else if (obj is Map) {
    var js_obj = new JsObject(jsObject, []);

    obj.forEach((k, v) {
      js_obj[k] = createJsProxy(v, customConversionFunc);
    });

    return js_obj;
  } else if (obj is Iterable) {
    return new JsObject.jsify(obj.map((o) =>
    createJsProxy(o, customConversionFunc)).toList());
  } else if (customConversionFunc != null){
    return customConversionFunc(obj);
  }
  return JsProxy(obj);
}

bool _isPrimaryType(Object obj) {
  return obj == null
    || obj is String
    || obj is bool
    || obj is num
    || obj is DateTime
    || obj is Blob
    || obj is Event
    || obj is HtmlCollection
    || obj is ImageData
    || obj is KeyRange
    || obj is Node
    || obj is NodeList
    || (obj is TypedData && obj is! ByteBuffer)
    || obj is Window;
}

