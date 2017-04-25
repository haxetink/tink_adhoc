package ;

import haxe.unit.*;

class RunTests extends TestCase {
  function test() {
    var bar = 5;
    var a = new tink.Adhoc<Foo>({ test: 'yo' }, {
      plain: 3,
      bar: {
        get: function (_) return bar,
        set: function (_, param) return bar = param,
      },
      foo: function (self, b:Bool, i:Int) return '${self.test}:$b:$i',
    });

    assertEquals(bar, a.bar);
    assertEquals('yo:true:null', a.foo(true));
    assertEquals('yo:true:4', a.foo(true, 4));
    
    for (i in 0...10) {
      var rnd = Std.random(100) + 100;
      assertEquals(rnd, a.bar = rnd);
      assertEquals(bar, a.bar);
      assertEquals(rnd, bar);
    }

  }
  static function main() {
    var runner = new TestRunner();
    
    runner.add(new RunTests());

    travix.Logger.exit(
      if (runner.run()) 0
      else 500
    ); 
  }
  
}

interface Foo {
  var bar(get, set):Int;
  var plain(default, null):Float;
  function foo(b:Bool, ?i:Int):String;
}