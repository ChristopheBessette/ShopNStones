package resources;

class ResourceFactory{

    var resources : Array<ResourceId> = [];
    var weights : Array<Float> = [];
    var total_weight : Float = 0;

    public function new(){

    }

    public function add(resource:ResourceId, weight:Float){
        resources.push(resource);
        weights.push(weight);
        total_weight += weight;
    }

    public function clear(){
        total_weight = 0;
        resources = [];
        weights = [];
    }

    public function get(){
        var index : Int = 0;
        var rand = Math.random();
        for (i in 0 ... weights.length){
            var weight = weights[i] / total_weight;
            if (weight > rand){
                index = i;
                break;
            }else{
                rand-=weight;
            }
        }
        return resources[index];
    }

    inline function rand(min:Int, max:Int){
        return Math.floor(Math.random()*(max-min+1))+min;
    }
} 