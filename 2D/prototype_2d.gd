extends Node2D


func _ready() -> void:
	SignalBus.player_dead.connect(_on_player_dead)
	SignalBus.player_dead.connect(_on_enemy_dead)

func _on_player_dead(param : float, param_2 : CharacterBody2D):
	var tween = get_tree().create_tween();
	tween.tween_property(param_2, "scale", Vector2(param, param), 5.0)

func _on_enemy_dead(param : int, param_2 : CharacterBody2D):
	pass
	
func _process(delta: float) -> void:
	print(Game.player_bmp);

func _on_player_2d_child_exiting_tree(node: Node) -> void:
	pass # Replace with function body.
