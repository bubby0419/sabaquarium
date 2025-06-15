# FishIcon.gd
extends TextureRect

signal drag_started(data)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

func _get_drag_data(at_position: Vector2) -> Variant:
	print("_get_drag_data")

	var preview = TextureRect.new()
	preview.texture = texture
	preview.expand_mode = expand_mode
	preview.stretch_mode = stretch_mode
	preview.size = size
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_drag_preview(preview)

	return { "type": "fish_icon" }

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	return false

func _drop_data(at_position: Vector2, data: Variant) -> void:
	pass
