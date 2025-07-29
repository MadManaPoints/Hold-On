extends RigidBody3D

@export var player_one : RigidBody3D;
@export var player_two : RigidBody3D;

var target_pos : Vector3;
var vel : Vector3;
var move_speed : float = 200.0;

var hands_up : bool;

var start_y_pos : float;
var new_y_pos : float = 2.4;

func _ready() -> void:
	start_y_pos = self.position.y;

func _physics_process(delta: float) -> void:
	move_to_players(delta);
	move_up();


func move_up() -> void:
	if(hands_up):
		if(self.position.y < new_y_pos):
			self.linear_velocity.y = 1;
		else:
			self.linear_velocity.y = 0;
	else:
		if(self.position.y > start_y_pos):
			self.linear_velocity.y = -1;
		else:
			self.linear_velocity.y = 0;


func move_to_players(delta : float) -> void:
	var center_pos := Vector3((player_one.position + player_two.position) / 2);
	target_pos = Vector3(center_pos.x + 0.30, position.y, center_pos.z);

	if(position.distance_to(target_pos) > 0.05):
		var dir := Vector3(target_pos - position).normalized();
		var move := Vector3(dir * move_speed * delta);
		self.apply_central_force(move);
	else:
		linear_velocity = Vector3.ZERO;
		#position = target_pos;
