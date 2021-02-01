import states.IState;

class Welcome implements states.IState{

    var stack : states.StateStack;
    var root : h2d.Object;
    var scene : h2d.Scene;

    var bg_pieces : Array<h2d.Bitmap> = [];

    var width : Int;
    var height : Int;

    var edition : h2d.Text;

    var resourceFactory : resources.ResourceFactory;

    public function new(stack:states.StateStack, parent:h2d.Scene){
        this.stack = stack;
        this.root = new h2d.Object(parent);

        this.width = parent.width;
        this.height = parent.height;

        this.scene = parent;

        resourceFactory = new resources.ResourceFactory();
        resourceFactory.clear();
        resourceFactory.add(resources.ResourceId.Diamond, 1);
        resourceFactory.add(resources.ResourceId.Emerald, 1);
        resourceFactory.add(resources.ResourceId.Amethyst, 1);
        resourceFactory.add(resources.ResourceId.Topaz, 1);
        resourceFactory.add(resources.ResourceId.RainbowOpal, 1);
        resourceFactory.add(resources.ResourceId.Garnet, 1);
        resourceFactory.add(resources.ResourceId.Ruby, 1);
        resourceFactory.add(resources.ResourceId.RoseQuartz, 1);
        resourceFactory.add(resources.ResourceId.StrangeDoll, 0.05);
        resourceFactory.add(resources.ResourceId.Bomb, 0.1);
        resourceFactory.add(resources.ResourceId.Coin, 1);
        resourceFactory.add(resources.ResourceId.Shop, 0.4);
        resourceFactory.add(resources.ResourceId.Star, 0.1);

        for (y in 0 ... Math.floor(height / (16 * 4))+1){
            for (x in 0 ... Math.floor(width / (16 * 4))){
                var b = new h2d.Bitmap(Assets.getResource(resourceFactory.get()), root);
                b.x = x * 16 * 4 + 8 * 4;
                b.y = (y-1) * 16 * 4 + 8 * 4;
                b.scale(4);
                bg_pieces.push(b);
            }
        }

        var overlay = new h2d.Bitmap(h2d.Tile.fromColor(0, width, height, 0.7), root);

        var title = new h2d.Text(Assets.font_title, root);
        title.text = "Shop 'n Stones";
        title.textAlign = Center;
        title.x = parent.width * 0.5;
        title.y = 50;
        title.scale(2);
        title.filter = new h2d.filter.Outline();

        edition = new h2d.Text(Assets.font_title, root);
        edition.text = "- press space -";
        edition.textAlign = Center;
        edition.x = parent.width * 0.5;
        edition.y = 550;
        edition.textColor = 0xe64539;
        edition.filter = new h2d.filter.Outline(3);

        //var trigger = new DragTrigger(null, null, root);
    }

    var music : hxd.snd.Channel;
    public function enter(){
        music = Assets.music_title.play(true);
    }

    public function exit(){
        music.fadeTo(0, 1, music.stop);
    }

    public function dispose(){
        this.root.remove();
    }

    var time : Float;

    public function update(tmod:Float){

        if (hxd.Key.isPressed(hxd.Key.SPACE)){
            stack.pop();
            stack.push(new Game(stack, scene));
            // stack.push(new CubeTransition(stack, scene, ()->{
            //     stack.pop(); // remove transition
            //     stack.pop(); // remove previous scene (this)
            //     // stack.push(); // add new scene
            // }));
        }
    }

    public function postUpdate(tmod:Float){
        time += 0.1 * tmod;

        #if hl
            edition.scaleX = 1 + Math.sin(time) * 0.1;
            edition.scaleY = 1 + Math.cos(time) * 0.1;
        #end

        for (bmp in bg_pieces){
            bmp.y += tmod * 0.2;
            if (bmp.y-8*4 > height){
                bmp.y = -8*4;
                bmp.tile = Assets.getResource(resourceFactory.get());
            }
        }
    }
}