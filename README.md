# Tink Adhoc Implementations 

[![Build Status](https://travis-ci.org/haxetink/tink_adhoc.svg?branch=master)](https://travis-ci.org/haxetink/tink_adhoc)

This library provides a way to make adhoc implementations, very similar to Java's anonymous classes.

```haxe
interface Enemy {
  
  var id(default, null):Int;
  var name(default, null):String;
  var level(get, never):Int;
  var hp(get, never):Int;

  function hit(dmg:Int):Void;
}

var level = 1;
var ogre = new tink.Adhoc<Enemy>({ hp: 100 }, {
  id: Std.random(1000000000),
  name: 'Ogre',
  level: {
    get: function (_) return level
  },
  hp: {
    get: function (state) return state.hp,
  }
  hit: function (state, dmg) state.hp -= dmg
});
```

The type parameter is the interface being implemented. As for constructor arguments, the first one is the adhoc instance's internal state, which gets passed to all methods and accessors as the first argument (you may call it as you wish). Notice that all implementations live in the very scope they were created in, so you can capture variables, access the outer `this` and so forth.

Adhoc subclassing is planned for a later time.
