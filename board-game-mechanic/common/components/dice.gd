# dice.gd
# 通用骰子元件

extends Area2D
class_name Dice

signal dice_rolled(dice: Dice, result: int)
signal dice_selected(dice: Dice)
signal dice_stopped(dice: Dice)

@export var sides: int = 6
@export var current_value: int = 1
@export var is_rolling: bool = false
@export var can_roll: bool = true
@export var roll_speed: float = 10.0
@export var roll_duration: float = 1.5

@onready var background: ColorRect = $Background
@onready var value_label: Label = $ValueLabel
@onready var highlight: ColorRect = $Highlight
var tween: Tween = null

var original_position: Vector2
var original_rotation: float
var roll_start_time: float = 0.0
var roll_target_value: int = 1
var is_selected: bool = false

func _ready() -> void:
	# 初始化節點
	# 注意：不在 _ready() 中創建 Tween，只在需要時創建
	
	# 設定初始外觀
	update_appearance()
	
	# 連接信號
	connect("mouse_entered", _on_mouse_entered)
	connect("mouse_exited", _on_mouse_exited)
	
	# 設定碰撞形狀
	var collision_shape = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(Constants.GAME_SETTINGS.DICE_SIZE, Constants.GAME_SETTINGS.DICE_SIZE)
	collision_shape.shape = shape
	add_child(collision_shape)

func update_appearance() -> void:
	# 設定背景顏色
	background.color = Constants.COLORS.PANEL
	background.size = Vector2(Constants.GAME_SETTINGS.DICE_SIZE, Constants.GAME_SETTINGS.DICE_SIZE)
	
	# 設定文字
	value_label.text = str(current_value)
	value_label.add_theme_color_override("font_color", Constants.COLORS.TEXT)
	
	# 設定高亮
	highlight.color = Constants.COLORS.BUTTON
	highlight.modulate.a = 0.0
	highlight.size = Vector2(Constants.GAME_SETTINGS.DICE_SIZE, Constants.GAME_SETTINGS.DICE_SIZE)

func roll() -> void:
	if not can_roll or is_rolling:
		return
	
	is_rolling = true
	roll_start_time = Time.get_ticks_msec() / 1000.0
	roll_target_value = randi_range(1, sides)
	
	# 開始滾動動畫
	start_rolling_animation()
	
	# 設定定時器停止滾動
	var timer = get_tree().create_timer(roll_duration)
	timer.timeout.connect(_on_roll_complete)

func start_rolling_animation() -> void:
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.set_loops()
	tween.set_parallel(false)
	
	# 快速旋轉和縮放動畫
	for i in range(6):
		tween.tween_property(self, "rotation", rotation + PI/2, 0.1)
		tween.tween_property(self, "scale", Vector2(0.9, 0.9), 0.05)
		tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.05)
		tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.05)

func stop_rolling_animation() -> void:
	if tween:
		tween.kill()
	
	# 設定最終值
	current_value = roll_target_value
	update_appearance()
	
	# 最終彈跳動畫
	tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "rotation", 0, 0.2)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2)
	
	# 發送信號
	dice_rolled.emit(self, current_value)
	dice_stopped.emit(self)

func _on_roll_complete() -> void:
	is_rolling = false
	stop_rolling_animation()

func select() -> void:
	is_selected = true
	dice_selected.emit(self)
	animate_selection()

func deselect() -> void:
	is_selected = false
	animate_deselection()

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

func _on_mouse_entered() -> void:
	if not is_selected and not is_rolling:
		if tween:
			tween.kill()
		
		tween = create_tween()
		tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.1)
		tween.tween_property(highlight, "modulate:a", 0.1, 0.1)

func _on_mouse_exited() -> void:
	if not is_selected and not is_rolling:
		if tween:
			tween.kill()
		
		tween = create_tween()
		tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)
		tween.tween_property(highlight, "modulate:a", 0.0, 0.1)

func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if can_roll and not is_rolling:
				roll()
			else:
				select()

func _process(_delta: float) -> void:
	if is_rolling:
		# 在滾動過程中更新顯示的數字（視覺效果）
		var elapsed = Time.get_ticks_msec() / 1000.0 - roll_start_time
		var progress = elapsed / roll_duration
		
		# 快速變換數字
		if progress < 0.9:
			var random_value = randi_range(1, sides)
			value_label.text = str(random_value)
		else:
			# 最後顯示目標值
			value_label.text = str(roll_target_value)

# 工具函數
func set_sides(new_sides: int) -> void:
	sides = new_sides
	if current_value > sides:
		current_value = sides
	update_appearance()

func set_value(new_value: int) -> void:
	current_value = clamp(new_value, 1, sides)
	update_appearance()

func reset() -> void:
	current_value = 1
	is_rolling = false
	update_appearance()
	
	if tween:
		tween.kill()
	
	rotation = 0
	scale = Vector2(1.0, 1.0)

func get_dice_type() -> String:
	match sides:
		4: return "D4"
		6: return "D6"
		8: return "D8"
		10: return "D10"
		12: return "D12"
		20: return "D20"
		_: return "D%d" % sides
