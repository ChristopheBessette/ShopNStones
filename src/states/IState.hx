package states;

interface IState{
    function enter():Void;
    function exit():Void;
    function dispose():Void;
    function update(tmod:Float):Void;
    function postUpdate(tmod:Float):Void;
}