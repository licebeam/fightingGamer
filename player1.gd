extends "res://scripts/playerControllers/moveScript.gd"


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	keys = {
		'up': 'up',
		'down': 'down',
		'left': 'left', 
		'right': 'right',
		'lp': 'lightP',
		'mp': 'medP',
		'hp': 'hardP',
		'lk': 'lightK',
		'mk': 'medK',
		'hk': 'hardK',
	}
	enemy = 'player2'
	hitBox = get_node("hitArea1/hitBox");
	boxAreaHit = get_node("hitArea1")
	boxAreaHurt = get_node("hurtArea1")
	enemyInstance = get_node('../player2');
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
