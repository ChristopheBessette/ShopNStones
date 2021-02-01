class LeagueManager{

    public var current_league (default, null) : Int = 20;
    public var next_league_score (default, null) : Int = 1500;

    public var league_hint (default, null) : String;
    public var league_hint_color (default, null) : Int;

    var game : Game;

    public function new(game:Game){
        this.game = game;
        league_hint = "every 5 league passed - new game rule!";
        league_hint_color = Const.COLOR_RED;
    }

    public function canIncreaseLeague(score:Int){
        return next_league_score < game.last_final_score;
    }

    public function increaseLeague(){
        if (current_league == 1) return;
        current_league--;
        next_league_score += 500;
        updateLeagueHint();
    }

    function updateLeagueHint(){
        if (current_league <= 15 && current_league >10){
            league_hint = "league 15 - items will spawn randomly every 5 moves!";
            league_hint_color = Const.COLOR_RED;
        }else if (current_league<=10 && current_league > 5){
            league_hint = "league 10 - when a column is emptied, it's refilled!";
            league_hint_color = Const.COLOR_YELLOW;
        }else if (current_league<=5 && current_league > 1){
            league_hint = "league 5 - when a column is emptied, board is refilled!";
            league_hint_color = Const.COLOR_RED;
        }else if (current_league == 1){
            league_hint = "league 1 - board is refilled on moves!";
            league_hint_color = Const.COLOR_YELLOW;
        }
    }

    var max_move = 5;
    var move = 0;

    public function applyLeagueBonus(game:Game){
        if (current_league <= 15 && current_league > 1){
            if (move < 5){
                move++;
            }else{
                var empties = game.board.getEmptyTiles();
                var tile = empties[rand(0, empties.length-1)];
                if (tile != null)
                    game.resources.createRandomResource(game).setPosition(tile.x, tile.y);
                move = 0;
                @:privateAccess game.need_collapse = true;
            }
        }

        if (current_league <= 10 && current_league > 5){
            for (x in 0 ... game.board.width){
                if (game.board.columnEmpty(x)){
                    for (y in 0 ... game.board.height){
                        game.resources.createRandomResource(game).setPosition(x, y);
                    }
                }
            }
        }

        else if (current_league<=5 && current_league > 1){
             for (x in 0 ... game.board.width){
                if (game.board.columnEmpty(x)){
                    game.refillBoard();
                }
            }
        }

        else if (current_league == 1){
            game.refillBoard();
        }
    }

    function rand(min:Int, max:Int){
        return Math.floor(Math.random()*(max-min+1))+min;
    }
}
