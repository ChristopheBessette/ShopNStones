package resources;

class ResourceManager{

    // factory controlling which resources spawns
    var factory : ResourceFactory;
    // list of all current resources
    var resources : Array<Resource> = [];
    // filter all resources by id
    var id_filter : Map<ResourceId, Array<Resource>> = [];
    // counts the total of each resource
    var counter : ResourceCounter;
    
    public var event_removed (default, null) : Event.EventListener<ResourceManager.Event>;
    public var event_added (default, null) : Event.EventListener<ResourceManager.Event>;

    var dispatcher_removed : Event.EventDispatcher<ResourceManager.Event>;
    var dispatcher_added : Event.EventDispatcher<ResourceManager.Event>;

    public function new(factory:ResourceFactory){
        this.factory = factory;
        event_added = new Event.EventListener();
        event_removed = new Event.EventListener();
        dispatcher_added = event_added;
        dispatcher_removed = event_removed;
        counter = new ResourceCounter(this);
    }

    public function getScores(){
        var list = [];
        for (key=>value in id_filter){
            list.push({
                id:key,
                current:value.length,
                total:counter.getTotal(key)
            });
        }
        return list;
    }

    /**
        Clears all the resources
    **/
    public function clear(){
        counter.clear();
        for (resource in resources){
            removeResource(resource);
        }
        resources = [];
        id_filter = [];
    }

    /**
        Removed a resource
    **/
    public function removeResource(resource:Resource){
        resource.dispose();
        resources.remove(resource);
        id_filter.get(resource.id).remove(resource);
        dispatcher_removed.dispatch(new ResourceManager.Event(resource));
    }

    /**
        Create a random resource using the ResourceFactory
    **/
    public function createRandomResource(game:Game){
        if (factory == null) 
            throw "cannot create random resource with null factory";
        return createResource(factory.get(), game);
    }

    /**
        Create a resource using an ResourceId
    **/
    public function createResource(id:ResourceId, game:Game){
        var resource = new Resource(game, id);
        addToFilters(resource);
        dispatcher_added.dispatch(new ResourceManager.Event(resource));
        return resource;
    }

    /**
        Add a resource to the correct filters
    **/
    function addToFilters(resource:Resource){
        resources.push(resource);
        addToIdFilter(resource);
    }

    /**
        Add a resource to the id_filter
    **/
    function addToIdFilter(resource:Resource){
        var list = id_filter.get(resource.id);
        if (list == null) list = id_filter[resource.id] = [];
        list.push(resource);
    }

    /**
        Returns a list of all resource with the correct id
    **/
    public function filterById(id:ResourceId){
        var list = id_filter.get(id);
        return list == null ? [] : list;
    }

    /**
        Updates all the resources
    **/
    public function update(tmod:Float){
        for (resource in resources){
            resource.update(tmod);
        }
    }

    /**
        PostUpdate all the resources
    **/
    public function postUpdate(){
        for (resource in resources){
            resource.postUpdate();
        }

        var i = resources.length-1;
        while(i >= 0){
            var res = resources[i];
            if (res.destroyed){
                removeResource(res);
            }
            i--;
        }
    }
}

class Event{

    public var resource (default, null) : Resource;

    public function new(resource:Resource){
        this.resource = resource;
    }
}