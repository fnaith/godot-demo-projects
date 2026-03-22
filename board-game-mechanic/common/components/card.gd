# card.gd
# 通用卡牌元件

extends Area2D
class_name Card

signal card_selected(card: Card)
signal card_played(card: Card)
signal card_dragged(card: Card, position: Vector2)
signal card_dropped(card: Card, position: Vector2)

@export var card_name: String = "Card"
@export var card_type: String = Constants.CARD_TYPES.ACTION
@export var card_cost: int = 0
@export var card_value: int = 0
@export var card_description: String = ""
@export var is_playable: bool = true
@export var is_draggable: bool = true
@export var is_selectable: bool = true

@onready var background: ColorRect = $Background
@onready var name_label: Label = $NameLabel
@onready var cost_label: Label = $CostLabel
@onready var value_label: Label = $ValueLabel
@onready var description_label: Label = $DescriptionLabel
@onready var highlight: ColorRect = $Highlight
@onready var tween: Tween

var original_position: Vector2
var original_z_index: int
var is_selected: bool = false
var is_dragging: bool = false
var is_in_hand: bool = true
var owner_index: int = 0

func _ready() -> void:
	# 初始化節點
	# 注意：不在 _ready() 中創建 Tween，而是在需要時創建
	
	# 設定初始外觀
	update_appearance()
	
	# 連接信號
	connect("mouse_entered", _on_mouse_entered)
	connect("mouse_exited", _on_mouse_exited)
	
	# 設定碰撞形狀
	var collision_shape = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(Constants.GAME_SETTINGS.CARD_WIDTH, Constants.GAME_SETTINGS.CARD_HEIGHT)
	collision_shape.shape = shape
	add_child(collision_shape)

func update_appearance() -> void:
	# 設定背景顏色
	background.color = Constants.COLORS.CARD
	
	# 設定文字
	name_label.text = card_name
	cost_label.text = "Cost: %d" % card_cost
	value_label.text = "Value: %d" % card_value
	description_label.text = card_description
	
	# 根據卡牌類型設定顏色
	match card_type:
		Constants.CARD_TYPES.ACTION:
			name_label.add_theme_color_override("font_color", Color("#ff6b6b"))
		Constants.CARD_TYPES.RESOURCE:
			name_label.add_theme_color_override("font_color", Color("#4ecdc4"))
		Constants.CARD_TYPES.VICTORY:
			name_label.add_theme_color_override("font_color", Color("#ffe66d"))
		Constants.CARD_TYPES.SPECIAL:
			name_label.add_theme_color_override("font_color", Color("#95e1d3"))
	
	# 設定高亮
	highlight.color = Constants.COLORS.BUTTON
	highlight.modulate.a = 0.0
	
	# 設定尺寸
	background.size = Vector2(Constants.GAME_SETTINGS.CARD_WIDTH, Constants.GAME_SETTINGS.CARD_HEIGHT)

func select() -> void:
	if not is_selectable:
		return
	
	is_selected = true
	card_selected.emit(self)
	animate_selection()

func deselect() -> void:
	is_selected = false
	animate_deselection()

func play() -> void:
	if not is_playable:
		return
	
	card_played.emit(self)
	animate_play()

func discard() -> void:
	animate_discard()

func animate_selection() -> void:
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.1, 1.1), Constants.GAME_SETTINGS.ANIMATION_DURATION)
	tween.tween_property(highlight, "modulate:a", 0.3, Constants.GAME_SETTINGS.ANIMATION_DURATION)
	tween.tween_property(self, "z_index", original_z_index + 10, Constants.GAME_SETTINGS.ANIMATION_DURATION)

func animate_deselection() -> void:
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), Constants.GAME_SETTINGS.ANIMATION_DURATION)
	tween.tween_property(highlight, "modulate:a", 0.0, Constants.GAME_SETTINGS.ANIMATION_DURATION)
	tween.tween_property(self, "z_index", original_z_index, Constants.GAME_SETTINGS.ANIMATION_DURATION)

func animate_play() -> void:
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, Constants.GAME_SETTINGS.ANIMATION_DURATION * 2)
	tween.tween_property(self, "scale", Vector2(0.5, 0.5), Constants.GAME_SETTINGS.ANIMATION_DURATION * 2)
	tween.tween_callback(queue_free).set_delay(Constants.GAME_SETTINGS.ANIMATION_DURATION * 2)

func animate_discard() -> void:
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "rotation", PI / 4, Constants.GAME_SETTINGS.ANIMATION_DURATION)
	tween.tween_property(self, "modulate:a", 0.5, Constants.GAME_SETTINGS.ANIMATION_DURATION)
	tween.tween_property(self, "position:y", position.y + 100, Constants.GAME_SETTINGS.ANIMATION_DURATION)

func _on_mouse_entered() -> void:
	if not is_selected:
		if tween:
			tween.kill()
		
		tween = create_tween()
		tween.tween_property(self, "scale", Vector2(1.05, 1.05), 0.1)
		tween.tween_property(highlight, "modulate:a", 0.1, 0.1)

func _on_mouse_exited() -> void:
	if not is_selected:
		if tween:
			tween.kill()
		
		tween = create_tween()
		tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)
		tween.tween_property(highlight, "modulate:a", 0.0, 0.1)

func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if not is_selectable:
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				select()
				if is_draggable:
					is_dragging = true
					original_position = global_position
					original_z_index = z_index
					z_index = 100  # 拖曳時置頂
			else:
				# 處理拖放
				if is_dragging:
					is_dragging = false
					card_dropped.emit(self, global_position)

func _process(_delta: float) -> void:
	if is_dragging:
		card_dragged.emit(self, get_global_mouse_position())

# 工具函數
func set_card_owner(player_index: int) -> void:
	owner_index = player_index
	background.color = Constants.get_player_color(player_index).darkened(0.3)

func set_card_data(data: Dictionary) -> void:
	if "name" in data:
		card_name = data.name
	if "type" in data:
		card_type = data.type
	if "cost" in data:
		card_cost = data.cost
	if "value" in data:
		card_value = data.value
	if "description" in data:
		card_description = data.description
	
	update_appearance()
