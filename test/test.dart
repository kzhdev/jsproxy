library dartproxy.test;

import 'dart:async';
import 'package:jsproxy/src/js_object_proxy.dart';
import 'package:test/test.dart';

class TestDartObject {
  String name = "Test";
  int id = 1;
  bool isReal = false;

  String foo() {
    return 'foo';
  }

  bool bar() {
    return true;
  }

  int _count = 0;
  int get count => ++_count;
  void set count(int value) { _count = value; }

  Future foobar() {
    Completer completer = new Completer();
    new Future.delayed(new Duration(seconds: 5), () {
      completer.complete("This is a future callback");
    });
    return completer.future;
  }

  static JsObject exposeToJs(TestDartObject obj) {
    var rt = JsProxy(obj);
    rt['name'] = obj.name;
    rt['id'] = obj.id;
    rt['isReal'] = obj.isReal;
    rt['foo'] = obj.foo;
    rt['bar'] = obj.bar;
    addSetterAndGetter(rt, 'count', (int value) { obj.count = value; }, () => obj.count);
    rt['foobar'] = () => createJsProxy(obj.foobar());
    return rt;
  }
}

List testList = ['abc', 1, false, new TestDartObject()];

Map<String, dynamic> testMap = {
  'one': 1,
  'two': 'two',
  'boolean': true,
  'obj': new TestDartObject()
};

void _testObject(obj) {
  expect(obj['name'], equals('Test'));
  expect(obj['id'], equals(1));
  expect(obj['isReal'], equals(false));

  obj['isReal'] = true;
  expect(obj['isReal'], equals(true));

  expect(obj.callMethod('foo', []), equals('foo'));
  expect(obj.callMethod('bar', []), equals(true));

  expect(obj['count'], equals(1));

  obj['count'] = 100;
  expect(obj['count'], equals(101));

  var jsFuture = obj.callMethod('foobar', []);
  expect(jsFuture['__isJsProxy'], equals(true));
  expect(jsFuture['__dartObj'] is Future, equals(true));

  jsFuture.callMethod('then', [(result) => expect(result, equals("This is a future callback"))]);
}

void main() {
  test("convert list", () {
    var js_obj = createJsProxy(testList, TestDartObject.exposeToJs);

    expect(js_obj['length'], equals(4));

    JsArray arr = js_obj;
    expect(arr.elementAt(0), equals('abc'));
    expect(arr.elementAt(1), equals(1));
    expect(arr.elementAt(2), equals(false));

    var obj = arr.elementAt(3);
    _testObject(obj);
  });

  test("convert map", () {
    var js_obj = createJsProxy(testMap, TestDartObject.exposeToJs);

    expect(js_obj['one'], isNotNull);
    expect(js_obj['one'], equals(1));

    expect(js_obj['two'], isNotNull);
    expect(js_obj['two'], equals('two'));

    expect(js_obj['boolean'], isNotNull);
    expect(js_obj['boolean'], equals(true));

    var obj = js_obj['obj'];
    _testObject(obj);
  });
}
