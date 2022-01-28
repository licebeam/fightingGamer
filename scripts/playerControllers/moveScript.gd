extends KinematicBody2D

var keys = {
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
var enemy = 'player2'

# externals
var anim;
var debugLable;

# command related
# const MAXLAG = 2;
# var inputLag = MAXLAG;

var controlsFlipped = false;
const MAXBUFFER = 8; # frames of total input storage before we delete everything.
var bufferTime = MAXBUFFER;
var MAXKARA = 20 # the amount of kara frames needs to be adjusted
var karaTimer = MAXKARA;
var canKara = false;
var inputSequence = [];
var heldInputSequence = []; #only used for displaying input
var isForward = false;
var isBackward = false;
var commands; #used to set the flipped commands;
var commandsRight = {
	'dash': ['right', 'right'],
	'dashBack': ['left', 'left'],
	'hadouL': ['down', 'right', 'lp'],
};
var commandsLeft = {
	'dash': ['left', 'left'],
	'dashBack': ['right', 'right'],
	'hadouL': ['down', 'left', 'lp'],
};

#charge related stuff;
const MAXCHARGETIME = 60;
var chargeBackTimer = MAXCHARGETIME;
var isChargedBack = false;
var chargeDownTimer = MAXCHARGETIME;
var isChargedDown= false;

#character specific 
const DASHFORWARD = 240;
const DASHBACK = 180;
const FALLSPEED = 500;
const JUMPDIAGSPEED = 120;
var jumpHeight = 0;
var jumpSpeed = 2; #2px per frame
var fallSpeed = 4; #4px per frame
const MAXAIRACCEL = 4;
var airAccel = 0;
var isCrouching = false;
var moveRight = Vector2(120, 0)
var moveLeft = Vector2(-90, 0)

var health = 820; #820 is default for now, used by rect

#state machine
enum STATES {
	IDLE,
	JAB,
	STRONG,
	FIERCE,
	HADOU,
	JUMPING,
	FALLING,
	SHORT,
	FORWARD,
	ROUNDHOUSE,
	CROUCH,
	WALK, 
	JUMPDIAG,
	DASHF,
	DASHB,
}
var currentState = STATES.IDLE;

# Called when the node enters the scene tree for the first time.
func _ready():
	# animation player
	anim = get_node("AnimationPlayer");
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
		var shouldNotSkip = (command == 'dash' || command == 'dashBack')
		#print(shouldNotSkip)
		var actualCombo = 0;
		var n = 0;
		var foundInput = 0;
		var fudgedInputs = 0;
		while n <= inputSequence.size():
			var shouldSkip = false;
			if shouldNotSkip && fudgedInputs >= 1: 
				#print('failed dash')
				# it a dash cannot be input unless the buffer is clear
				# TODO need to fix this so it can make sure the input is in order
				break
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
	
func checkAndClearKara(): #this needs to be changed via animation eventually.
	karaTimer -= 1;
	if karaTimer <= 0:
		canKara = false;
		karaTimer = MAXKARA
		#print('kara stop')
	
func checkAndClearBuffer(): #this needs to change to pop from the back of the array eventually.
	bufferTime -= 1;
	if bufferTime <= 0:
		inputSequence = []; # can set this to empty to clear the display of inputs;

func getInput():
	var direction = Vector2();
	var holdDowns = Vector2();
	holdDowns.x = int(Input.is_action_just_pressed(keys.right)) - int(Input.is_action_just_pressed(keys.left))
	holdDowns.y = int(Input.is_action_pressed(keys.down)) - int(Input.is_action_pressed(keys.up))
	
	var holdRights = Vector2();
	holdRights.x = int(Input.is_action_pressed(keys.right)) - int(Input.is_action_pressed(keys.left))
	holdRights.y = int(Input.is_action_just_pressed(keys.down)) - int(Input.is_action_just_pressed(keys.up))
	
	direction.x = int(Input.is_action_just_pressed(keys.right)) - int(Input.is_action_just_pressed(keys.left))
	direction.y = int(Input.is_action_just_pressed(keys.down)) - int(Input.is_action_just_pressed(keys.up))

	match holdRights:
		Vector2(-1, -1): 
			#print('up left')
			heldInputSequence.push_back(6);			
			if currentState == STATES.IDLE || currentState == STATES.WALK:
				currentState = STATES.JUMPDIAG;
				isForward = false;
				isBackward = true;	
				
		Vector2(-1, 1): 
			#print('down left')
			heldInputSequence.push_back(5);			
			
		Vector2(1, -1): 
			#print('up right')
			heldInputSequence.push_back(7);			
			if currentState == STATES.IDLE || currentState == STATES.WALK:
				currentState = STATES.JUMPDIAG;	
				isForward = true;
				isBackward = false;
				
		Vector2(1, 1): 
			#print('down right')
			heldInputSequence.push_back(4);	
			
	match holdDowns:
		Vector2(-1, -1): 
			#print('up left')
			heldInputSequence.push_back(6);	
			if (currentState == STATES.IDLE || currentState == STATES.WALK) && currentState != STATES.JUMPING:
				currentState = STATES.JUMPDIAG;	
				isForward = false;
				isBackward = true;	
				
		Vector2(-1, 1): 
			#print('down left')
			heldInputSequence.push_back(5);			
			
		Vector2(1, -1): 
			#print('up right')
			heldInputSequence.push_back(7);		
			if (currentState == STATES.IDLE || currentState == STATES.WALK) && currentState != STATES.JUMPING:
				currentState = STATES.JUMPDIAG;		
				isForward = true;
				isBackward = false;	
				
		Vector2(1, 1): 
			#print('down right')
			heldInputSequence.push_back(4);	
			
	match direction:	
		Vector2(1, 0): 
			heldInputSequence.push_back(3);
			inputSequence.push_back('right');
			bufferTime = MAXBUFFER;
			checkCommand()
			
		Vector2(-1, 0): 
			heldInputSequence.push_back(2);
			inputSequence.push_back('left');
			bufferTime = MAXBUFFER;
			checkCommand()
			
		Vector2(0, -1): 
			heldInputSequence.push_back(0);
			inputSequence.push_back('up');
			if (currentState == STATES.IDLE || currentState == STATES.WALK) && currentState != STATES.JUMPDIAG:
				currentState = STATES.JUMPING;	
				
		Vector2(0, 1): 
			heldInputSequence.push_back(1);
			isCrouching = true;
			inputSequence.push_back('down');
			bufferTime = MAXBUFFER;
			checkCommand()
			
	var completeHold = Vector2();
	completeHold.x = int(Input.is_action_pressed(keys.right)) - int(Input.is_action_pressed(keys.left))
	completeHold.y = int(Input.is_action_pressed(keys.down)) - int(Input.is_action_pressed(keys.up))

	match completeHold:	
		Vector2(-1, -1): 
			if currentState == STATES.IDLE || currentState == STATES.WALK:
				currentState = STATES.JUMPDIAG;	
				isBackward = true;
				isForward = false;
				
		Vector2(1, -1): 
			if currentState == STATES.IDLE || currentState == STATES.WALK:
				currentState = STATES.JUMPDIAG;	
				isBackward = false;
				isForward = true;
				
		Vector2(-1, 1): 
			isCrouching = true;
			if currentState == STATES.IDLE || currentState == STATES.WALK: #this checks to make sure we are not already doing some command.
				currentState = STATES.CROUCH;

		Vector2(1, 1): 
			isCrouching = true;
			if currentState == STATES.IDLE || currentState == STATES.WALK: #this checks to make sure we are not already doing some command.
				currentState = STATES.CROUCH;
				
		Vector2(1, 0): 
			if currentState == STATES.IDLE || Input.is_action_pressed(keys.right) && currentState == STATES.WALK:
				if !isCrouching: 
					if controlsFlipped:
						move_and_slide(-moveLeft)
					else: 
						move_and_slide(moveRight)
					currentState = STATES.WALK;
				bufferTime = MAXBUFFER;
				isBackward = false;
				isForward = true;
				
		Vector2(-1, 0): 
			if Input.is_action_pressed(keys.left) && currentState == STATES.IDLE || Input.is_action_pressed(keys.left) && currentState == STATES.WALK:
				if !isCrouching: 
					if controlsFlipped:
						move_and_slide(-moveRight)
					else: 
						move_and_slide(moveLeft)
					currentState = STATES.WALK;
				bufferTime = MAXBUFFER;
				isForward = false;
				isBackward = true;
				chargeBack()
				
		Vector2(0, -1): 
			if currentState == STATES.IDLE && currentState != STATES.JUMPDIAG:
				currentState = STATES.JUMPING;	
				
		Vector2(0, 1): 
			isCrouching = true;
			if currentState == STATES.IDLE || currentState == STATES.WALK: #this checks to make sure we are not already doing some command.
				currentState = STATES.CROUCH;
	
	#input releases 			
	if Input.is_action_just_released(keys.down): 
		isCrouching = false;
		
	if ((Input.is_action_just_released(keys.left) || Input.is_action_just_released(keys.right)) && currentState == STATES.WALK):
		#print(anim.current_animation_position)
		# TODO: fix this so we don't see weird animation frames.
		currentState = STATES.IDLE;
			
	if Input.is_action_pressed(keys.left) == false && chargeBackTimer <= MAXCHARGETIME: 
		if chargeBackTimer >= 20: #frames you can partition a charge
			isChargedBack = false;
		chargeBackTimer += 1;
		
	#punches
	if Input.is_action_just_pressed(keys.lp):
		#test 
		health -= 40;
		#
		inputSequence.push_back('lp');
		heldInputSequence.push_back(8);
		bufferTime = MAXBUFFER;
		yield(checkCommand(), "completed");
		# may need to yield here before state change
		if currentState == STATES.IDLE || currentState == STATES.WALK: #this checks to make sure we are not already doing some command.
			currentState = STATES.JAB;
			canKara = true;
			
	if Input.is_action_just_pressed(keys.mp):
		inputSequence.push_back('mp');
		heldInputSequence.push_back(9);
		bufferTime = MAXBUFFER;
		yield(checkCommand(), "completed");
		# may need to yield here before state change
		if currentState == STATES.IDLE || currentState == STATES.WALK: #this checks to make sure we are not already doing some command.
			currentState = STATES.STRONG;
			canKara = true;
			
	if Input.is_action_just_pressed(keys.lk):
		inputSequence.push_back('lk');
		heldInputSequence.push_back(11);
		bufferTime = MAXBUFFER;
		yield(checkCommand(), "completed");
		# may need to yield here before state change
		if currentState == STATES.IDLE || currentState == STATES.WALK: #this checks to make sure we are not already doing some command.
			currentState = STATES.SHORT;
			canKara = true;
			
	if Input.is_action_just_pressed(keys.mk):
		inputSequence.push_back('mk');
		heldInputSequence.push_back(12);
		bufferTime = MAXBUFFER;
		yield(checkCommand(), "completed");
		# may need to yield here before state change
		if currentState == STATES.IDLE || currentState == STATES.WALK: #this checks to make sure we are not already doing some command.
			currentState = STATES.FORWARD;
			canKara = true;
			
	if(currentState != STATES.JUMPING && currentState != STATES.JUMPDIAG && currentState != STATES.FALLING):
		if(!Input.is_action_pressed(keys.right)):
			isForward = false;
		if(!Input.is_action_pressed(keys.left)):
			isBackward = false;
		
func chargeBack():
	if chargeBackTimer >= 1:
		chargeBackTimer -= 1;
	if chargeBackTimer <= 0: 
		isChargedBack = true;
		chargeBackTimer = 0;
		#print('charged')

func _physics_process(delta):
		
	for i in get_slide_count():
		var collision = get_slide_collision(i)
		var middle = (position.x + collision.collider.position.x) / 2
		if collision.collider.name == enemy && currentState == STATES.FALLING: 
			if middle >= position.x: 
				move_and_collide(Vector2(-1, 0))
				collision.collider.move_and_collide(Vector2(1, 0))
			else: 
				move_and_collide(Vector2(1, 0))
				collision.collider.move_and_collide(Vector2(-1, 0))
		#handle walk pushing
		#if collision.collider.name == 'fake2pNode' && currentState != STATES.FALLING: 
			#print(collision.collider.name)
			#if middle >= position.x: 
				#collision.collider.move_and_collide(Vector2(1, 0))
			#else: 
				#collision.collider.move_and_collide(Vector2(-1, 0))	
				
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# debugLable.text = str(currentState)
	getInput()
	checkAndClearBuffer()

	if canKara: 
		checkAndClearKara();
		
	changeState();
	handleJumpState();
	switchSides();
#-------------------------------------------

func handleJumpState():
		#handle jump state 
	if(jumpHeight >= 8) && (currentState == STATES.JUMPING || currentState == STATES.JUMPDIAG): 
		jumpHeight -= 1;
		if(airAccel < MAXAIRACCEL):
			airAccel += 0.15;
		if(isForward && currentState == STATES.JUMPDIAG):
			move_and_slide(Vector2(JUMPDIAGSPEED, (-60 * jumpSpeed) / airAccel))
		elif(isBackward && currentState == STATES.JUMPDIAG):
			move_and_slide(Vector2(-JUMPDIAGSPEED, (-60 * jumpSpeed) / airAccel))
		else: 
			move_and_slide(Vector2(0, (-60 * jumpSpeed) / airAccel))
		#self.position.y -= (1 * jumpSpeed) / airAccel; original jump code, move_and_slide uses delta
		
	if(jumpHeight >= 0 && jumpHeight <= 7): #hang time + move left and right on jump
		jumpHeight -= 1
		airAccel = 0;
		if(isForward && currentState == STATES.JUMPDIAG):
			move_and_slide(Vector2(JUMPDIAGSPEED, 0))
		elif(isBackward && currentState == STATES.JUMPDIAG):
			move_and_slide(Vector2(-JUMPDIAGSPEED, 0))
		
	if jumpHeight <= 0 && currentState == STATES.FALLING:
		if(airAccel < MAXAIRACCEL):
			airAccel += 0.2;
		if(isForward):
			move_and_slide(Vector2(JUMPDIAGSPEED, (60 * fallSpeed) * airAccel)) #the amount of acceleration needs to be adjusted.
		elif(isBackward):
			move_and_slide(Vector2(-JUMPDIAGSPEED, (60 * fallSpeed) * airAccel)) #the amount of acceleration needs to be adjusted.
		else:
			move_and_slide(Vector2(0, (60 * fallSpeed) * airAccel)) #the amount of acceleration needs to be adjusted.
		for i in get_slide_count():
			var collision = get_slide_collision(i)
			#print('collision', collision.collider.name)
			if collision.collider.name == 'ground': 
				currentState = STATES.IDLE
				isForward = false;
				isBackward = false;
				airAccel = 0;

func animFinished(name):
	# print('animation end', name)
	if(name == 'jumpUp' || name == 'jumpDiag' || name == 'falling'): # whatever animation that ends where we don't IDLE
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
			anim.play('fierce')
		4: 
			#if canKara: 
				#print('kara cancelled?')
			anim.play('hadouken')
		5: #jumping
			anim.play('jumpUp');
		6: #falling
			anim.play('falling');
		7: #short
			anim.play('short');
		8: #forward
			anim.play('forward');
		9: #roundhouse
			anim.play('short');
		10: #crouch
			anim.play('crouch');
		11: #walk:
			anim.play('walk');
		12: #jump diag
			anim.play('jumpDiag');
		13: #dash f
			anim.play('dash');
			if controlsFlipped:
				move_and_slide(Vector2(-DASHFORWARD, 0))
			else: 
				move_and_slide(Vector2(DASHFORWARD, 0))
		14: # dash back
			anim.play('dashBack');
			if controlsFlipped:
				move_and_slide(Vector2(DASHBACK, 0))
			else: 
				move_and_slide(Vector2(-DASHBACK, 0))
			
func moveSetExecute(command): 
	if command == 'dash' && (currentState == STATES.IDLE || currentState == STATES.WALK):
		#print('dash');
		currentState = STATES.DASHF;
	if command == 'dashBack' && (currentState == STATES.IDLE || currentState == STATES.WALK):
		#print('dash');
		currentState = STATES.DASHB;
	#if(command == 'hcb'):
		#print('did half circle back');
	#if(command == 'hcf'):
		#print('did half circle forward');
	if(command == 'hadouL'):
		#print('did a hadouken with lP');
		currentState = STATES.HADOU;
	if(command == 'lpBoom'):
		if isChargedBack:
			#print('did a sonic boom motion');
			chargeBackTimer = MAXCHARGETIME;
		
#------------------ Related to interactions 

func switchSides():
	var camera = get_node('../CameraController');
	if(position.x > camera.position.x):
		var sprite = get_node("playerSprite")
		commands = commandsLeft;
		controlsFlipped = true;
		sprite.set_flip_h(true);
	else: 
		var sprite = get_node("playerSprite")
		commands = commandsRight;
		controlsFlipped = false;
		sprite.set_flip_h(false);
		
## functions related to actual actions
