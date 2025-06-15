extends Control

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS

func _can_drop_data(position: Vector2, data) -> bool:
	print("_can_drop_data")
	return data is Dictionary and data.get("type") == "fish_icon"

func _drop_data(position: Vector2, data) -> void:
	print("_drop_data")
	if data.get("type") != "fish_icon":
		return
	var cam = get_viewport().get_camera_2d()
	var world_pos = cam.unproject_position(position) if cam else position
	var main = get_tree().get_current_scene()
	if main and main.has_method("attempt_place_fish"):
		main.attempt_place_fish(world_pos, data["fish_scene"])
