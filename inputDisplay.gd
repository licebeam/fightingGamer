extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var node = preload("res://packedInput.tscn")
var spriteIns;
var inputSequence;
const TIMERMAX = 60;
var timer = TIMERMAX;
# Called when the node enters the scene tree for the first time.
func _ready():
	spriteIns = node.instance();
	pass # Replace with function body.

func killLast(): # need to fix this jarring graphical issue moves before destroy.
	inputSequence = get_node('../../TheGame/player1').heldInputSequence;
	var lastChild = self.get_child(self.get_child_count()-1)
	lastChild.queue_free()
	remove_child(lastChild)
	inputSequence.pop_front();
	timer = TIMERMAX;
	for child in self.get_children():
		child.get_child(0).position.y += 10
		
func killAll():
	for child in self.get_children():
		child.queue_free()
		
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	inputSequence = get_node('../../TheGame/player1').heldInputSequence;
	if(inputSequence.size() >= 1):
		killAll()
		for i in inputSequence.size():
			spriteIns = node.instance();
			spriteIns.get_child(0).get_child(0).set_frame(inputSequence[i])
			spriteIns.get_child(0).position.y = -i * 10
			add_child(spriteIns) #Spawns wherever script is attatched.
	
	if inputSequence.size() >= 1:
		timer -= 1;
	if timer <= 0 || inputSequence.size() >= 15: 
		killLast()
#	pass
