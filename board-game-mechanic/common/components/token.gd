# token.gd
# 通用代幣元件

extends Area2D
class_name Token

signal token_selected(token: Token)
signal token_moved(token: Token, new_position: Vector2)
signal token_removed(token: Token)
signal token_clicked(token: Token)

@export var token_name: String = "Token"
@export var token_value: int = 1
@export var token_type: String = "generic"
@export var is_selectable: bool = true
@export var is_movable: bool = true
@export var is_removable: bool = true

@onready var background: ColorRect = $Background
@onready var value_label: Label = $CenterContainer/ValueLabel
@onready var highlight: ColorRect = $Highlight
@onready var tween: Tween

var original_position: Vector2
var is_selected: bool = false
var is_dragging: bool = false
var owner_index: int = 0
var grid_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	# 設定初始外觀
	update_appearance()
	
	# 連接信號
	connect("mouse_entered", _on_mouse_entered)
	connect("mouse_exited", _on_mouse_exited)
	
	# 設定碰撞形狀
	var collision_shape = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = Constants.GAME_SETTINGS.TOKEN_SIZE / 2.0
	collision_shape.shape = shape
	add_child(collision_shape)

func update_appearance() -> void:
	# 設定背景顏色（圓形，使用 set_deferred 避免非相等對立錨點警告）
	background.set_deferred("color", Constants.get_player_color(owner_index))
	
	# 設定文字
	value_label.text = str(token_value)
	value_label.add_theme_color_override("font_color", Constants.COLORS.TEXT)
	
	# 設定高亮
	highlight.set_deferred("color", Constants.COLORS.BUTTON)
	highlight.modulate.a = 0.0

func select() -> void:
	if not is_selectable:
		return
	
	is_selected = true
	token_selected.emit(self)
	token_clicked.emit(self)  # 發射點擊信號
	animate_selection()

func deselect() -> void:
	is_selected = false
	animate_deselection()

func move_to(new_position: Vector2) -> void:
	if not is_movable:
		return
	
	original_position = position
	animate_move(new_position)
	token_moved.emit(self, new_position)

func remove() -> void:
	if not is_removable:
		return
	
	animate_remove()
	token_removed.emit(self)

func animate_selection() -> void:
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), Constants.GAME_SETTINGS.ANIMATION_DURATION)
	tween.tween_property(highlight, "modulate:a", 0.3, Constants.GAME_SETTINGS.ANIMATION_DURATION)
	tween.tween_property(self, "z_index", 10, Constants.GAME_SETTINGS.ANIMATION_DURATION)

func animate_deselection() -> void:
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), Constants.GAME_SETTINGS.ANIMATION_DURATION)
	tween.tween_property(highlight, "modulate:a", 0.0, Constants.GAME_SETTINGS.ANIMATION_DURATION)
	tween.tween_property(self, "z_index", 0, Constants.GAME_SETTINGS.ANIMATION_DURATION)

func animate_move(target_position: Vector2) -> void:
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position", target_position, Constants.GAME_SETTINGS.ANIMATION_DURATION)
	tween.tween_property(self, "scale", Vector2(1.1, 1.1), Constants.GAME_SETTINGS.ANIMATION_DURATION * 0.5)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), Constants.GAME_SETTINGS.ANIMATION_DURATION * 0.5).set_delay(Constants.GAME_SETTINGS.ANIMATION_DURATION * 0.5)

func animate_remove() -> void:
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, Constants.GAME_SETTINGS.ANIMATION_DURATION)
	tween.tween_property(self, "scale", Vector2(0.5, 0.5), Constants.GAME_SETTINGS.ANIMATION_DURATION)
	tween.tween_callback(queue_free).set_delay(Constants.GAME_SETTINGS.ANIMATION_DURATION)

func _on_mouse_entered() -> void:
	if not is_selected:
		if tween:
			tween.kill()
		
		tween = create_tween()
		tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.1)
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
			else:
				# 處理拖放
				if is_dragging:
					is_dragging = false
					move_to(get_global_mouse_position())

func _process(_delta: float) -> void:
	if is_dragging:
		position = get_global_mouse_position()

# 工具函數
func set_token_owner(player_index: int) -> void:
	owner_index = player_index
	background.set_deferred("color", Constants.get_player_color(player_index))
	update_appearance()

func set_value(new_value: int) -> void:
	token_value = new_value
	value_label.text = str(token_value)

func set_type(new_type: String) -> void:
	token_type = new_type
	# 根據類型設定顏色（使用 set_deferred）
	match token_type:
		"resource":
			background.set_deferred("color", Constants.COLORS.RESOURCE_GOLD)
		"victory":
			background.set_deferred("color", Constants.COLORS.BUTTON)
		"action":
			background.set_deferred("color", Constants.COLORS.PLAYER_1)
		_:
			background.set_deferred("color", Constants.get_player_color(owner_index))
