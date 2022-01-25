extends KinematicBody2D

# externals
var inputLable;
var anim;
var debugLable;

# command related
const MAXBUFFER = 8; # frames of total input storage before we delete everything.
var bufferTime = MAXBUFFER;
var MAXKARA = 20 # the amount of kara frames needs to be adjusted
var karaTimer = MAXKARA;
var canKara = false;

var inputSequence = [];
var commands = {
	'dash': ['right', 'right'],
	'dashBack': ['left', 'left'],
	#'hcb': ['left', 'down', 'right'],
	#'hcf': ['right', 'down', 'left'],
	'hadouL': ['down', 'right', 'lp'],
	'lpBoom': ['lp', 'right', 'left'],
};

#charge related stuff;
const MAXCHARGETIME = 60;
var chargeBackTimer = MAXCHARGETIME;
var isChargedBack = false;
var chargeDownTimer = MAXCHARGETIME;
var isChargedDown= false;

#character specific 
const DASHFORWARD = 800;
const DASHBACK = 500;
const FALLSPEED = 500;

var jumpHeight = 0;
var jumpSpeed = 2; #2px per frame
var fallSpeed = 4; #4px per frame
const MAXAIRACCEL = 4;
var airAccel = 0;

var isCrouching = false;

var moveRight = Vector2(200, 0)
var moveLeft = Vector2(-180, 0)

#state machine
enum STATES {IDLE, JAB, STRONG, FIERCE, HADOU, JUMPING, FALLING}
var currentState = STATES.IDLE;


# Called when the node enters the scene tree for the first time.
func _ready():
	# animation player
	anim = get_node("AnimationPlayer");
	inputLable = get_node("../../CanvasLayer/inputLabel")
	anim.connect("animation_finished", self, "animFinished");
	debugLable = get_node("DebugLabel");

#function specifically for moving during an animation frame. used by the animation player
func moveViaAnimation(amount): #change to pixels eventually
	move_and_slide(Vector2(amount, 0))

func arrayBuffCheck(seq, com, n, f): # should refactor this check
	if !range(seq.size()).has(n): 
		return false
	if !range(com.size()).has(f): 
		return false
	return true
		
func checkCommand(): 
	print(inputSequence);
	for command in commands: 
		var actualCombo = 0;
		var n = 0;
		var foundInput = 0;
		var fudgedInputs = 0;
		while n <= inputSequence.size():
			var shouldSkip = false;
			if fudgedInputs >= 3: 
				break
			if  arrayBuffCheck(inputSequence, commands[command], n, foundInput) && inputSequence[n] != commands[command][foundInput]:
				shouldSkip = true;
				fudgedInputs +=1;
				
			if  !shouldSkip && arrayBuffCheck(inputSequence, commands[command], n, foundInput) && inputSequence[n] == commands[command][foundInput]:
				actualCombo += 1;
				foundInput += 1;	
			n += 1;

		if actualCombo >= commands[command].size():
			if(canKara or currentState == STATES.IDLE):
				inputSequence = [];
				moveSetExecute(command)
			bufferTime = MAXBUFFER;
	yield(get_tree(), "idle_frame")
	
func checkAndClearKara():
	karaTimer -= 1;
	if karaTimer <= 0:
		canKara = false;
		karaTimer = MAXKARA
		print('kara stop')
	
func checkAndClearBuffer():
	bufferTime -= 1;
	if bufferTime <= 0:
		inputSequence = []; # can set this to empty to clear the display of inputs;

	 
func getInput():
	# test
	if Input.is_action_pressed('up') && currentState == STATES.IDLE:
		currentState = STATES.JUMPING;
		
	if Input.is_action_just_pressed('right'):
		inputSequence.push_back('right');
		inputLable.text += 'right '
		bufferTime = MAXBUFFER;
		checkCommand()
		
	if Input.is_action_pressed('right') && currentState == STATES.IDLE:
		if !isCrouching: 
			move_and_slide(moveRight)
		bufferTime = MAXBUFFER;
		
	if Input.is_action_just_pressed('left'):
		inputSequence.push_back('left');
		inputLable.text += 'left '
		bufferTime = MAXBUFFER;
		checkCommand()
		
	if Input.is_action_pressed('left'):
		if !isCrouching && currentState == STATES.IDLE: 
			move_and_slide(moveLeft)
		bufferTime = MAXBUFFER;
		chargeBack()
			
	if Input.is_action_pressed('left') == false && chargeBackTimer <= MAXCHARGETIME: 
		if chargeBackTimer >= 20: #frames you can partition a charge
			isChargedBack = false;
		chargeBackTimer += 1;

	if Input.is_action_just_pressed('down'):
		isCrouching = true;
		inputSequence.push_back('down');
		inputLable.text += 'down '
		bufferTime = MAXBUFFER;
		checkCommand()
		
	if Input.is_action_just_released('down'): 
		isCrouching = false;
		
	#punches
	if Input.is_action_just_pressed('lightP'):
		inputSequence.push_back('lp');
		inputLable.text += 'lp '
		bufferTime = MAXBUFFER;
		yield(checkCommand(), "completed");
		# may need to yield here before state change
		if currentState == STATES.IDLE: #this checks to make sure we are not already doing some command.
			currentState = STATES.JAB;
			canKara = true;
			
	if Input.is_action_just_pressed('medP'):
		inputSequence.push_back('mp');
		inputLable.text += 'mp '
		bufferTime = MAXBUFFER;
		yield(checkCommand(), "completed");
		# may need to yield here before state change
		if currentState == STATES.IDLE: #this checks to make sure we are not already doing some command.
			currentState = STATES.STRONG;
			canKara = true;
		
func chargeBack():
	if chargeBackTimer >= 1:
		chargeBackTimer -= 1;
	if chargeBackTimer <= 0: 
		isChargedBack = true;
		chargeBackTimer = 0;
		print('charged')
		
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	debugLable.text = str(currentState)
	getInput()
	checkAndClearBuffer()
		
	for i in get_slide_count():
		var collision = get_slide_collision(i)
		if collision.collider.name == 'test': 
			switchSides();
	
	if canKara: 
		checkAndClearKara();
		
	changeState();
	handleJumpState();
				
#-------------------------------------------
func handleJumpState():
		#handle jump state 
	if(jumpHeight >= 8) && currentState == STATES.JUMPING: 
		jumpHeight -= 1;
		if(airAccel < MAXAIRACCEL):
			airAccel += 0.15;
		move_and_slide(Vector2(0, (-60 * jumpSpeed) / airAccel))
		#self.position.y -= (1 * jumpSpeed) / airAccel;
		
	if(jumpHeight >= 0 && jumpHeight <= 7): #hang time
		jumpHeight -= 1
		airAccel = 0;
		#maintain height
		
	if jumpHeight <= 0 && currentState == STATES.FALLING:
		if(airAccel < MAXAIRACCEL):
			airAccel += 0.2;
		move_and_slide(Vector2(0, (60 * fallSpeed) * airAccel)) #the amount of acceleration needs to be adjusted.
		for i in get_slide_count():
			var collision = get_slide_collision(i)
			if collision.collider.name == 'ground': 
				currentState = STATES.IDLE
				airAccel = 0;

func animFinished(name):
	print('animation end', name)
	if(name == 'jumpUp' || name == 'falling'):
		currentState = STATES.FALLING
		return;
	else: 
		changeState(true);

func playerJump(height): 
	jumpHeight = height;

func changeState(defactoState = false):
	if defactoState: #used by animation end
		currentState = STATES.IDLE;

	match currentState: 
		0: 
			anim.play('idle')
		1: 
			anim.play('jab')
		2: 
			anim.play('strong')
		3: 
			anim.play('jab')
		4: 
			if canKara: 
				print('kara cancelled?')
			anim.play('hadouken')
		5: #jumping
			anim.play('jumpUp');
		6: #falling
			anim.play('falling');
	
func moveSetExecute(command): 
	#check for Kara
		
	if(command == 'dash') && currentState == STATES.IDLE:
		print('did a dash');
		dash('none')
	if(command == 'dashBack'  && currentState == STATES.IDLE):
		print('did a dash left');
		move_and_slide(Vector2(-DASHBACK, 0))
	if(command == 'hcb'):
		print('did half circle back');
	if(command == 'hcf'):
		print('did half circle forward');
	if(command == 'hadouL'):
		print('did a hadouken with lP');
		currentState = STATES.HADOU;
	if(command == 'lpBoom'):
		if isChargedBack:
			print('did a sonic boom motion');
			chargeBackTimer = MAXCHARGETIME;
		
#------------------ Related to interactions 
#collision detection stuff
func switchSides():
	print('switching')
		

## functions related to actual actions
func dash(dir): 
	print('did a dash')
	move_and_slide(Vector2(DASHFORWARD, 0))
