abstract EventListener<T>(Array<T->Void>){

    public inline function new(){
        this = [];
    }

    public inline function subscribe(fn:T->Void){
        this.push(fn);
    }

    public inline function unsubscribe(fn:T->Void){
        this.remove(fn);
    }

    @:to
    inline function toDispatcher():EventDispatcher<T>{
        return cast this;
    }
}

abstract EventDispatcher<T>(Array<T->Void>){
    
    inline function new(data : Array<T->Void>){
        this = data;
    }

    public function dispatch(data:T){
        for (fn in this)
            fn(data);
    }
}