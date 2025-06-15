extends Node2D

signal pop_coin(position: Vector2)

@export var size_ratio: float = 0.1
@export var size_variation: float = 0.2

@export var price: int = 100

@export var speed: float = 50.0
@export var wobble_amplitude: float = 5.0
@export var wobble_speed: float = 3.0
@export var coin_interval: float = 5.0

var direction: Vector2 = Vector2.ZERO
var wobble_time: float = 0.0
var base_sprite_y: float
var half_extent: Vector2

func _ready() -> void:
	var screen_w = get_viewport().get_visible_rect().size.x
	var tex_w    = $Sprite.texture.get_width()
	var base     = (screen_w * size_ratio) / tex_w

	var factor   = randf_range(1.0 - size_variation, 1.0 + size_variation)
	self.scale   = Vector2.ONE * base * factor

	var effective_scale = self.scale * $Sprite.scale
	half_extent = Vector2(
		$Sprite.texture.get_width(),
		$Sprite.texture.get_height()
	) * 0.5 * effective_scale

	base_sprite_y = $Sprite.position.y

	if has_node("WanderTimer"):
		$WanderTimer.timeout.connect(Callable(self, "_on_wander_timer_timeout"))
	if has_node("CoinTimer"):
		$CoinTimer.wait_time = coin_interval
		$CoinTimer.one_shot   = false
		$CoinTimer.autostart  = true
		$CoinTimer.timeout.connect(Callable(self, "_on_CoinTimer_timeout"))

	_on_wander_timer_timeout()

func _process(delta: float) -> void:
	position += direction * speed * delta

	var rect   = get_viewport().get_visible_rect()
	var origin = rect.position
	var size   = rect.size

	var min_x = origin.x + half_extent.x
	var max_x = origin.x + size.x  - half_extent.x
	var min_y = origin.y + half_extent.y + wobble_amplitude
	var max_y = origin.y + size.y  - half_extent.y - wobble_amplitude

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
	$Sprite.position.y = base_sprite_y + sin(wobble_time * wobble_speed) * wobble_amplitude

func _on_wander_timer_timeout() -> void:
	direction = Vector2(
		randf_range(-1.0, 1.0),
		randf_range(-1.0, 1.0)
	).normalized()

func _on_CoinTimer_timeout() -> void:
	emit_signal("pop_coin", global_position)
