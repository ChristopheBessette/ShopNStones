package resources;

class ResourceCounter{

    var manager : ResourceManager;
    var resourceCounter : Map<ResourceId, Int> = [];

    public function new(manager:ResourceManager){
        this.manager = manager;
        manager.event_added.subscribe(onResourceAdded);
    }

    function onResourceAdded(event:ResourceManager.Event){
        if (resourceCounter.exists(event.resource.id)){
            resourceCounter[event.resource.id]++;
        }else{
            resourceCounter[event.resource.id] = 1;
        }
    }

    public function getTotal(id:ResourceId){
        if (resourceCounter.exists(id))
            return resourceCounter[id];
        return -1;
    }

    public function clear(){
        resourceCounter = [];
    }
}