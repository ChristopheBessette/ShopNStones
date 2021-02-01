import resources.ResourceManager;
import resources.ResourceManager.Event as ResourceEvent;
import resources.ResourceFactory;
import resources.Resource;
import resources.ResourceId;

/**
    A Descriptor of a json's level data
**/
typedef LevelData = {
    // level's unique identifier
    var id : String;
    // level's display name
    var name : String;
    // board's width
    var width : Int;
    // board's height
    var height : Int;
    // default resources at startup
    var defaults : Array<{id:ResourceId, cx:Int, cy:Int}>;
    // level's hint
    var hint : String;
}

/**
    A descriptor for game data
**/
typedef GameData = {
    var levels : Array<{
        // level's unique identifier
        var id : String;
        // level's display name
        var name : String;
        // board's width
        var width : Int;
        // board's height
        var height : Int;
        // default resources at startup
        var defaults : Array<{id:String, cx:Int, cy:Int}>;
        // level's hint
        var hint : String;
    }>;
}

/**
    Where the fun stuff happens!
**/
class Game implements states.IState{

    // the game's board layout
    public var board (default, null): Board;

    // layer used by scroller
    var LAYER_RESOURCES : Int = 1;

    // our root scene
    var scene : h2d.Scene;

    // root (state scene) object
    var root : h2d.Object;

    // contains the board
    var scroller : h2d.Layers;

    // interactive located onto our scroller
    var interactive : h2d.Interactive;

    // stack containing this state
    var stack : states.StateStack;

    // factory that gives out weighted resources
    var resourceFactory : ResourceFactory;

    // marker to see if we need to regrow the board
    var need_growth : Bool = false;

    // marker to see if we need to collapse the board
    var need_collapse : Bool = false;

    // event that triggers when the level is started
    public var event_started (default, null): Event.EventListener<GameEvent>;
    var dispatcher_started : Event.EventDispatcher<GameEvent>;

    // event that triggers when the level becomes unplayable (is finished)
    public var event_unplayable (default, null) : Event.EventListener<GameEvent>;
    var dispatcher_unplayable : Event.EventDispatcher<GameEvent>;  

    // a default event to avoid creating new ones each time
    var default_event : GameEvent;

    // contains all the level datas
    var levels : Array<LevelData>;

    // current level index
    var level_index : Int = 0;

    // available moves left
    var available_moves : Int = 0;

    // hint text
    var hint_text : h2d.Text;

    // ui effects
    var ui_effects : h2d.Object;
    var points_effects : Array<h2d.Text> = [];

    var score : Int = 0;
    var score_text : h2d.Text;

    var markerGameEnd : Bool = false;
    var lockGameEnd : Bool = false;

    var hud : h2d.Object;

    var sideboard : SideBoard;
    public var resources (default, null): ResourceManager;
    public var league (default, null) : LeagueManager;

    var league_id : h2d.Text;
    var league_current : h2d.Text;
    var league_hint : h2d.Text;
    public var last_final_score : Int = 0;

    /**
        Constructor
    **/
    public function new(stack:states.StateStack, parent:h2d.Scene){
        // initialize all the levels
        var json : GameData = haxe.Json.parse(hxd.Res.data.entry.getText());

        levels = [for (level in json.levels){
            {
                id : level.id,
                name : level.name,
                width : level.width,
                height : level.height,
                defaults : [for (def in level.defaults){
                    {id : ResourceId.createByName(def.id), cx:def.cx, cy:def.cy}
                }],
                hint : level.hint
            }
        }];

        this.scene = parent;

        // initialize game events
        initEvents();
        // we initialize our stack. We need it when changing states
        this.stack = stack;
        // create our root
        root = new h2d.Object(parent);
        // create our scroller
        scroller = new h2d.Layers(root);
        // set the scale of our scroller (we dont want everything to be scaled)
        scroller.scale(Const.SCALE);
        
        // build our scroller's interactive
        interactive = new h2d.Interactive(0, 0, scroller);
        interactive.onMove = onScrollerMove;
        interactive.onOut = onScrollerOut;
        interactive.onPush = onScrollerPush;
        interactive.onRelease = onScrollerRelease;
        interactive.cursor = hxd.Cursor.Default;
        interactive.propagateEvents = false;

        // ui effects
        ui_effects = new h2d.Object(root);

        // hint
        hint_text = new h2d.Text(Assets.font_text, root);
        hint_text.textAlign = Center;
        hint_text.x = scene.width * 0.5;
        hint_text.y = 620;

        score_text = new h2d.Text(Assets.font_title, root);
        score_text.textAlign = Center;
        score_text.x = scene.width * 0.5;
        score_text.y = 10;
        score_text.text = 'Score: ${score}';
        score_text.textColor = 0xf0b541;
        //score_text.scale(2);

        hud = new h2d.Object(root);

        resourceFactory = new ResourceFactory();
        resources = new ResourceManager(resourceFactory);
        sideboard = new SideBoard(this);

        resources.event_removed.subscribe(onResourceRemoved);
        resources.event_added.subscribe(onResourceAdded);

        league = new LeagueManager(this);
        league_id = new h2d.Text(Assets.font_text, root);
        league_id.textColor = Const.COLOR_YELLOW;
        league_id.x = scene.width - 150;
        league_current = new h2d.Text(Assets.font_text, root);
        league_current.x = league_id.x;
        league_current.y = league_id.y + 25;

        league_hint = new h2d.Text(Assets.font_text, root);
        league_hint.textAlign = Center;
        league_hint.x = hint_text.x;
        league_hint.y = hint_text.y + 45;
    }

    function onResourceAdded(event:ResourceEvent){
        scroller.add(event.resource.sprite, LAYER_RESOURCES);
        event.resource.playDelayedIntro();
    }

    function onResourceRemoved(event:ResourceEvent){
        if (board.getTile(event.resource.cx, event.resource.cy).resource == event.resource)
            board.getTile(event.resource.cx, event.resource.cy).resource = null;
        need_collapse = true;
        //need_growth = true;
    }

    public function addScore(score:Int){
        this.score += score;
        score_text.text = 'Score: ${this.score}';
    }

    public function addTextEffect(label:String, color:Int, cx:Int, cy:Int){
        var t = new h2d.Text(Assets.font_text, ui_effects);
        t.filter = new h2d.filter.Glow(0x000000, 1, 1, 1, 1, true);
        t.textAlign = Center;
        t.textColor = color;
        t.scaleX = 1.5;
        t.scaleY = 1.5;
        t.text = label;
        t.x = (cx+0.5) * Const.TILE_SIZE * Const.SCALE;
        t.y = (cy-0.5) * Const.TILE_SIZE * Const.SCALE;
        points_effects.push(t);
    }

    function startLevel(){

        

        if (level_index == levels.length-1){

            if (league.canIncreaseLeague(score)){
                league.increaseLeague();
            }

            league_id.visible = true;
            league_hint.visible = true;
            league_current.visible = true;
            league_id.text = 'League ${league.current_league}';
            if (league.current_league == 1){
                league_current.text = "League Maxed Out!";
            }else{
                league_current.text = 'League ${league.current_league-1} -> score ${league.next_league_score}+';
            }
            league_hint.text = league.league_hint;
            league_hint.textColor = league.league_hint_color;
        }else{
            league_id.visible = false;
            league_hint.visible = false;
            league_current.visible = false;
        }

        sideboard.clear();
        resetResources();

        resetScroller();
        initResources();
        
        var level = levels[level_index];
        board = new Board(level.width, level.height);

        for (resource in level.defaults){
            resources.createResource(resource.id, this)
                .setPosition(resource.cx, resource.cy);
        }

        if (level.defaults.length == 0) need_growth = true;

        positionScroller();
        resetInteractive();

        hint_text.text = level.hint;
        hint_text.y = scroller.y + board.height * Const.TILE_SIZE * Const.SCALE + 20;
        addScore(-score);

        markerGameEnd = true;
    }

    function hasAvailableMoves(){
        for (y in 0 ... board.height){
            for (x in 0 ... board.width){
                var tile = board.getTile(x, y);
                if (tile.resource != null){
                    if (tile.resource.hasCombineOptions()){
                        return true;
                    }
                }
            }
        }
        return false;
    }

    public function addHud(item:h2d.Object){
        hud.addChild(item);
    }

    function getRandomAvailable(){
        var availables = [];
        for (y in 0 ... board.height){
            for (x in 0 ... board.width){
                var tile = board.getTile(x, y);
                if (tile.resource != null){
                    if (tile.resource.hasCombineOptions()){
                        availables.push(tile.resource);
                    }
                }
            }
        }
        return availables[rand(0, availables.length-1)];
    }

    function rand(min:Int, max:Int){
        return Math.floor(Math.random()*(max-min+1))+min;
    }

    function resetResources(){
        resources.clear();
    }

    function resetInteractive(){
        var board_w = board.width * Const.TILE_SIZE;
        var board_h = board.height * Const.TILE_SIZE;
        interactive.width = board_w;
        interactive.height = board_h;
    }

    function positionScroller(){
        var board_w = board.width * Const.TILE_SIZE;
        var board_h = board.height * Const.TILE_SIZE;
        scroller.x = scene.width * 0.5 - board_w * 0.5 * Const.SCALE;
        scroller.y = 720 * 0.5 - board_h * 0.5 * Const.SCALE;
        ui_effects.x = scroller.x;
        ui_effects.y = scroller.y;
    }

    function resetScroller(){
        for (child in scroller.getLayer(LAYER_RESOURCES)){
            child.remove();
        }
    }

    function initResources(){
        resourceFactory.clear();
        resourceFactory.add(    ResourceId.Diamond,     1   );
        resourceFactory.add(    ResourceId.Emerald,     1   );
        resourceFactory.add(    ResourceId.Amethyst,    1   );
        resourceFactory.add(    ResourceId.Topaz,       1   );
        resourceFactory.add(    ResourceId.RainbowOpal, 1   );
        resourceFactory.add(    ResourceId.Garnet,      1   );
        resourceFactory.add(    ResourceId.Ruby,        1   );
        resourceFactory.add(    ResourceId.RoseQuartz,  1   );
        resourceFactory.add(    ResourceId.StrangeDoll, 0.05);
        resourceFactory.add(    ResourceId.Bomb,        0.1);
        resourceFactory.add(    ResourceId.Coin,        1);
        resourceFactory.add(    ResourceId.Shop,        0.4);
        resourceFactory.add(    ResourceId.Star,        0.1);
    }

    public function getScore(){
        return score;
    }

    inline function initEvents(){
        event_started = new Event.EventListener();
        event_unplayable = new Event.EventListener();

        dispatcher_started = event_started;
        dispatcher_unplayable = event_unplayable;

        default_event = new GameEvent();
    }

    function onScrollerMove(e:hxd.Event){
        var x = Math.floor(e.relX / Const.TILE_SIZE);
        var y = Math.floor(e.relY / Const.TILE_SIZE);

        if (selected != null){
            var other = board.getTile(x, y).resource;

            if (other == null){
                selected.unselect();
                return;
            }else{
                selected.select();
            }

            var dx = selected.cx - other.cx;
            var dy = selected.cy - other.cy;
            
            if (dx + dy != 0  && Math.abs(dx + dy) == 1){
                selected.combine(other, ()->{
                    
                });
            }
        }
    }

    var timer : haxe.Timer;

    function checkForGameEnd(){
        // trace("checking for game ending");
        if (hasAvailableMoves() && getRandomAvailable() == null)
            throw "inconsistance";
        if (!hasAvailableMoves()){
            // if (timer != null) return;
            // timer = haxe.Timer.delay(()->{
                timer = null;
                if (level_index >= levels.length-2){ 
                    level_index = Std.int(Math.min(level_index+1, levels.length-1));
                    stack.push(new ScoreOverlay(stack, scene, this));
                }else{
                    level_index = Std.int(Math.min(level_index+1, levels.length-1));
                    startLevel();
                }
                
            // }, 1000);
            // startLevel();
        }else{
            // trace("did not end game");
        }
        //markerGameEnd = false;
        //lockGameEnd = false;
    }

    public var selected : Resource;

    function onScrollerPush(e:hxd.Event){
        var x = Math.floor(e.relX / Const.TILE_SIZE);
        var y = Math.floor(e.relY / Const.TILE_SIZE);
        if (selected == null){
            time_without_moves = 0;
            selected = board.getTile(x, y).resource;
            if (selected == null) return;
            scroller.add(selected.sprite, LAYER_RESOURCES);
            selected.select();
        }
    }

    function onScrollerRelease(e:hxd.Event){
        if (selected != null){
            selected.unselect();
            selected = null;
        }
    }

    function onScrollerOut(e:hxd.Event){
        
    }

    function drawBoard(){
        for (y in 0 ... board.height){
            for (x in 0 ... board.width){
                resources.createRandomResource(this).setPosition(x, y);
            }
        }
    }

    public function getAllResourcesOfId(id:ResourceId){
        return resources.filterById(id);
    }


    public function destroyAllOfKind(id:ResourceId, addScore = false){
        board.map((tile:Board.BoardTile)->{
            if (tile.resource != null && tile.resource.id == id){
                if (addScore)
                    tile.resource.mergeDestroy();
                else
                    tile.resource.destroy();
            }
            return tile;
        });
    }

    var should_start = true;
    var music : hxd.snd.Channel;
    var in_level : Bool = false;

    public function enter(){
        interactive.cancelEvents = false;
        should_start = !should_start;
        // if (should_start)
            startLevel();
            if (level_index == levels.length-1){
                music = Assets.music_levels.play(true, 0);
                music.fadeTo(0.5, 1);
            }else if (music == null){
                music = Assets.music_tutorial.play(true, 0);
                music.fadeTo(0.5, 1);
            }
            
        // else{
            // stack.push(new LevelIntro(stack, scene, levels[level_index].name));
        // }
    }

    public function exit(){
        interactive.cancelEvents = true;
        music.fadeTo(0,0.5, music.stop);
        music = null;
    }

    public function dispose(){
        
    }

function collapseBoard(){

    for (x in 0 ... board.width){

        var y = board.height-1;
        var empty : Board.BoardTile = null;

        while (y >= 0){

            var tile = board.getTile(x, y);

            if (tile.resource == null){
                if (empty == null)
                    empty = tile;
            }else{
                if (empty != null){
                    tile.resource.move(0, empty.y-tile.y, null);
                    y = empty.y;
                    empty = null;
                }
            }
            y--;
        }
        
    }

    // when the board as collapsed, it means we did a move
    league.applyLeagueBonus(this);
    markerGameEnd = true;
    // checkForGameEnd();
}

    function growBoard(){
        for (y in 0 ... board.height){
            for (x in 0 ... board.width){
                if (board.getTile(x, y).resource == null){
                    resources.createRandomResource(this).setPosition(x, y);
                }
            }
        }
    }

    public function refillBoard(){
        need_growth = true;
    }

    var time_without_moves : Float = 0;
    var max_time_without_moves : Float = 60 * 10; // 10 seconds
    var random_selected : Resource;

    public function update(tmod:Float){

        resources.update(tmod);

        if (time_without_moves >= max_time_without_moves){
            if (random_selected == null){
                if (hasAvailableMoves()){
                    random_selected = getRandomAvailable();
                    random_selected.select();
                    timer = null;
                }
            }
        }else{
            if (random_selected != null){
                random_selected.unselect();
                random_selected = null;
            }
            if (selected == null)
                time_without_moves += tmod * 1;
        }

        if (need_growth){
            growBoard();
            need_growth = false;
        }

        if (need_collapse){
            collapseBoard();
            need_collapse = false;
        }

        if (!hasAvailableMoves()){
            checkForGameEnd();
        }
        
        if (hxd.Key.isPressed(hxd.Key.R) && hxd.Key.isDown(hxd.Key.CTRL)){
            startLevel();
        }
    }

    public function postUpdate(tmod:Float){

        sideboard.update(tmod);
        resources.postUpdate();

        var i = points_effects.length-1;
        while(i >= 0){
            var item = points_effects[i];
            item.alpha -= 0.02 * tmod;
            item.y -= 1 * tmod;
            if (item.alpha <= 0){
                points_effects.remove(item);
                item.remove();
            }
            i--;
        }
    }
}