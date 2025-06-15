extends Control

@export var menu_scene_path: String

const MIN_DB := -40.0

@onready var slider = $Panel/VBoxContainer/VolumeSlider
@onready var label  = $Panel/VBoxContainer/VolumeLabel
@onready var back   = $Panel/VBoxContainer/BackButton

func _ready() -> void:
	back.pressed.connect(Callable(self, "_on_back_pressed"))
	slider.value_changed.connect(Callable(self, "_on_slider_value_changed"))

	var bus = AudioServer.get_bus_index("Master")
	var current_db = AudioServer.get_bus_volume_db(bus)
	var pct = clamp((current_db - MIN_DB) / -MIN_DB * 100.0, 0.0, 100.0)
	slider.value = pct
	_update_label(pct)

func _on_slider_value_changed(pct: float) -> void:
	var db = lerp(MIN_DB, 0.0, pct / 100.0)
	var bus = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus, db)
	_update_label(pct)

func _update_label(pct: float) -> void:
	label.text = "Volume: %d%%" % pct

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(menu_scene_path)
