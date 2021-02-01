package resources;

class Resource{

    public var id (default, null) : ResourceId;

    public var sprite (default, null) : h2d.Bitmap;

    public var cx (default, null): Int = 0;
    public var cy (default, null): Int = 0;

    public var rx (default, null): Float = 0;
    public var ry (default, null): Float = 0;

    public var x (get, never) : Float; inline function get_x() return cx + rx;
    public var y (get, never) : Float; inline function get_y() return cy + ry;

    var game : Game;
    var board : Board;

    var moving = false;
    var move_ftime = 5;
    var move_timer = 0.;
    var move_cb : Void->Void;
    var dx : Int;
    var dy : Int;

    var scaleX : Float = 0;
    var scaleY : Float = 0;
    var keepScale : Bool = false;

    var selected : Bool = false;
    var selectedAnimTimer = 0.0;

    var tags : Array<String> = [];

    var cd : Cooldown;

    var score_mod : Int = 0;

    public static var specials = [
        ResourceId.StrangeDoll,
        ResourceId.Bomb,
        ResourceId.Coin,
        ResourceId.Star,
        ResourceId.Shop
    ];

    public var destroyed (default, null) : Bool = false;

    public function new(game:Game, id : ResourceId){
        this.id = id;
        sprite = new h2d.Bitmap();

        this.game = game;
        this.board = game.board;

        sprite.tile = Assets.getResource(id);
        cd = new Cooldown(Const.FPS);
    }

    public function hasCombineOptions(){
        if (specials.indexOf(id) != -1){
            return (
                board.tileResourceIsGem(cx, cy-1) ||
                board.tileResourceIsGem(cx, cy+1) ||
                board.tileResourceIsGem(cx-1, cy) ||
                board.tileResourceIsGem(cx+1, cy)
            );
        };
        return (
            board.tileResourceIs(cx,cy-1, id) ||
            board.tileResourceIs(cx,cy+1, id) ||
            board.tileResourceIs(cx-1,cy, id) ||
            board.tileResourceIs(cx+1,cy, id)
        );
    }

    public function playDelayedIntro(){
        scaleX = -1;
        scaleY = -1;
        keepScale = true;
        haxe.Timer.delay(playIntro, Math.floor(Math.random()*500));
    }

    public function combine(resource:Resource, cb:Void->Void){
        var dx = resource.cx - cx;
        var dy = resource.cy - cy;

        if (canCombine(resource.id))
            Assets.snd_bwop.play();
        else
            Assets.snd_bwop2.play();

        move(dx, dy, ()->{
            if(canCombine(resource.id)){
                onCombined(resource);
                if(specials.indexOf(resource.id) < 0)
                    resource.mergeDestroy();
                else
                    resource.destroy();
                // mergeDestroy();
                if (cb != null) cb();
            }else{
                move(dx*-1, dy*-1, null);
                resource.move(0, 0, null);
            }
            if (game.selected == this){
                this.unselect();
                game.selected = null;
            }
        });
    }

    public function setPosition(x:Int, y:Int){
        setBoardPosition(x, y);
        this.cx = x;
        this.cy = y;
    }

    function setBoardPosition(x:Int, y:Int){
        if (board.getTile(cx, cy).resource == this)
            board.getTile(cx, cy).resource = null;
        board.getTile(x, y).resource = this;
    }

    inline function rand(min:Int, max:Int){
        return Math.floor(Math.random()*(max-min+1))+min;
    }

    function onCombined(resource:Resource){
        // the coin adds to the actual score the amount of
        // the combined item
        if (resource.id == Coin){
            Assets.snd_coin.play();
            effectCoin(resource);

        // the shop turns whatever it combines with into
        // a new random special item
        }else if (resource.id == Shop){
            effectShop(resource);
        }

        // the star destroys every item of the combined
        // type,giving their base score
        else if (resource.id == Star){
            Assets.snd_star.play();
            effectStar(resource);
        }

        // the strange doll can pick a random effect from another special item,
        // or transform all item of the kind of the combined one
        else if (resource.id == ResourceId.StrangeDoll){
            Assets.snd_mystical2.play(false, 0.4);
            effectStrangeDoll(resource);
        }
        // bomb explodes all surrounding items and add their actual value
        else if (resource.id == Bomb){
            Assets.snd_bomb.play();
            effectBomb(resource);
        }else{
            //score_mod += resource.getScore();
        }
    }

    function effectCoin(resource:Resource){
        game.addTextEffect('+${getScore()+score_mod}', 0x63ab3f, cx, cy);
        game.addScore(getScore()+score_mod);
    }

    function effectShop(resource:Resource){
        var special : ResourceId = Shop;
        while (special == Shop){
            special = specials[rand(0, specials.length-1)];
        }
        game.resources.removeResource(this);
        game.resources.createResource(special, game)
            .setPosition(cx, cy);
    }

    function effectBomb(resource:Resource){
        for (i in resource.cy-1 ... resource.cy+2)
        for (j in resource.cx-1 ... resource.cx+2){
            if (board.isValid(j, i)){
                var tile = board.getTile(j, i);
                if (tile.resource != null){
                    tile.resource.mergeDestroy();
                }
                    
            }
        }
    }

    function effectStar(resource:Resource){
        game.destroyAllOfKind(this.id, true);
    }

    function effectStrangeDoll(resource:Resource){
        var effects = [
            effectCoin,
            effectBomb,
            effectShop,
            effectStar,
            effectCustomStrangeDoll
        ];
        effects[rand(0, effects.length-1)](resource);
    }

    function effectCustomStrangeDoll(resource:Resource){
        var all = game.getAllResourcesOfId(id);
        for (res in all){
            res.destroy();
            game.resources.createRandomResource(game).setPosition(res.cx, res.cy);
        }
    }

    public function playIntro(){
        scaleX = -1;
        scaleY = -1;
        keepScale = true;
        cd.addFrames("intro_1", 15, (cd)->{
            scaleX = -1 + cd.getRange() * 1.5;
            scaleY = -1 + cd.getRange() * 1.5;
        }, ()-> {keepScale = false;});
    }

    public function canCombine(id:ResourceId){
        return (
            specials.indexOf(this.id) == -1 &&
            (this.id == id ||
            specials.indexOf(id) >= 0)
        );
    }

    public function move(dx:Int, dy:Int, cb:Void->Void){
        if (moving) return false;
        if (!board.isValid(cx+dx, cy+dy)) return false;
        moving = true;
        this.dx = cx+dx;
        this.dy = cy+dy;
        this.move_cb = cb;
        board.getTile(cx, cy).resource = null;
        board.getTile(cx+dx, cy+dy).resource = this;
        return true;
    }

    public function select(){
        selected = true;
        keepScale = true;
    }

    public function unselect(){
        selected = false;
        keepScale = false;
        selectedAnimTimer = 0;
    }

    function getScore(){
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

    public function mergeDestroy(){
        game.addTextEffect('+${getScore()+score_mod}', 0x63ab3f, cx, cy);
        game.addScore(getScore()+score_mod);
        destroy();
    }

    public function destroy(){
        game.resources.removeResource(this);
        keepScale = true;
        if (board.getTile(cx, cy).resource == this)
            board.getTile(cx, cy).resource = null;
        cd.addFrames("destroyed", 10, (cd)->{
            scaleX = cd.getRange() * 1;
            scaleY = cd.getRange() * 1;
            sprite.alpha = 1 - cd.getRange();
        }, ()->{
            destroyed = true;
        });
    }

    public function update(tmod:Float){
        cd.update(tmod);

        if (selected){
            selectedAnimTimer += tmod * 0.2;
            scaleX = Math.sin(selectedAnimTimer) * 0.2;
            scaleY = Math.cos(selectedAnimTimer) * 0.2;
        }

        if (moving){
            move_timer += 1 * tmod;
            rx = (dx-cx) * move_timer / move_ftime + 0;
            ry = (dy-cy) * move_timer / move_ftime + 0;
            if (move_timer >= move_ftime){
                rx = 0;
                ry = 0;
                cx = dx;
                cy = dy;
                move_timer = 0;
                moving = false;
                if(move_cb != null) move_cb();
            }
        }

        if (!keepScale){
            scaleX *= 0.8;
            scaleY *= 0.8;
        }
    }

    public function postUpdate(){
        sprite.x = x * Const.TILE_SIZE + 8;
        sprite.y = y * Const.TILE_SIZE + 8;
        sprite.scaleX = 1 + scaleX;
        sprite.scaleY = 1 + scaleY;
    }

    public function dispose(){
        sprite.remove();
        cd.cancelAll();
    }
} 