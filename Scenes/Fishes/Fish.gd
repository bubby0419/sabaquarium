extends Area2D
class_name Fish   # ← add this at the top

signal fish_selected(fish_node: Node2D)
signal fuse_request(fish_a: Fish, fish_b: Fish)
signal pop_coin(position: Vector2, variation_level: int)

@export var variation_level:    int           = 1
@export var next_variation_scene: PackedScene = null
@export var fusion_cost:        int           = 100

@export var Icon: TextureRect;

@export var size_ratio: float = 0.1
@export var size_variation: float = 0.2

@export var price: int = 100

@export var speed: float = 75.0
@export var speed_variation: float = 0.2

@export var wobble_amplitude: float = 2.0
@export var wobble_speed_ratio: float = 0.1   # wobble cycles per pixel/sec
@export var wobble_tilt_degrees: float = 5.0   # max tilt angle

@export var coin_interval_min: float = 5.0
@export var coin_interval_max: float = 7.0
@export var coin_probability: float = 0.5
@export var threshold: int = 64


var spawn_time: float

var _base_speed: float

var half_extent: Vector2

var wobble_speed: float = 0.0
var wobble_time: float = 0.0

var direction: Vector2 = Vector2.ZERO

var base_sprite_offset: Vector2

const DRAG_THRESHOLD := 8
var _dragging: bool = false
var _drag_waiting := false

var _drag_start_pos := Vector2.ZERO
var _drag_offset := Vector2.ZERO

func _ready() -> void:
	input_pickable = true
	
	if !spawn_time:
		spawn_time = Time.get_unix_time_from_system()
	
	var screen_w = get_viewport().get_visible_rect().size.x
	var tex_w    = $Sprite.texture.get_width()
	var base     = (screen_w * size_ratio) / tex_w
	_base_speed = speed

	var factor   = randf_range(1.0 - size_variation, 1.0 + size_variation)
	self.scale   = Vector2.ONE * base * factor

	var effective_scale = self.scale * $Sprite.scale
	half_extent = Vector2(
		$Sprite.texture.get_width(),
		$Sprite.texture.get_height()
	) * 0.5 * effective_scale

	base_sprite_offset = $Sprite.position
	_apply_speed_variation()
	if has_node("WanderTimer"):
		$WanderTimer.timeout.connect(Callable(self, "_on_wander_timer_timeout"))
	if has_node("CoinTimer"):
		$CoinTimer.one_shot = true
		$CoinTimer.timeout.connect(Callable(self, "_on_CoinTimer_timeout"))
		_schedule_coin_timer()

	_on_wander_timer_timeout()

func _process(delta: float) -> void:
	position += direction * speed * delta

	var rect   = get_viewport().get_visible_rect()
	var origin = rect.position
	var size   = rect.size

	var min_x = origin.x + half_extent.x
	var max_x = origin.x + size.x  - half_extent.x
	var min_y = origin.y + half_extent.y + wobble_amplitude
	var max_y = origin.y + size.y  - half_extent.y - wobble_amplitude - threshold

	if position.x < min_x:
		position.x = min_x; direction.x = abs(direction.x)
	elif position.x > max_x:
		position.x = max_x; direction.x = -abs(direction.x)

	if position.y < min_y:
		position.y = min_y; direction.y = abs(direction.y)
	elif position.y > max_y:
		position.y = max_y; direction.y = -abs(direction.y)

	$Sprite.flip_h = direction.x < 0

	# Wobble
	wobble_time += delta
	var bob = sin(wobble_time * wobble_speed) * wobble_amplitude
	# since we've rotated the parent Node2D, local Y = world perpendicular
	$Sprite.position = base_sprite_offset + Vector2(0, bob)
	
	var max_tilt = deg_to_rad(wobble_tilt_degrees)
	$Sprite.rotation = sin(wobble_time * wobble_speed) * max_tilt
	
	var mp = get_viewport().get_mouse_position()

	# Only promote to dragging here, never clear _drag_waiting:
	if _drag_waiting and not _dragging and mp.distance_to(_drag_start_pos) > DRAG_THRESHOLD:
		_dragging     = true
		_drag_waiting = false
		_drag_offset  = global_position - mp
		get_viewport().set_input_as_handled()

	if _dragging:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			global_position = mp + _drag_offset
			get_viewport().set_input_as_handled()
		else:
			_dragging = false
			_try_fuse()

func _input_event(_viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_drag_waiting = true
			_drag_start_pos   = get_viewport().get_mouse_position()
			get_viewport().set_input_as_handled()
		else:
			if _dragging:
				_dragging = false
				_try_fuse()
			elif _drag_waiting:
				print("FISH SELECTED")
				emit_signal("fish_selected", self)
			_drag_waiting = false
			get_viewport().set_input_as_handled()
		return

func _apply_speed_variation() -> void:
	# random ±variation around base speed
	var factor = randf_range(1.0 - speed_variation, 1.0 + speed_variation)
	speed = speed * factor
	# now scale wobble_speed to match
	wobble_speed = speed * wobble_speed_ratio

func _on_wander_timer_timeout() -> void:
	direction = Vector2(
		randf_range(-1.0, 1.0),
		randf_range(-1.0, 1.0)
	).normalized()
	_apply_speed_variation()

func _schedule_coin_timer() -> void:
	# pick a random interval, then start the one-shot timer
	var t = randf_range(coin_interval_min, coin_interval_max)
	$CoinTimer.wait_time = t
	$CoinTimer.start()

func _on_CoinTimer_timeout() -> void:
	if randf() < coin_probability:
		emit_signal("pop_coin", global_position, variation_level)
	_schedule_coin_timer()

func _try_fuse() -> void:
	var params = PhysicsPointQueryParameters2D.new()
	params.position = global_position
	params.collide_with_areas = true
	params.collide_with_bodies = false
	# exclude yourself by RID
	params.exclude = [get_rid()]
	# look for another fish of same variation at drop point
	var space = get_world_2d().direct_space_state
	var results = space.intersect_point(params)
	for hit in results:
		var other = hit.collider
		if other is Fish and other.variation_level == variation_level:
			emit_signal("fuse_request", self, other)
			return
