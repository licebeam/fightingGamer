extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var timer1;
var timer2;
var currentTime = 99;
var timeStr = str(currentTime)
var _timer = null;

# Called when the node enters the scene tree for the first time.
func _ready():
	timer1 = get_node("TimerSprite");
	timer2 = get_node("TimerSprite2");
	# actual yield timer;
	_timer = Timer.new()
	add_child(_timer)

	_timer.connect("timeout", self, "_on_Timer_timeout")
	_timer.set_wait_time(1.0)
	_timer.set_one_shot(false) # Make sure it loops
	_timer.start()

func _on_Timer_timeout():
	if currentTime <= 0: 
		currentTime = 99;
	currentTime -= 1;
	timeStr = str(currentTime)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if currentTime >= 10:
		timer1.set_frame((int(timeStr[0]) + 1))
		timer2.set_frame((int(timeStr[1]) + 1))
	else: 
		timer1.set_frame(1)
		timer2.set_frame((int(timeStr[0]) + 1))

