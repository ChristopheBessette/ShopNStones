class Main extends hxd.App{

    public static function main(){
        return new Main();
    }

    var stack : states.StateStack;

    override function init(){
        super.init();
        hxd.Res.initEmbed();
        #if sys hl.UI.closeConsole(); #end

        #if hl
            @:privateAccess hxd.Window.getInstance().vsync = true;
        #end

        Assets.init();

        s2d.filter = new h2d.filter.ColorMatrix();

        stack = new states.StateStack();
        haxe.Timer.delay(()->{
            stack.push(new Welcome(stack, s2d));
        }, 1);
    }

    override function update(_){
        stack.update(hxd.Timer.tmod);
    }

    override function onResize(){

    }
}



