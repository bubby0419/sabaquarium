extends Node2D

@export var menu_scene_path: String

@export var default_fish_scene: PackedScene     
@export var coin_scene: PackedScene
@export var FISH_COST: int = 100

var fish_inventory := { }  

const COIN_VALUES = [10, 50, 100, 500]
@export var coins: int = 100  

@onready var fish_container: Node2D = $FishContainer
@onready var coin_container: Node2D = $CoinContainer
@onready var coin_label: Label = $UI/CoinCount
@onready var fish_bar = $UI/FishBarBox/FishBar

func _ready() -> void:
	$UI/BackButton.pressed.connect(Callable(self, "_on_back_pressed"))
	_recompute_inventory()
	update_coin_ui()
	update_fish_bar()

func _get_price(fish_scene: PackedScene) -> int:
	var f = fish_scene.instantiate()
	var p = f.price
	f.queue_free()
	return p

func _recompute_inventory() -> void:
	fish_inventory.clear()
	var price = _get_price(default_fish_scene)
	fish_inventory[default_fish_scene] = coins / price

func _on_coins_changed() -> void:
	_recompute_inventory()
	update_coin_ui()
	update_fish_bar()

func update_coin_ui() -> void:
	coin_label.text = "Coins: %d" % coins

func update_fish_bar() -> void:
	for c in fish_bar.get_children():
		c.queue_free()
	for fish_scene in fish_inventory.keys():
		var count = fish_inventory[fish_scene]
		var item = preload("res://Scenes/FishBarItem.tscn").instantiate()
		item.fish_scene = fish_scene
		item.set_count(_get_price(fish_scene))
		fish_bar.add_child(item)

func attempt_place_fish(world_pos: Vector2, fish_scene: PackedScene) -> void:
	var price = _get_price(fish_scene)
	if coins < price:
		return
	coins -= price
	_on_coins_changed()
	spawn_fish_at(world_pos, fish_scene)


func spawn_coin(at_pos: Vector2) -> void:
	var coin = coin_scene.instantiate()
	coin.position = at_pos
	
	coin.value = COIN_VALUES[randi() % COIN_VALUES.size()]
	
	coin_container.add_child(coin)
	coin.connect("collected", Callable(self, "_on_coin_collected"))

func _on_coin_collected(coin_node) -> void:
	coins += coin_node.value
	_on_coins_changed()

func spawn_fish_at(world_pos: Vector2, fish_scene: PackedScene) -> void:
	var fish = fish_scene.instantiate()
	fish.position = world_pos
	fish.connect("pop_coin", Callable(self, "spawn_coin"))
	fish_container.add_child(fish)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(menu_scene_path)
