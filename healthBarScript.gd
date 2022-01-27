extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var targetBar;
var secondBar; 
var playerHealth;
var startBleedTimer = 20; #10 frames

# Called when the node enters the scene tree for the first time.
func _ready():
	playerHealth = get_node('../../TheGame/player1').health;
	targetBar = get_node("orangeHealth");
	secondBar = get_node("orangeHealth/orangeHealth2")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	playerHealth = get_node('../../TheGame/player1').health;
	targetBar.rect_size.x = playerHealth / 10
	if(secondBar.rect_size.x != targetBar.rect_size.x):
		startBleedTimer -= 1;
		if(startBleedTimer <= 0):
			secondBar.rect_size.x -= 1;
	else: 
		startBleedTimer = 20;
#	pass
