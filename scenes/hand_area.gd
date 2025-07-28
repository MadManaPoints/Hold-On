extends RigidBody3D

@export var player_one : RigidBody3D;
@export var player_two : RigidBody3D;

var target_pos : Vector3;
var vel : Vector3;
var move_speed : float = 5.0;

var start_y_pos : float = 1.5;
var new_y_pos : float = 2.0;

var hands_up : bool;

func _ready() -> void:
	position.y = start_y_pos;


func _physics_process(delta: float) -> void:
	if(hands_up):
		if(position.y < new_y_pos):
			position.y += delta;
		else:
			position.y = new_y_pos;
	else:
		if(position.y > start_y_pos):
			position.y -= delta;
		else:
			position.y = start_y_pos;

	var center_pos := Vector3((player_one.position + player_two.position) / 2);
	target_pos = Vector3(center_pos.x, position.y, center_pos.z);

	if(position.distance_to(target_pos) > 0.1):
		var dir := Vector3(target_pos - position).normalized();
		var move := Vector3(dir * move_speed * delta);
		position += move;
	else:
		position = target_pos;


func _on_hand_center_area_entered(area: Area3D) -> void:
	if(area.name == "P1_Hand" && !Game.player_one_hand):
		Game.player_one_hand = true;

	if(area.name == "P2_Hand" && !Game.player_two_hand):
		Game.player_two_hand = true;


func _on_hand_center_area_exited(area: Area3D) -> void:
	if(area.name == "P1_Hand"):
		Game.player_one_hand = false;

	if(area.name == "P1_Hand"):
		Game.player_two_hand = false;
