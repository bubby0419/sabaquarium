extends Node2D

@export var menu_scene_path: String

@export var fish_scene: PackedScene     
@export var crab_scene: PackedScene 

var spawn_types: Array[PackedScene] = []

@export var coin_scene: PackedScene
@export var FISH_COST: int = 100
const BASE_FISH_COST_RATE := 0.20

var fish_inventory := { }  
var _last_inventory := {}

var owned_counts := {}

const COIN_VALUES = [10, 50, 100, 500]
const COIN_WEIGHTS_BY_LEVEL := {
	1: [1.0, 0.0, 0.0, 0.0],  
	2: [0.99, 0.01, 0.0, 0.0],  
	3: [0.62, 0.37, 0.01, 0.0],  
	4: [0.44, 0.33, 0.22, 0.01]
}

@export var coins: int = 100  

@onready var fish_container: Node2D = $FishContainer
@onready var coin_container: Node2D = $CoinContainer
@onready var coin_label: Label = $UI/CoinCount
@onready var fish_label: Label = $UI/FishCount
@onready var fish_bar_box = $UI/VBoxContainer/FishBarBox
@onready var fish_bar = $UI/VBoxContainer/FishBarBox/FishBar

func _ready() -> void:
	fish_bar_box.mouse_filter = Control.MOUSE_FILTER_PASS
	
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
	_restore_purchased_units(saved.get("spawned_fishes", []))
	_recompute_inventory()
	update_coin_ui()
	update_fish_count_ui()
	update_fish_bar()

func _save_state() -> void:
	var fishes = []
	for fish in fish_container.get_children():
		# get its variation scene path so we can re-instance the correct PackedScene
		var path = fish.scene_file_path
		fishes.append({
			"scene_path": path,
			"x": fish.global_position.x,
			"y": fish.global_position.y,
			"spawn_time": fish.spawn_time
		})
	var counts_by_path := {}
	for scene in owned_counts.keys():
		counts_by_path[scene.resource_path] = owned_counts[scene]
	var state = {
		"coins": coins,
		"owned_counts": counts_by_path,
		"spawned_fishes": fishes
	}
	SaveManager.save_game(state)

func _get_price(scene: PackedScene) -> int:
	var f = scene.instantiate()
	var base_price = f.price
	f.queue_free()
	var count = owned_counts.get(scene, 0)
	var price = base_price * (1.0 + count * BASE_FISH_COST_RATE)
	return int(price)

func _recompute_inventory() -> bool:
	fish_inventory.clear()
	var new_inventory := {}
	for scene in spawn_types:
		var price = _get_price(scene)
		new_inventory[scene] = coins / price
	var changed := false
	for scene in new_inventory.keys():
		if not _last_inventory.has(scene) or _last_inventory[scene] != new_inventory[scene]:
			changed = true
			break
	if changed:
		fish_inventory = new_inventory    # replace the old map
		_last_inventory = new_inventory.duplicate()
	return changed

func _on_coins_changed() -> void:
	update_coin_ui()
	var changed = _recompute_inventory()
	if changed:
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

func _get_weighted_coin_value(level: int) -> int:
	var weights = COIN_WEIGHTS_BY_LEVEL.get(level, COIN_WEIGHTS_BY_LEVEL[1])
	var r = randf()
	var cumulative = 0.0
	for i in COIN_VALUES.size():
		cumulative += weights[i]
		if r < cumulative:
			return COIN_VALUES[i]
	return COIN_VALUES.back()

func spawn_coin(at_pos: Vector2, level: int) -> void:
	var coin = coin_scene.instantiate()
	coin.position = at_pos
	coin.value = _get_weighted_coin_value(level)
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
	fish.connect("fuse_request", Callable(self, "_on_fuse_request"))
	fish.connect("fish_selected",  Callable(self, "_on_fish_selected"))
	fish_container.add_child(fish)
	owned_counts[scene] += 1
	_on_coins_changed()
	_save_state()

func _restore_purchased_units(list:Array) -> void:
	for c in fish_container.get_children():
		c.queue_free()
	var now = Time.get_unix_time_from_system()
	for entry in list:
		var p = entry["scene_path"] as String
		var scene = ResourceLoader.load(p) as PackedScene
		var age = entry.get("spawn_time", now)
		if scene:
			_spawn_unit_at(Vector2(entry["x"], entry["y"]), scene, age)

func _on_fuse_request(fish_a: Fish, fish_b: Fish) -> void:
	print("Trying fusion")
	# only fuse if there's a next_variation_scene
	if fish_a.variation_level != fish_b.variation_level:
		return
	if not fish_a.next_variation_scene:
		return
	
	var cost = fish_a.fusion_cost
	if coins < cost:
		_flash_red(fish_a)
		_flash_red(fish_b)
		return    #TODO error on not enough coins
	coins -= cost
	var pos = (fish_a.global_position + fish_b.global_position) * 0.5
	fish_a.queue_free()
	fish_b.queue_free()
	_spawn_unit_at(pos, fish_a.next_variation_scene)
	update_fish_count_ui()
	_on_coins_changed()
	_save_state()

func _flash_red(node: Node2D) -> void:
	# temporarily tint red and then tween back to white
	node.modulate = Color(1, 0, 0)
	var tw = node.create_tween()
	tw.tween_property(node, "modulate", Color(1, 1, 1), 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _spawn_unit_at(world_pos: Vector2, unit_scene: PackedScene, age: int = 0) -> void:
	var unit = unit_scene.instantiate()
	unit.position = world_pos
	unit.spawn_time = age
	unit.connect("pop_coin", Callable(self, "spawn_coin"))
	unit.connect("fuse_request", Callable(self, "_on_fuse_request"))
	unit.connect("fish_selected",  Callable(self, "_on_fish_selected"))
	fish_container.add_child(unit)

func _on_fish_selected(fish: Node2D) -> void:
	var panel = $UI/VBoxContainer/FishInfoPanel
	panel.visible = true
	
	# Icon
	var icon = fish.get("Icon")
	panel.get_node("VBoxContainer/Icon").texture = icon

	# Level / variation
	var level = fish.get("variation_level")
	panel.get_node("VBoxContainer/VariationLabel").text = "Level: %d" % level

	# Age = now – spawn_time
	var born = fish.get("spawn_time")
	var age_secs = int(Time.get_unix_time_from_system() - born)
	
	panel.get_node("VBoxContainer/AgeLabel").text = "Age: %02d seconds" % age_secs

	var cost = fish.fusion_cost
	panel.get_node("VBoxContainer/CostLabel").text      = "Fuse Cost: %d" % cost
	
	# Optionally move the panel near the fish:
	#var screen_pos = get_viewport().get_camera_2d().unproject_position(fish.global_position)
	#panel.rect_position = screen_pos + Vector2(20, -20)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var panel = $UI/VBoxContainer/FishInfoPanel
		if panel.visible:
			var bounds = panel.get_global_rect()
			if not bounds.has_point(event.position):
				panel.visible = false

func _on_back_pressed() -> void:
	_save_state()
	get_tree().change_scene_to_file(menu_scene_path)
