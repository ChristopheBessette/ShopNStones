typedef UpdateFn = CooldownItem->Void;
typedef FinishedFn = Void->Void;

class CooldownItem{

    public var id (default, null) : String;

    var ftotal : Int = 0;
    var fcurrent : Float = 0;

    var updateFn : UpdateFn;
    var finishedFn : FinishedFn;


    public function new(id:String, frames:Int, update:UpdateFn, ?finished:FinishedFn){
        this.id = id;
        this.ftotal = frames;
        this.fcurrent = frames;
        this.updateFn = update;
        this.finishedFn = finished;
    }

    public inline function getRange(){
        return 1 - fcurrent / ftotal;
    }

    public function update(tmod:Float){
        fcurrent = Math.max(0, fcurrent - (1 * tmod));
        onUpdate();
        if (fcurrent == 0){
            onFinish();
        }
    }

    public function isFinished(){
        return fcurrent == 0;
    }

    inline function onUpdate(){
        if (updateFn != null) updateFn(this);
    }

    inline function onFinish(){
        if (finishedFn != null) finishedFn();
    }
}

class Cooldown{

    var fps : Float;

    var all : Array<CooldownItem> = [];
    var sorted : Map<String, CooldownItem> = [];

    public function new(fps:Float){
        this.fps = fps;
    }

    public function addFrames(id:String, frames:Int, ?update:UpdateFn, ?finished:FinishedFn){
        var cd = new CooldownItem(id, frames, update, finished);
        all.push(cd);
        sorted.set(id, cd);
    }

    public function has(id:String){
        return sorted.get(id);
    }

    public function cancelAll(){
        all = [];
        sorted.clear();
    }

    public function cancel(id:String){
        remove(sorted.get(id));
    }

    function remove(cd:CooldownItem){
        all.remove(cd);
        sorted.remove(cd.id);
    }

    public function update(tmod:Float){
        for (cdi in all){
            cdi.update(tmod);
        }
        var i = all.length-1;
        while (i >= 0){
            if (all[i].isFinished()){
                remove(all[i]);
            }
            i--;
        }
    }
}