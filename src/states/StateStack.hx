package states;

abstract StateStack(Array<IState>){

    var current (get, never) : IState; inline function get_current() return this[this.length-1];

    public inline function new(){
        this = [];
    }

    public inline function push(state:IState){
        if (this.length > 0) current.exit();
        this.push(state);
        state.enter();
    }

    public inline function pop(){
        if (this.length > 0){
            current.exit();
            current.dispose();
        }
        this.pop();
        if (this.length > 0) current.enter();
    }

    public inline function update(tmod:Float){
        if (this.length > 0){
            current.update(tmod);
        }
        for (state in this){
            state.postUpdate(tmod);
        }
    } 
}