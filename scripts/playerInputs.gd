extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var playerInputs;

# Called when the node enters the scene tree for the first time.
func _ready():
	playerInputs = get_node('../../TheGame/player1').inputSequence;
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	playerInputs = get_node('../../TheGame/player1').inputSequence;
	for input in playerInputs:
		print('input')
#	pass
