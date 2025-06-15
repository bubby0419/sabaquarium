extends Area2D

signal collected

@export var fall_speed: float = 100.0  
@export var lifetime:   float = 10.0 
@export var value:      int = 10  

var _age := 0.0
var stop_y: float
var has_landed := false
var sprite_node: Sprite2D

func _ready() -> void:
	input_pickable = true
	set_process(true)

	if has_node("Sprite2D"):
		sprite_node = $Sprite2D
	elif has_node("Sprite"):
		sprite_node = $Sprite
	else:
		push_error("Coin.gd: no Sprite2D or Sprite child found!")
		return

	var factor: float = 1.0
	match value:
		10:
			factor = 0.7
		50:
			factor = 0.8
		100:
			factor = 0.9
		500:
			factor = 1.0
		_:
			factor = 1.0
	scale = Vector2.ONE * factor

	match value:
		10:
			sprite_node.modulate = Color(0.9, 0.9, 0.9)
		50:
			sprite_node.modulate = Color(0,   1.0, 0)
		100:
			sprite_node.modulate = Color(0,   0,   1.0)
		500:
			sprite_node.modulate = Color(1.0, 0.8, 0)
		_:
			sprite_node.modulate = Color(1,1,1)

	var sh = get_viewport().get_visible_rect().size.y
	stop_y = sh - randf_range(10.0, 128.0)

func _process(delta: float) -> void:
	if not has_landed:
		position.y += fall_speed * delta
		if position.y >= stop_y:
			position.y = stop_y
			has_landed = true

	_age += delta
	if _age >= lifetime:
		queue_free()

func _input_event(_viewport, event, _shape_idx) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		emit_signal("collected", self)
		queue_free()
