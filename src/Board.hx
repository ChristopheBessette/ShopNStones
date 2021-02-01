class BoardTile{

    public var x (default, null) : Int;
    public var y (default, null) : Int;
    public var resource : resources.Resource;

    public function new(x:Int, y:Int){
        this.x = x;
        this.y = y;
    }
}

class Board{

    public var width (default, null): Int;
    public var height (default, null): Int;

    var tiles : Array<BoardTile>;

    public function new(width:Int, height:Int){
        this.width = width;
        this.height = height;

        tiles = [
            for (y in 0 ... height)
            for (x in 0 ... width)
            new BoardTile(x, y)
        ];
    }

    public function map<S>(fn:BoardTile->S){
        tiles.map(fn);
    }

    public function filter(fn:BoardTile->Bool){
        return tiles.filter(fn);
    }

    public function tileResourceIs(x:Int, y:Int, id:resources.ResourceId){
        return isValid(x, y) && getTile(x, y).resource != null && getTile(x, y).resource.id == id;
    }

    public function columnEmpty(x:Int){
        for (y in 0 ... height){
            if (getTile(x, y).resource != null) return false;
        }
        return true; 
    }

    public function getEmptyTiles(){
        return tiles.filter((tile:BoardTile)->{
            return (tile.resource == null && (
                tileResourceIsGem(tile.x, tile.y+1) ||
                tileResourceIsGem(tile.x-1, tile.y) ||
                tileResourceIsGem(tile.x+1, tile.y-1)
            ));
        });
    }

    public function tileResourceIsGem(x:Int, y:Int){
        var valid = isValid(x, y);
        if (!valid) return false;
        var res = getTile(x, y).resource;
        return valid && res != null && resources.Resource.specials.indexOf(res.id) == -1;
    }

    public function isValid(x:Int, y:Int){
        return x >= 0 && x < width && y >= 0 && y < height;
    }

    public function getTile(x:Int, y:Int){
        return tiles[convert(x, y)];
    }

    inline function convert(x:Int, y:Int){ 
        return y * width + x;
    }
}
