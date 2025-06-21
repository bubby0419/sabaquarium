extends Control

@export var menu_scene_path: String 
func _ready() -> void:
	$VBoxContainer/RichText.bbcode_text = \
	"Version 0.2: " + \
	"\n - Two types of fishies" + \
	"\n - Data is automatically saved! You can come back to your fishies." + \
	"\n - You can delete your previous data from the options menu." + \
	"\n" + \
	"\nSABA: SABA [url=https://www.youtube.com/watch?v=k3cryiz8nJo]Youtube[/url]" + \
	"\nSound Effect by [url=https://pixabay.com/users/richardmultimedia-20862125/?utm_source=link-attribution&utm_medium=referral&utm_campaign=music&utm_content=250310]Richard Multimedia[/url] " + \
	"from [url=https://pixabay.com/sound-effects//?utm_source=link-attribution&utm_medium=referral&utm_campaign=music&utm_content=250310]Pixabay[/url] " + \
	"\nAssets by [url=https://www.kenney.nl]Kenney[/url]"
	"\nCrab Emote by Saba's Fish Tank Discord Server" + \
	
	$VBoxContainer/BackButton.pressed.connect(Callable(self, "_on_back_pressed"))

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(menu_scene_path)
