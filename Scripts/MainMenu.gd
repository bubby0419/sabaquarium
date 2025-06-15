extends Control

@export var game_scene_path: String
@export var options_scene_path: String
@export var credits_scene_path: String

func _ready() -> void:
	$MenuVBox/StartButton.pressed.connect(Callable(self, "_on_start_pressed"))
	$MenuVBox/OptionsButton.pressed.connect(Callable(self, "_on_options_pressed"))
	$MenuVBox/CreditsButton.pressed.connect(Callable(self, "_on_credits_pressed"))

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file(game_scene_path)

func _on_options_pressed() -> void:
		get_tree().change_scene_to_file(options_scene_path)

func _on_credits_pressed() -> void:
	get_tree().change_scene_to_file(credits_scene_path)

