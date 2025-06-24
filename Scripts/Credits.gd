extends Control

@export var menu_scene_path: String 
func _ready() -> void:
	var bb = ""
	# — Changelog header —
	bb += "[center][font_size=18][b]Changelog[/b][/font_size][/center]\n\n"
	# — Version entries —
	bb += "[b]Version 0.3[/b]\n"
	bb += " - You can now fuse your fishies! Drag them into each other!\n"
	bb += " - Fish info panel on tap: See your fishies' ages, levels and fusion costs!\n"
	bb += " - Full save/load of fishies, levels & stats!\n"
	bb += " - Reworked the coin weight mechanic so fishes get better as you fuse them\n"
	bb += " - Improved drag and touch areas for mobile\n\n"
	bb += "[b]Version 0.2[/b]\n"
	bb += " - Two types of fishies:\n"
	bb += " - New KANI unit that auto‐collects coins in the bottom area!\n"
	bb += " - Data is automatically saved! You can come back to your fishies.\n"
	bb += " - You can delete your previous data from the options menu.\n\n"
	bb += "[b]Version 0.1[/b]\n"
	bb += " - Initial release: place fishie, collect coin.\n\n"

	# — Credits header —
	bb += "[center][font_size=18][b]Credits[/b][/font_size][/center]\n\n"
	# — Credits entries —
	bb += "SABA: SABA [url=https://www.youtube.com/watch?v=k3cryiz8nJo]YouTube[/url]\n"
	bb += "Sound Effect by [url=https://pixabay.com/users/richardmultimedia-20862125/]Richard Multimedia[/url] from [url=https://pixabay.com/sound-effects/]Pixabay[/url]\n"
	bb += "Assets by [url=https://www.kenney.nl]Kenney[/url]\n"
	bb += "Crab Emote and Hat by Saba's Fish Tank Discord Server\n"

	$VBoxContainer/ScrollContainer/RichText.bbcode_text = bb
	
	$VBoxContainer/BackButton.pressed.connect(Callable(self, "_on_back_pressed"))

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(menu_scene_path)
