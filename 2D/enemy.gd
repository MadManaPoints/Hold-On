extends CharacterBody2D

func _enemy_has_died():
	SignalBus.player_dead.emit(20, self)


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "Player2D":
		_enemy_has_died()
