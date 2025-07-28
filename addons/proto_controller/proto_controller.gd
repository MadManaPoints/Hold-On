class_name Player

extends RigidBody3D

@export var can_move : bool = true
@export var has_gravity : bool = true
@export var can_jump : bool = true
@export var can_freefly : bool = false

@export_group("Speeds")
## Look around rotation speed.
@export var look_speed : float = 0.002
## Normal speed.
@export var base_speed : float = 7.0
## Speed of jump.
@export var jump_velocity : float = 4.5
## How fast do we freefly?
@export var freefly_speed : float = 25.0

@export_group("Input Actions")
## Name of Input Action to move Left.
@export var input_left : String = "ui_left"
## Name of Input Action to move Right.
@export var input_right : String = "ui_right"
## Name of Input Action to move Forward.
@export var input_forward : String = "ui_up"
## Name of Input Action to move Backward.
@export var input_back : String = "ui_down"
## Name of Input Action to Jump.
@export var input_jump : String = "ui_accept"
## Name of Input Action to toggle freefly mode.
@export var input_freefly : String = "freefly"
@export var reach_hand : String = "hold_on";

@export var playerTwo : bool; 

var mouse_captured : bool = false
var look_rotation : Vector2
var move_speed : float = 0.0
var freeflying : bool = false
var player_input_num : int = 0;

## IMPORTANT REFERENCES
@onready var collider: CollisionShape3D = $CollisionShape3D;
@onready var anim : AnimationPlayer = $AnimationPlayer;

var move_dir : Vector3 = Vector3.ZERO;
@onready var skeleton : Skeleton3D = $Node/Skeleton3D;
@onready var look : LookAtModifier3D = $Node/Skeleton3D/LookAtModifier3D;
@onready var mesh : MeshInstance3D = $Node/Skeleton3D/Ch46;
@onready var anim_tree : AnimationTree = $AnimationTree;
var target_hand : Vector3;
var modified_bone : bool;

var hand_id : int; var hand; var hand_pos : Vector3;

var is_holding : bool;
var reaching : bool;
var is_being_dragged : bool;
var drag_vel : Vector3;
var partner_vel : Vector3;

var velocity : Vector3;

func _ready() -> void:
	check_input_mappings()
	move_speed = base_speed;
	anim.play("New_idle");

	if(playerTwo):
		player_input_num = 1;
	
	if(!playerTwo):
		hand_id = skeleton.find_bone("mixamorigRightHand");
	else:
		hand_id = skeleton.find_bone("mixamorigLeftHand");
	
	#THIS WILL TRACK WHEN LOOK MODIFIER NODE HAS PROCESSED 
	look.modification_processed.connect(_on_modification_processed);


func _unhandled_input(event: InputEvent) -> void:
	# Mouse capturing
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		capture_mouse()
	if Input.is_key_pressed(KEY_ESCAPE):
		release_mouse()


func _physics_process(delta: float) -> void:
	# Apply desired movement to velocity
	if can_move:
		var input_dir := Input.get_vector(input_back, input_forward, input_left, input_right)
		move_dir = (Vector3(input_dir.x, 0, input_dir.y).normalized());
		if(move_dir):
			move_dir *= move_speed;
			velocity.x = move_dir.x;
			velocity.z = move_dir.z;
			#PREVENT BACKWARD MOVEMENT - DO I EVEN WANT THIS?!?!
			if(velocity.x < -0.3):
				velocity = Vector3.ZERO;
		else:
			velocity.x = move_toward(velocity.x, 0, 8);
			velocity.z = move_toward(velocity.z, 0, 8);
	else:
		velocity = Vector3.ZERO;

	#rotate_player();
	# Use velocity to actually move
	#print(self.linear_velocity);
	self.apply_central_force(velocity)
	
	if(velocity.x == 0):
		self.linear_velocity.x = 0;
	if(velocity.z == 0):
		self.linear_velocity.z = 0;
	
	#move_and_slide();


func _process(delta : float) -> void:
	#print(velocity.x);
	if(velocity == Vector3.ZERO):
		anim.play("New_idle");
	elif(velocity.x > 0.03):
		anim.play("New_walk");
	elif(velocity.z < -0.055):
		anim.play("Left_strafe");
	elif(velocity.z > 0.055):
		anim.play("Right_strafe");
	elif(velocity.x < -0.04):
		anim.play("New_idle");
	
	reaching = Input.is_action_pressed(reach_hand);

	#SET PROPER TRIGGER BUTTON FOR BOTH PLAYERS
	if(reaching || is_holding):
		modified_bone = true;
		$Node/Skeleton3D/LookAtModifier3D.active = true;
		anim_tree.active = true;
	else:
		modified_bone = false;
		$Node/Skeleton3D/LookAtModifier3D.active = false;
		anim_tree.active = false;


	#KEEP TRACK OF HAND POSITION BEFORE OVERRIDE
	if(!modified_bone):
		get_hand_position();


func _on_modification_processed():
	#KEEP TRACK OF HAND POSITION AFTER OVERRIDE
	if(modified_bone):
		get_hand_position();


func get_hand_position() -> void:
	hand = skeleton.get_bone_global_pose(hand_id);
	hand_pos = skeleton.to_global(hand.origin);
	target_hand = hand_pos;


func rotate_player() -> void:
	#MOST PIECES OF ROTATION CODE ARE FROM GOOGLE SEARCH
	var joy_x = Input.get_joy_axis(player_input_num, JOY_AXIS_LEFT_X);
	var joy_y = Input.get_joy_axis(player_input_num, JOY_AXIS_LEFT_Y);

	if abs(joy_x) < 0.1:
		joy_x = 0;
	if abs(joy_y) < 0.1:
		joy_y = 0;

	if joy_x != 0 || joy_y != 0:
		var angle = atan2(joy_y, joy_x);
		rotation.y = -angle;


## Rotate us to look around.
## Base of controller rotates around y (left/right). Head rotates around x (up/down).
## Modifies look_rotation based on rot_input, then resets basis and rotates by look_rotation.
func rotate_look(rot_input : Vector2):
	look_rotation.x -= rot_input.y * look_speed
	look_rotation.y -= rot_input.x * look_speed
	transform.basis = Basis()
	rotate_y(look_rotation.y)
	#head.transform.basis = Basis()
	#head.rotate_x(look_rotation.x)


func enable_freefly():
	collider.disabled = true
	freeflying = true
	velocity = Vector3.ZERO

func disable_freefly():
	collider.disabled = false
	freeflying = false


func capture_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_captured = true


func release_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_captured = false


## Checks if some Input Actions haven't been created.
## Disables functionality accordingly.
func check_input_mappings():
	if can_move and not InputMap.has_action(input_left):
		push_error("Movement disabled. No InputAction found for input_left: " + input_left)
		can_move = false
	if can_move and not InputMap.has_action(input_right):
		push_error("Movement disabled. No InputAction found for input_right: " + input_right)
		can_move = false
	if can_move and not InputMap.has_action(input_forward):
		push_error("Movement disabled. No InputAction found for input_forward: " + input_forward)
		can_move = false
	if can_move and not InputMap.has_action(input_back):
		push_error("Movement disabled. No InputAction found for input_back: " + input_back)
		can_move = false
	if can_jump and not InputMap.has_action(input_jump):
		push_error("Jumping disabled. No InputAction found for input_jump: " + input_jump)
		can_jump = false
	if can_freefly and not InputMap.has_action(input_freefly):
		push_error("Freefly disabled. No InputAction found for input_freefly: " + input_freefly)
		can_freefly = false

func player_cam_movement(delta : float) -> void:
	if(Input.is_action_pressed("cam_rotation_left")):
		pass
		#head.rotation.y += 1.0 * delta;
	if(Input.is_action_pressed("cam_rotation_right")):
		pass
		#head.rotation.y -= 1.0 * delta;
	if(Input.is_action_pressed("cam_center_up")):
		pass
		#head.position.y += 1.0 * delta;
		#head.rotation.x += 1.0 * delta;
	if(Input.is_action_pressed("cam_center_down")):
		pass
		#head.position.y -= 1.0 * delta;
		#head.rotation.x -= 1.0 * delta;

	#head.rotation.x = clamp(head.rotation.x, deg_to_rad(-20), deg_to_rad(35));


func hanlde_freefly(delta : float) -> void:
	if can_freefly and freeflying:
		var input_dir := Input.get_vector(input_left, input_right, input_forward, input_back)
		#var motion := (head.global_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		#motion *= freefly_speed * delta
		#move_and_collide(motion)
		return

func old_movement(delta : float) -> void:
	if can_move:
		var input_dir := Input.get_vector(input_back, input_forward, input_left, input_right)
		# FIRST PERSON - var move_dir := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		# THIRD PERSON - var move_dir := Vector3(input_dir.x, 0, input_dir.y).rotated(Vector3.UP, head.rotation.y).normalized();
		move_dir = (Vector3(input_dir.x, 0, input_dir.y).normalized());
		if(move_dir):
			move_dir *= move_speed * delta;
			velocity.x = move_dir.x;
			if(is_holding):
				velocity.z = 0;
			else:
				velocity.z = move_dir.z;
			#PREVENT BACKWARD MOVEMENT - DO I EVEN WANT THIS?!?!
			if(velocity.x < -0.3):
				velocity = Vector3.ZERO;
		elif(!move_dir && is_being_dragged && partner_vel.x != 0):
			var pull = 1.0;
			pull *= move_speed * delta;
			velocity.x = pull;
		else:
			velocity.x = move_toward(velocity.x, 0, 8);
			velocity.z = move_toward(velocity.z, 0, 8);
	else:
		velocity = Vector3.ZERO;
