class SideBoard{

    var invalidated = false;
    var game : Game;

    var resourceCount : Map<resources.ResourceId, Int> = [];
    var resources : Array<resources.ResourceId> = [];

    var top :h2d.Object;
    var root : h2d.Flow;

    var elements : Array<SideBoardResource>  = [];


    public function new(game:Game){
        this.game = game;
        game.resources.event_added.subscribe(onResourceAdded);
        game.resources.event_removed.subscribe(onResourceRemoved);

        game.addHud(root = new h2d.Flow());
        root.layout = Vertical;
        root.x = 8 * Const.SCALE;
        root.verticalSpacing = 6 * Const.SCALE;
        root.y = 8 * Const.SCALE;
    }

    public function clear(){
        resourceCount.clear();
        resources = [];
        for (element in elements){
            element.remove();
        }
        elements = [];
    }

    public function dispose(){
        game.resources.event_added.unsubscribe(onResourceAdded);
        game.resources.event_removed.unsubscribe(onResourceRemoved);
    }

    function onResourceAdded(event:resources.ResourceManager.Event){
        if (resourceCount.exists(event.resource.id)){
            resourceCount[event.resource.id]++;
            // trace('added sideboard resource count for [${event.resource.id}]');
        }else{
            resourceCount[event.resource.id] = 1;
        }
        invalidate();
    }

    function onResourceRemoved(event:resources.ResourceManager.Event){
        if (resourceCount.exists(event.resource.id)){
            resourceCount[event.resource.id]--;
            if (resourceCount[event.resource.id] == 0){
                resourceCount.remove(event.resource.id);
                resources.remove(event.resource.id);
            }
        }
        invalidate();
    }

    public inline function invalidate(){
        invalidated = true;
    }

    public function update(tmod:Float){
        if (invalidated){
            for (element in elements){
                var score = resourceCount.get(element.id);
                if (score == null){
                    element.fadeAway();
                }else if(element.c != score){
                    element.setCount(score);
                }
            }

            for (key=>val in resourceCount){
                if (resources.indexOf(key) < 0){
                    resources.push(key);
                    var element = new SideBoardResource(key, root);
                    elements.push(element);
                    element.setCount(val);
                    // trace('created sideboard resource for [${key}]');
                }
            }
            invalidated = true;
        }
        for (element in elements){
            element.update(tmod);
        }

        var i = elements.length-1;
        while(i >= 0){
            var element = elements[i];
            if (element.alpha <= 0){
                elements.remove(element);
                element.remove();
            }
            i--;
        }
    }
}


class SideBoardResource extends h2d.Object{

    var icon : h2d.Bitmap;
    var count : h2d.Text;

    public var c : Int;

    var iconScale = 2;
    var iconScaleX = 0.;
    var iconScaleY = 0.;

    var fading : Bool = false;

    public var id : resources.ResourceId;

    public function new(id:resources.ResourceId, parent:h2d.Object){
        super(parent);

        this.id = id;

        icon = new h2d.Bitmap(Assets.getResource(id), this);
        count = new h2d.Text(Assets.font_text, this);
        count.x = 6 * Const.SCALE;
        count.y = -count.textHeight * 0.5;
    }

    public function setCount(count:Int){
        this.count.text = '${count}';
        this.c = count;
        bweep();
    }

    public function fadeAway(){
        fading = true;
    }

    function bweep(){
        iconScaleX = 2;
        iconScaleY = 1.5;
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