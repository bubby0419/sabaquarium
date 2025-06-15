extends Control

@export var menu_scene_path: String 
func _ready() -> void:
	$VBoxContainer/RichText.bbcode_text = \
	"SABA: SABA [url=https://www.youtube.com/watch?v=k3cryiz8nJo]Youtube[/url]" + \
	"\n\nSound Effect by [url=https://pixabay.com/users/richardmultimedia-20862125/?utm_source=link-attribution&utm_medium=referral&utm_campaign=music&utm_content=250310]Richard Multimedia[/url] " + \
	"from [url=https://pixabay.com/sound-effects//?utm_source=link-attribution&utm_medium=referral&utm_campaign=music&utm_content=250310]Pixabay[/url] "
	$VBoxContainer/BackButton.pressed.connect(Callable(self, "_on_back_pressed"))

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(menu_scene_path)
