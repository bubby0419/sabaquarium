extends Node2D

@export var menu_scene_path: String

@export var fish_scene: PackedScene     
@export var crab_scene: PackedScene 

var spawn_types: Array[PackedScene] = []

@export var coin_scene: PackedScene
@export var FISH_COST: int = 100
const BASE_FISH_COST_RATE := 0.10 

var fish_inventory := { }  
var owned_counts := {}

const COIN_VALUES = [10, 50, 100, 500]
const COIN_WEIGHTS = [0.7, 0.2, 0.08, 0.02]  
@export var coins: int = 100  

@onready var fish_container: Node2D = $FishContainer
@onready var coin_container: Node2D = $CoinContainer
@onready var coin_label: Label = $UI/CoinCount
@onready var fish_label: Label = $UI/FishCount
@onready var fish_bar = $UI/FishBarBox/FishBar

func _ready() -> void:
	spawn_types = [fish_scene, crab_scene]
	var saved = SaveManager.load_game()
	print(saved)
	coins = int(saved.get("coins", coins))
	var counts_by_path = saved.get("owned_counts", {})
	
	owned_counts.clear()
	for s in spawn_types:
		var p = s.resource_path
		owned_counts[s] = counts_by_path[p] if counts_by_path.has(p) else 0

	$UI/BackButton.pressed.connect(Callable(self, "_on_back_pressed"))
	_restore_purchased_units()
	_recompute_inventory()
	update_coin_ui()
	update_fish_count_ui()
	update_fish_bar()

func _save_state() -> void:
	var counts_by_path := {}
	for scene in owned_counts.keys():
		counts_by_path[scene.resource_path] = owned_counts[scene]
	var state = {
		"coins": coins,
		"owned_counts": counts_by_path
	}
	print("to save: ", state)
	SaveManager.save_game(state)

func _get_price(scene: PackedScene) -> int:
	var f = scene.instantiate()
	var base_price = f.price
	f.queue_free()
	var count = owned_counts.get(scene, 0)
	var price = base_price * (1.0 + count * BASE_FISH_COST_RATE)
	return int(price)

func _recompute_inventory() -> void:
	fish_inventory.clear()
	for scene in spawn_types:
		var price = _get_price(scene)
		fish_inventory[scene] = coins / price

func _on_coins_changed() -> void:
	update_coin_ui()
	_recompute_inventory()
	update_fish_bar()

func update_coin_ui() -> void:
	coin_label.text = "Coins: %d" % coins

func update_fish_count_ui() -> void:
	fish_label.text = "Fishes: %d" % fish_container.get_child_count()

func update_fish_bar() -> void:
	for c in fish_bar.get_children():
		c.queue_free()
	for scene in fish_inventory.keys():
		var count = fish_inventory[scene]
		var item = preload("res://Scenes/FishBarItem.tscn").instantiate()
		item.scene = scene
		item.set_price(_get_price(scene))
		item.set_count(count)
		fish_bar.add_child(item)

func attempt_place_fish(world_pos: Vector2, scene: PackedScene) -> void:
	var price = _get_price(scene)
	if coins < price:
		return
	coins -= price
	spawn_fish_at(world_pos, scene)
	update_fish_count_ui()
	_on_coins_changed()

func _get_random_coin_value() -> int:
	var r = randf()
	var cumulative = 0.0
	for i in COIN_VALUES.size():
		cumulative += COIN_WEIGHTS[i]
		if r < cumulative:
			return COIN_VALUES[i]
	# fallback just in case of rounding
	return COIN_VALUES[COIN_VALUES.size() - 1]

func spawn_coin(at_pos: Vector2) -> void:
	var coin = coin_scene.instantiate()
	coin.position = at_pos
	
	coin.value = _get_random_coin_value()
	
	coin_container.add_child(coin)
	coin.connect("collected", Callable(self, "_on_coin_collected"))

func _on_coin_collected(coin_node) -> void:
	coins += coin_node.value
	_on_coins_changed()
	_save_state()

func spawn_fish_at(world_pos: Vector2, scene: PackedScene) -> void:
	var fish = scene.instantiate()
	fish.position = world_pos
	fish.connect("pop_coin", Callable(self, "spawn_coin"))
	fish_container.add_child(fish)
	owned_counts[scene] += 1
	_on_coins_changed()
	_save_state()

func _restore_purchased_units() -> void:
	var screen = get_viewport().get_visible_rect()

	for scene in spawn_types:
		var count = owned_counts.get(scene, 0)
		for i in range(count):
			# choose a random screen‐position:
			var pos: Vector2
			if scene == crab_scene:
				# anywhere under the bottom‐band
				var bottom_line_y = screen.position.y + screen.size.y - 64
				var x = randf_range(screen.position.x,
									screen.position.x + screen.size.x)
				var y = randf_range(bottom_line_y, screen.position.y + screen.size.y)
				pos = Vector2(x, y)
			else:
				# fish: anywhere on screen
				var x = randf_range(screen.position.x ,
									screen.position.x + screen.size.x)
				var y = randf_range(screen.position.y,
									screen.position.y + screen.size.y)
				pos = Vector2(x, y)

			_spawn_unit_restore(pos, scene)

func _spawn_unit_restore(world_pos: Vector2, unit_scene: PackedScene) -> void:
	var unit = unit_scene.instantiate()
	unit.position = world_pos
	unit.connect("pop_coin", Callable(self, "spawn_coin"))
	fish_container.add_child(unit)

func _on_back_pressed() -> void:
	_save_state()
	get_tree().change_scene_to_file(menu_scene_path)
