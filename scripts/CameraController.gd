extends KinematicBody2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var p1Pos = 0;
var p2Pos = 0;
var middle = Vector2(0,0)
var initalY = self.position.y;
var airBorne = false;

# Called when the node enters the scene tree for the first time.
func _ready():
	p1Pos = get_node('../player1').position;
	p2Pos = get_node('../player2').position;
	middle = (p1Pos.x + p2Pos.x) / 2

func calculateCenter():
	p1Pos = get_node('../player1').position;
	p2Pos = get_node('../player2').position;
	middle = (p1Pos.x + p2Pos.x) / 2
	airBorne = round(p1Pos.y) != round(p2Pos.y);
	# print()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	calculateCenter();		
	if(airBorne): 
		self.position = Vector2(middle, initalY - 20)
	else: 
		self.position = Vector2(middle, initalY)
#	pass
