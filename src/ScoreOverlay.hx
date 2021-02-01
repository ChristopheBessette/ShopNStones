class ScoreOverlay implements states.IState{

    var cd : Cooldown;
    var stack : states.StateStack;
    var scene : h2d.Scene;
    var root : h2d.Object;
    var game : Game;

    var flow : h2d.Flow;

    public function new(stack:states.StateStack, scene:h2d.Scene, game:Game){
        this.game = game;
        this.scene = scene;
        this.stack = stack;

        cd = new Cooldown(hxd.Timer.wantedFPS);
        root = new h2d.Object(scene);

        var bg = new h2d.Bitmap(h2d.Tile.fromColor(0x000000, scene.width,720,0.9), root);

        flow = new h2d.Flow(root);
        flow.layout = Vertical;
        flow.verticalSpacing = 6 * Const.SCALE;
        flow.y = 180;
        flow.x = scene.width * 0.5 - 100;

        var title = new h2d.Text(Assets.font_title, root);
        title.text = "You cannot play anything else!";
        title.textColor = 0xf0b541;
        title.textAlign = Center;
        title.x = scene.width * 0.5;
        title.y = 10;
    }

    var music : hxd.snd.Channel;
    public function enter(){
        var d = 15;
        music = Assets.music_highscore.play(true, 0);
        music.fadeTo(0.5, 0.5);
        var minusScore = 0;
        var values = game.resources.getScores();
        var delay = 0;
        for (i in 0...values.length){
            if (values[i].current != 0){
                cd.addFrames('item${i}', delay*30 + d, null, ()->{
                    displayItem(values[i]);
                });
                delay++;
                minusScore += (values[i].current-1) * getScore(values[i].id);
            }
        }
        cd.addFrames('item${delay+1}', (delay+1)*30 + d, null, ()->{
            var extras = new h2d.Text(Assets.font_text, flow);
            extras.textColor = 0xf0b541;
            extras.text = 'score : ${game.getScore()}\nprofit loss : -${minusScore}';
        });
        cd.addFrames('item${delay+2}', (delay+2)*30 + d, null, ()->{
            var f = new h2d.Text(Assets.font_title, flow);
            
            var fs = game.getScore() - minusScore;
            game.last_final_score = fs;
            if (fs >= 0){
                f.textColor = 0x63ab3f;
            }else{
                f.textColor = 0xe64539;
            }
            f.text = 'final score: ${fs}';
        });
        cd.addFrames('item${delay+2}', (delay+2)*30 + d, null, ()->{
            var space = new h2d.Text(Assets.font_text, flow);
            space.text = "press space to continue";
            space.textColor = 0xf0b541;
            canPressSpace = true;
        });
    }

    var canPressSpace = false;

    var items : Array<OverlayResource> = [];

    inline function displayItem(value:{id:resources.ResourceId, current:Int, total:Int}){
        items.push(new OverlayResource(value.id, value.current, value.total, flow));
    }

    public function exit(){
        music.fadeTo(0, 0.5, music.stop);
    }

    public function update(tmod:Float){
        cd.update(tmod);
    }

    public function postUpdate(tmod:Float){
        for (i in items){
            i.update(tmod);
        }

        if (canPressSpace && hxd.Key.isPressed(hxd.Key.SPACE)){
            stack.pop();
        }
    }

    public function dispose(){
        root.remove();
    }

    function getScore(id:resources.ResourceId){
        return switch(id){
            case Diamond: 300;
            case Emerald: 220;
            case Amethyst: 50;
            case Topaz: 100;
            case RainbowOpal: 80;
            case Garnet: 150;
            case Ruby: 270;
            case RoseQuartz: 20;
            case StrangeDoll: 0;
            case Bomb: 0;
            case Coin: 0;
            case Shop: 0;
            case Star: 0;
        }
    }
}


class OverlayResource extends h2d.Object{

    var icon : h2d.Bitmap;
    var count : h2d.Text;

    public var c : Int;

    var iconScale = 2;
    var iconScaleX = 0.;
    var iconScaleY = 0.;

    var fading : Bool = false;

    public var id : resources.ResourceId;

    public function new(id:resources.ResourceId, current:Int, total:Int, parent:h2d.Object){
        super(parent);

        this.id = id;

        icon = new h2d.Bitmap(Assets.getResource(id), this);
        count = new h2d.Text(Assets.font_text, this);
        count.x = 6 * Const.SCALE;
        count.y = -count.textHeight * 0.5;

        var t = total;
        var c = current;
        var c1 = current-1;
        var s = getScore(id);
        var min = Math.max(c1*s, 0);
        min = min == 0 ? 0 : min * -1;
        count.text = '${c} remaining/${t} total = ${c1} * value(${s}) = ${min}';
        bweep();
    }

    function getScore(id:resources.ResourceId){
        return switch(id){
            case Diamond: 300;
            case Emerald: 220;
            case Amethyst: 50;
            case Topaz: 100;
            case RainbowOpal: 80;
            case Garnet: 150;
            case Ruby: 270;
            case RoseQuartz: 20;
            case StrangeDoll: 0;
            case Bomb: 0;
            case Coin: 0;
            case Shop: 0;
            case Star: 0;
        }
    }

    public function fadeAway(){
        fading = true;
    }

    function bweep(){
        iconScaleX = 4;
        iconScaleY = 3.5;
    }

    public function update(tmod:Float){
        iconScaleX *= 0.8;
        iconScaleY *= 0.8;

        if (fading){
            this.alpha -= 0.1;
        }

        icon.scaleX = iconScale + iconScaleX;
        icon.scaleY = iconScale + iconScaleY;
    }
}