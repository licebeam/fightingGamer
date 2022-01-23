extends Label

var MAXTIME = 200
var displayerTimer = MAXTIME;
# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func checkTimer(): 
	displayerTimer -= 1;
	if displayerTimer <= 0:
		text = '';
		displayerTimer = MAXTIME
		
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	checkTimer()
#	pass
