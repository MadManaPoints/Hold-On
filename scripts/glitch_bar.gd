extends AnimatedSprite2D

@export var mat_shader : ShaderMaterial
var holding_hands : bool

@onready var anim : AnimationPlayer = $AnimationPlayer
var stop_pulse : bool 


func _process(_delta : float) -> void:
	#mat_shader.set_shader_parameter("limit", cos(Engine.get_frames_drawn()))
	if holding_hands:
		mat_shader.set_shader_parameter("speed", 0.6)
		if not stop_pulse:
			anim.play("Pulse")
			stop_pulse = true
	else:
		mat_shader.set_shader_parameter("speed", 0.2)
		stop_pulse = false
