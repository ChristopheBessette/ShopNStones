class Const{

    public static var SCALE = 4;
    public static var TILE_SIZE (default, null) : Int = 16;
    public static var FPS (get, never) : Float; 

    public static var COLOR_RED (default, never) : Int = 0xe64539;
    public static var COLOR_YELLOW (default, never) : Int = 0xff8933;

    static inline function get_FPS() return hxd.Timer.wantedFPS;
}