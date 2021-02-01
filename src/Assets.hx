class Assets{

    static var resources : Array<h2d.Tile>;

    public static var font_title : h2d.Font;
    public static var font_text : h2d.Font;

    public static var snd_bwop : hxd.res.Sound;
    public static var snd_bwop2 : hxd.res.Sound;
    public static var snd_coin : hxd.res.Sound;
    public static var snd_star : hxd.res.Sound;
    public static var snd_bomb : hxd.res.Sound;
    public static var snd_mystical1 : hxd.res.Sound;
    public static var snd_mystical2 : hxd.res.Sound;

    public static var music_title : hxd.res.Sound;
    public static var music_tutorial : hxd.res.Sound;
    public static var music_levels : hxd.res.Sound;
    public static var music_highscore : hxd.res.Sound;

    public static function init(){
        resources = [];
        
        snd_bwop = hxd.Res.bwop;
        snd_bwop2 = hxd.Res.bwop2;
        snd_coin = hxd.Res.coin;
        snd_star = hxd.Res.star_sfx;
        snd_bomb = hxd.Res.noise_bomb_sfx;
        snd_mystical1 = hxd.Res.mystery_1;
        snd_mystical2 = hxd.Res.mystery_2;
        music_title = hxd.Res.shop_n_stones_title;
        music_tutorial = hxd.Res.shop_n_stones_tutorial;
        music_tutorial = hxd.Res.shop_n_stones_tutorial;
        music_levels = hxd.Res.shop_n_stones_level_theme;
        music_highscore = hxd.Res.shop_n_stones_highscore;

        font_title = hxd.Res.fredoka_one_regular_40.toFont();
        font_text = hxd.Res.fredoka_one_regular_14.toFont();

        var tile_res = hxd.Res.resources.toTile();
        for (y in 0 ... Std.int(tile_res.height/16))
        for (x in 0 ... Std.int(tile_res.width/16))
        resources.push(tile_res.sub(x*16,y*16,16,16,-8,-8));
    }

    public static function getResource(id:resources.ResourceId){
        return resources[id.getIndex()];
    }
}