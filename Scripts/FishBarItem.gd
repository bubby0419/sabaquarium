extends PanelContainer

signal drag_started(data)

@export var scene: PackedScene
@export var countLabel: Label
@export var priceLabel: Label
@export var icon: TextureRect
var count: int = 0
var price: int = 0

func _ready() -> void:
	_update_icon()
	mouse_filter = Control.MOUSE_FILTER_STOP

func set_price(_price: int) -> void:
	price = _price
	if priceLabel:
		priceLabel.text = str(price)

func set_count(_count: int) -> void:
	count = _count
	if countLabel:
		countLabel.text = str(count)
	else:
		push_error("FishBarItem.gd: could not find CountLabel node!")

	if count <= 0:
		modulate = Color(0.6,0.6,0.6)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	else:
		modulate = Color(1,1,1,1)
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
		"fish_scene": scene
	}

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	return false

func _update_icon() -> void:
	if not scene:
		return
	# Instance a temp fish to grab its texture/frame
	var fish = scene.instantiate()
	var tex: Texture2D = null

	if fish.has_node("Icon"):
		tex = fish.get_node("Icon").texture
	elif fish.has_node("AnimatedSprite2D"):
		var anim = fish.get_node("AnimatedSprite2D") as AnimatedSprite2D
		# grab first frame of the default animation
		var anim_name = anim.animation
		tex = anim.frames.get_frame(anim_name, 0)
	fish.queue_free()

	if tex:
		icon.texture = tex
