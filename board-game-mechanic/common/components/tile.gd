# tile.gd
# 通用板塊元件

extends Area2D
class_name Tile

signal tile_selected(tile: Tile)
signal tile_placed(tile: Tile, position: Vector2)
signal tile_rotated(tile: Tile, rotation: float)
signal tile_flipped(tile: Tile, flipped: bool)

@export var tile_name: String = "Tile"
@export var tile_type: String = "generic"
@export var tile_value: int = 0
@export var can_rotate: bool = true
@export var can_flip: bool = true
@export var can_select: bool = true
@export var rotation_steps: int = 4  # 0, 90, 180, 270 degrees

@onready var background: ColorRect = $Background
@onready var name_label: Label = $Content/NameLabel
@onready var value_label: Label = $Content/ValueLabel
@onready var highlight: ColorRect = $Highlight
@onready var grid_lines: Node2D = $GridLines
@onready var tween: Tween

var original_position: Vector2
var original_rotation: float
var is_selected: bool = false
var current_rotation_index: int = 0
var is_flipped: bool = false
var grid_position: Vector2i = Vector2i(0, 0)

func _ready() -> void:
	# 設定初始外觀
	update_appearance()
	
	# 連接信號
	connect("mouse_entered", _on_mouse_entered)
	connect("mouse_exited", _on_mouse_exited)
	
	# 設定碰撞形狀
	var collision_shape = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(Constants.GAME_SETTINGS.TILE_SIZE, Constants.GAME_SETTINGS.TILE_SIZE)
	collision_shape.shape = shape
	add_child(collision_shape)
	
	# 繪製網格線
	draw_grid_lines()

func update_appearance() -> void:
	# 設定背景顏色（使用 set_deferred 避免非相等對立錨點警告）
	background.set_deferred("color", Constants.COLORS.PANEL.darkened(0.1))
	
	# 設定文字
	name_label.text = tile_name
	value_label.text = str(tile_value)
	
	# 根據類型設定顏色（使用 set_deferred）
	match tile_type:
		"land":
			background.set_deferred("color", Color("#8B4513"))  # 棕色
		"water":
			background.set_deferred("color", Color("#1E90FF"))  # 藍色
		"forest":
			background.set_deferred("color", Color("#228B22"))  # 綠色
		"mountain":
			background.set_deferred("color", Color("#808080"))  # 灰色
		"road":
			background.set_deferred("color", Color("#D2691E"))  # 橙色
		_:
			background.set_deferred("color", Constants.COLORS.PANEL.darkened(0.1))
	
	# 設定高亮
	highlight.set_deferred("color", Constants.COLORS.BUTTON)
	highlight.modulate.a = 0.0

func draw_grid_lines() -> void:
	# 清除現有線條
	for child in grid_lines.get_children():
		child.queue_free()
	
	# 繪製邊框
	var border = Line2D.new()
	border.points = PackedVector2Array([
		Vector2(0, 0),
		Vector2(Constants.GAME_SETTINGS.TILE_SIZE, 0),
		Vector2(Constants.GAME_SETTINGS.TILE_SIZE, Constants.GAME_SETTINGS.TILE_SIZE),
		Vector2(0, Constants.GAME_SETTINGS.TILE_SIZE),
		Vector2(0, 0)
	])
	border.width = 2
	border.default_color = Constants.COLORS.GRID_LINE
	grid_lines.add_child(border)
	
	# 繪製內部網格線（如果需要的話）
	var inner_line = Line2D.new()
	inner_line.points = PackedVector2Array([
		Vector2(Constants.GAME_SETTINGS.TILE_SIZE / 2.0, 0),
		Vector2(Constants.GAME_SETTINGS.TILE_SIZE / 2.0, Constants.GAME_SETTINGS.TILE_SIZE)
	])
	inner_line.width = 1
	inner_line.default_color = Constants.COLORS.GRID_LINE.darkened(0.5)
	grid_lines.add_child(inner_line)
	
	var inner_line2 = Line2D.new()
	inner_line2.points = PackedVector2Array([
		Vector2(0, Constants.GAME_SETTINGS.TILE_SIZE / 2.0),
		Vector2(Constants.GAME_SETTINGS.TILE_SIZE, Constants.GAME_SETTINGS.TILE_SIZE / 2.0)
	])
	inner_line2.width = 1
	inner_line2.default_color = Constants.COLORS.GRID_LINE.darkened(0.5)
	grid_lines.add_child(inner_line2)

func select() -> void:
	if not can_select:
		return
	
	is_selected = true
	tile_selected.emit(self)
	animate_selection()

func deselect() -> void:
	is_selected = false
	animate_deselection()

func place_at(new_position: Vector2, grid_pos: Vector2i) -> void:
	grid_position = grid_pos
	animate_place(new_position)
	tile_placed.emit(self, new_position)

func rotate_tile() -> void:
	if not can_rotate:
		return
	
	current_rotation_index = (current_rotation_index + 1) % rotation_steps
	var target_rotation = deg_to_rad(current_rotation_index * 90.0)
	animate_rotate(target_rotation)
	tile_rotated.emit(self, target_rotation)

func flip_tile() -> void:
	if not can_flip:
		return
	
	is_flipped = not is_flipped
	var target_scale = Vector2(-1 if is_flipped else 1, 1)
	animate_flip(target_scale)
	tile_flipped.emit(self, is_flipped)

func animate_selection() -> void:
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.1, 1.1), Constants.GAME_SETTINGS.ANIMATION_DURATION)
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

func animate_place(target_position: Vector2) -> void:
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position", target_position, Constants.GAME_SETTINGS.ANIMATION_DURATION)
	tween.tween_property(self, "scale", Vector2(1.05, 1.05), Constants.GAME_SETTINGS.ANIMATION_DURATION * 0.5)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), Constants.GAME_SETTINGS.ANIMATION_DURATION * 0.5).set_delay(Constants.GAME_SETTINGS.ANIMATION_DURATION * 0.5)

func animate_rotate(target_rotation: float) -> void:
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "rotation", target_rotation, Constants.GAME_SETTINGS.ANIMATION_DURATION)
	tween.tween_property(self, "scale", Vector2(1.05, 1.05), Constants.GAME_SETTINGS.ANIMATION_DURATION * 0.5)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), Constants.GAME_SETTINGS.ANIMATION_DURATION * 0.5).set_delay(Constants.GAME_SETTINGS.ANIMATION_DURATION * 0.5)

func animate_flip(target_scale: Vector2) -> void:
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", target_scale, Constants.GAME_SETTINGS.ANIMATION_DURATION)
	tween.tween_property(self, "scale:y", 1.05, Constants.GAME_SETTINGS.ANIMATION_DURATION * 0.5)
	tween.tween_property(self, "scale:y", 1.0, Constants.GAME_SETTINGS.ANIMATION_DURATION * 0.5).set_delay(Constants.GAME_SETTINGS.ANIMATION_DURATION * 0.5)

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
	if not can_select:
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			select()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if can_rotate:
				rotate_tile()
		elif event.button_index == MOUSE_BUTTON_MIDDLE and event.pressed:
			if can_flip:
				flip_tile()

# 工具函數
func set_grid_position(x: int, y: int) -> void:
	grid_position = Vector2i(x, y)
	# 更新顯示（可選）
	name_label.text = "%s (%d,%d)" % [tile_name, x, y]

func set_tile_data(data: Dictionary) -> void:
	if "name" in data:
		tile_name = data.name
	if "type" in data:
		tile_type = data.type
	if "value" in data:
		tile_value = data.value
	if "can_rotate" in data:
		can_rotate = data.can_rotate
	if "can_flip" in data:
		can_flip = data.can_flip
	
	update_appearance()

func get_tile_rotation_degrees() -> float:
	return rad_to_deg(rotation)

func reset_transform() -> void:
	rotation = 0
	scale = Vector2(1, 1)
	current_rotation_index = 0
	is_flipped = false
