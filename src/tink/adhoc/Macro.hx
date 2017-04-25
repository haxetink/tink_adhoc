package tink.adhoc;

import tink.macro.BuildCache;
import haxe.macro.Expr;
using tink.MacroApi;

class Macro {
  #if macro
  static function build() {
    return BuildCache.getType('tink.Adhoc', function (c:BuildContext) {

      var name = c.name,
          fields = c.type.getFields().sure(),
          superType = switch c.type.reduce().toComplex() {
            case TPath(p): p;
            default: throw 'assert';
          },
          implFields = [];

      var impl = TAnonymous(implFields),
          postConstruct = [];

      var ret = macro class $name<AdhocState> implements $superType {
        @:noCompletion private var __impl__:$impl;
        @:noCompletion private var __state__:AdhocState;
        public inline function new(state, impl) {
          this.__state__ = state;
          this.__impl__ = impl;
          $b{postConstruct};
        }
      };

      ret.pos = c.pos;

      var self:FunctionArg = { name: 'self', type: macro : AdhocState };
      for (f in fields) {
        
        var name = f.name,
            ct = f.type.toComplex();
        
        function init(?type)
          implFields.push({
            name: name,
            pos: f.pos,
            kind: FVar(if (type == null) ct else type)
          });

        switch f.kind {
          case FVar(read, write):

            switch [read, write] {
              case [AccNormal, AccNormal | AccNo | AccNever]:

                init();

                ret.fields.push({
                  name: name,
                  pos: f.pos,
                  access: [APublic],
                  kind: FProp('default', if (write == AccNormal) 'default' else 'null', ct),
                });

                postConstruct.push(macro this.$name = __impl__.$name);
                
                switch f.type.reduce() {
                  case TAbstract(_.get() => { pack: [], name: 'Int' | 'Float' | 'Bool' }, _): //TODO: this check is a bit weak
                  default:
                    postConstruct.push(macro __impl__.$name = null);
                }

              case [AccCall | AccNo | AccNever, AccCall | AccNo | AccNever]:

                ret.fields.push({
                  name: name,
                  pos: f.pos,
                  access: [APublic],
                  kind: FProp(read.accessToName(true), write.accessToName(false), ct),
                });

                var access = [];
                init(TAnonymous(access));

                if (read == AccCall) {
                  access.push({
                    name: 'get',
                    pos: f.pos,
                    kind: FFun({ expr: null, args: [self], ret: ct }),
                  });
                  ret.fields.push(Member.getter(name, f.pos, macro this.__impl__.$name.get(this.__state__), ct));
                }

                if (write == AccCall) {
                  access.push({
                    name: 'set',
                    pos: f.pos,
                    kind: FFun({ 
                      expr: null, 
                      args: [self, { name: 'param', type: ct, opt: false }], 
                      ret: ct 
                    }),
                  });
                  ret.fields.push(Member.setter(name, f.pos, macro param = this.__impl__.$name.set(this.__state__, param), ct));
                }
              default:
                f.pos.error('unsupported accessor combination');
            }
          case FMethod(kind):
            init(
              switch ct {
                case TFunction(args, ret):
                  TFunction([self.type].concat(args), ret);
                default: throw 'assert';
              }
            );
            ret.fields.push({
              name: name,
              pos: f.pos,
              access: [APublic, AInline],
              kind: {
                
                var callArgs = [macro this.__state__];
                
                var ret:Function = {
                  args: [],
                  expr: macro return this.__impl__.$name($a{callArgs}),
                  ret: null,
                };

                switch f.type.reduce() {
                  case TFun(args, r):
                    for (a in args) {
                      callArgs.push(macro $i{a.name});
                      ret.args.push({
                        opt: a.opt,
                        type: null,
                        name: a.name,
                      });
                    }
                    ret.ret = r.toComplex();
                  default: throw 'assert';
                }

                FFun(ret);
              }
            });
        }
      }

      return ret;
    });
  }
  #end
}