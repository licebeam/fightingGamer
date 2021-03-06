extends "res://scripts/playerControllers/moveScript.gd"


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	keys = {
		'up': 'p2up',
		'down': 'p2down',
		'left': 'p2left', 
		'right': 'p2right',
		'lp': 'p2lightP',
		'mp': 'medP',
		'hp': 'hardP',
		'lk': 'lightK',
		'mk': 'medK',
		'hk': 'hardK',
	}
	enemy = 'player1'
	hitBox = get_node("hitArea2/hitBox");
	boxAreaHit = get_node("hitArea2")
	boxAreaHurt = get_node("hurtArea")
	enemyInstance = get_node('../player1');


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
