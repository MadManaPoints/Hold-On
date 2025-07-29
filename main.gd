extends Node3D

@export_group("Speeds")
@export var cam_speed : float = 1.0;

@onready var cam : Camera3D = $Camera3D;
@onready var player_one : Player = $Player;
@onready var player_two : Player = $Player2;
@onready var center : Node3D = $Center;
@onready var tracker : Node3D = $Tracker;

@onready var hand_area : Node3D = $HandArea;
@onready var proximity_test : Control = $"Proximity Test";
@onready var target_one : RigidBody3D = $new_target;
@onready var target_two : RigidBody3D = $new_target2;
@onready var hand_node : RigidBody3D = $HandArea; 
@onready var p1_joint : Generic6DOFJoint3D = $JointBody/CenterPin;
@onready var middle_collision : RigidBody3D = $JointBody;

var new_joint_node_1 : NodePath;
var new_joint_node_2 : NodePath;

var cam_zoom : float;
#Keep players from getting too far from each other
var too_far : bool = false;
var holding_hands : bool;
var hands_locked : bool;
var turn_on_middle_collision : bool;


func _ready() -> void:
	#Get player paths for joints 
	new_joint_node_1 = player_one.get_path();
	new_joint_node_2 = player_two.get_path();
	
	#Turn off collision for joint
	middle_collision.set_collision_layer_value(1, false);


func _process(delta : float) -> void:
	player_closeness(delta);
	detect_hands_lock();
	lock_hands();


func _physics_process(delta: float) -> void:
	cam_movement(delta);
	follow_hands(delta);
	player_drag_detection();


func follow_hands(delta: float) -> void:
	#MOVING USING PHYSICS
	if(target_one.position.distance_to(player_two.target_hand) > 0.2):
		var new_dir: Vector3 = (player_two.target_hand - target_one.position).normalized();
		target_one.linear_velocity = new_dir * 200 * delta;
	else:
		target_one.position = player_two.target_hand;
		target_one.linear_velocity = Vector3.ZERO;

	if(target_two.position.distance_to(player_one.target_hand) > 0.2):
		var new_dir: Vector3 = (player_one.target_hand - target_two.position).normalized();
		target_two.linear_velocity = new_dir * 200 * delta;
	else:
		target_two.position = player_one.target_hand;
		target_two.linear_velocity = Vector3.ZERO;


func lock_hands() -> void:
	#Pins players together to simulate holding hands
	if(hands_locked):
		Game.attached = true;
		p1_joint.node_a = NodePath(new_joint_node_1);
		p1_joint.node_b = NodePath(new_joint_node_2);
	else:
		p1_joint.node_a = NodePath("");
		p1_joint.node_b = NodePath("");


func player_drag_detection() -> void:
	if(!Game.attached):
		player_two.is_being_dragged = false;
	elif((player_one.reaching && !player_two.reaching) && holding_hands):
		player_two.partner_vel.x = player_one.velocity.x;
		player_two.is_being_dragged = true;
	else:
		#player_two.partner_vel.x = 0.0;
		player_two.is_being_dragged = false;


func cam_movement(delta : float) -> void:
	#FOLLOW PLAYERS
	if(player_one.position.x >= player_two.position.x):
		tracker.position = (player_one.position + player_two.position) / 2;
	else:
		tracker.position = (player_two.position + player_one.position) / 2;
	cam.position.x = move_toward(cam.position.x, tracker.position.x - 4.0, 2 * delta);

	#ZOOM BASED ON PLAYER DISTANCE
	if(player_one.position.x >= player_two.position.x):
		center.position = (player_one.position - player_two.position) / 2;
	else:
		center.position = (player_two.position - player_one.position) / 2;

	if(center.position.x < 2.0 and center.position.x > -2.0):
		too_far = false;
		cam_zoom = center.position.x;
	else:
		too_far = true;
		cam_zoom = cam_zoom;
	cam.position.y = map(cam_zoom, -2, 2, 5, 8);


func detect_hands_lock() -> void:
	#print(holding_hands)
	hand_area.hands_up = (Input.is_action_pressed("right_stick_up") &&
						Input.is_action_pressed("right_stick_up_p2"));
	middle_collision.hands_up = hand_area.hands_up;
						
	holding_hands = (Game.player_one_hand && Game.player_two_hand);
	hands_locked = holding_hands; #&& (player_two.position.z - player_one.position.z) < 0.95);
	
	if(hands_locked && !turn_on_middle_collision):
		middle_collision.set_collision_layer_value(1, true);
		turn_on_middle_collision = true;
	elif(!hands_locked && turn_on_middle_collision):
		middle_collision.set_collision_layer_value(1, false);
		turn_on_middle_collision = false;
	
	player_one.is_holding = (hands_locked && player_two.reaching);
	player_two.is_holding = (hands_locked && player_one.reaching);
	
	if(!player_two.reaching && !player_one.reaching && holding_hands):
		Game.player_one_hand = false;
		Game.player_two_hand = false;


func player_closeness(delta : float) -> void:
	#CHANGE ICON BASED ON PLAYER PROXIMITY 
	if(too_far):
		proximity_test.get_child(1).visible = false;
		proximity_test.get_child(0).visible = true;
	elif(hands_locked):
		proximity_test.get_child(0).visible = false;
		proximity_test.get_child(1).visible = true;
	else:
		proximity_test.get_child(0).visible = false;
		proximity_test.get_child(1).visible = false;

	if(proximity_test.get_child(0).visible):
		proximity_test.modulate.a = cos(Time.get_ticks_msec() * delta / 2);
	elif(!proximity_test.modulate.a == 1):
		proximity_test.modulate.a = 1;


func map(value : float, minA : float, maxA : float, minB : float, maxB : float) -> float:
	var m_range : float = maxA - minA;
	var valuePercent : float = (value - minA) / m_range;

	var newRange : float = maxB - minB;

	return valuePercent * newRange + minB;
