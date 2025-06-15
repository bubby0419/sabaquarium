extends AudioStreamPlayer

func _ready() -> void:
	# load your converted OGG (or WAV) file here
	stream = preload("res://Assets/ocean-waves-250310.mp3")
	loop = true
	volume_db = 10.0           # adjust to taste
	pause_mode = Node.PAUSE_MODE_PROCESS
	play()
