extends PanelContainer

signal drag_started(data)

@export var fish_scene: PackedScene
var count: int = 0

@onready var icon = $HBoxContainer/Icon
@onready var label = $HBoxContainer/CountLabel as Label

func set_count(n: int) -> void:
	count = n
	if label:
		label.text = str(n)
	else:
		push_error("FishBarItem.gd: could not find CountLabel node!")

	if count <= 0:
		modulate = Color(0.6,0.6,0.6)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	else:
		modulate = Color(1,1,1,1)
		mouse_filter = Control.MOUSE_FILTER_STOP

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

func _get_drag_data(at_position: Vector2) -> Variant:
	if count <= 0:
		return null

	var preview_root = Control.new()
	preview_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var preview_icon = TextureRect.new()
	preview_icon.texture      = icon.texture
	preview_icon.expand       = true
	preview_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	preview_icon.size         = icon.size

	preview_icon.position = -icon.size * 0.5
	
	preview_root.add_child(preview_icon)
	set_drag_preview(preview_root)

	return {
		"type":       "fish_icon",
		"fish_scene": fish_scene
	}

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	return false
