extends Node2D

signal pop_coin(position: Vector2)

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

var _base_speed: float

var half_extent: Vector2

var wobble_speed: float = 0.0
var wobble_time: float = 0.0

var direction: Vector2 = Vector2.ZERO

var base_sprite_offset: Vector2

func _ready() -> void:
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

	#if direction.length() > 0:
	#	rotation = atan2(direction.y, abs(direction.x))
		
	# Wobble
	wobble_time += delta
	var bob = sin(wobble_time * wobble_speed) * wobble_amplitude
	# since we've rotated the parent Node2D, local Y = world perpendicular
	$Sprite.position = base_sprite_offset + Vector2(0, bob)
	
	var max_tilt = deg_to_rad(wobble_tilt_degrees)
	$Sprite.rotation = sin(wobble_time * wobble_speed) * max_tilt

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
		emit_signal("pop_coin", global_position)
	_schedule_coin_timer()
