# back_button.gd
# 通用返回按鈕元件

extends Button
class_name BackButton

signal back_pressed

@export var target_scene: String = "res://main.tscn"
@export var transition_duration: float = 0.5
@export var show_confirmation: bool = false
@export var confirmation_message: String = "確定要返回主選單嗎？"

@onready var tween: Tween

func _ready() -> void:
	# 設定按鈕文字和樣式
	text = "← 返回"
	
	# 設定按鈕樣式
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = Constants.COLORS.BUTTON
	stylebox.border_width_left = 2
	stylebox.border_width_top = 2
	stylebox.border_width_right = 2
	stylebox.border_width_bottom = 2
	stylebox.border_color = Constants.COLORS.BUTTON.darkened(0.3)
	stylebox.corner_radius_top_left = 8
	stylebox.corner_radius_top_right = 8
	stylebox.corner_radius_bottom_right = 8
	stylebox.corner_radius_bottom_left = 8
	stylebox.expand_margin_left = 12.0
	stylebox.expand_margin_top = 8.0
	stylebox.expand_margin_right = 12.0
	stylebox.expand_margin_bottom = 8.0
	
	add_theme_stylebox_override("normal", stylebox)
	
	# 懸停樣式
	var hover_stylebox = stylebox.duplicate()
	hover_stylebox.bg_color = Constants.COLORS.BUTTON_HOVER
	add_theme_stylebox_override("hover", hover_stylebox)
	
	# 按下樣式
	var pressed_stylebox = stylebox.duplicate()
	pressed_stylebox.bg_color = Constants.COLORS.BUTTON.darkened(0.2)
	add_theme_stylebox_override("pressed", pressed_stylebox)
	
	# 文字顏色
	add_theme_color_override("font_color", Constants.COLORS.TEXT)
	add_theme_color_override("font_hover_color", Constants.COLORS.TEXT)
	add_theme_color_override("font_pressed_color", Constants.COLORS.TEXT.darkened(0.2))
	
	# 字體大小
	add_theme_font_size_override("font_size", 16)
	
	# 連接信號
	pressed.connect(_on_pressed)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_pressed() -> void:
	if show_confirmation:
		show_confirmation_dialog()
	else:
		go_back()

func go_back() -> void:
	# 播放按壓動畫
	animate_press()
	
	# 發送信號
	back_pressed.emit()
	
	# 切換場景（如果有目標場景）
	if target_scene and target_scene != "":
		await get_tree().create_timer(transition_duration * 0.5).timeout
		get_tree().change_scene_to_file(target_scene)

func show_confirmation_dialog() -> void:
	# 這裡可以實作確認對話框
	# 目前先直接返回
	go_back()

func animate_press() -> void:
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(0.95, 0.95), transition_duration * 0.3)
	tween.tween_property(self, "modulate", Color(0.8, 0.8, 0.8, 1.0), transition_duration * 0.3)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), transition_duration * 0.3).set_delay(transition_duration * 0.3)
	tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 1.0), transition_duration * 0.3).set_delay(transition_duration * 0.3)

func _on_mouse_entered() -> void:
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.05, 1.05), 0.1)

func _on_mouse_exited() -> void:
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)

# 工具函數
func set_target_scene(scene_path: String) -> void:
	target_scene = scene_path

func set_button_text(new_text: String) -> void:
	text = new_text

func enable_confirmation(enable: bool, message: String = "") -> void:
	show_confirmation = enable
	if message:
		confirmation_message = message

func set_position_in_corner(corner: String = "top_left") -> void:
	var viewport_size = get_viewport().get_visible_rect().size
	
	match corner:
		"top_left":
			position = Vector2(20, 20)
		"top_right":
			position = Vector2(viewport_size.x - size.x - 20, 20)
		"bottom_left":
			position = Vector2(20, viewport_size.y - size.y - 20)
		"bottom_right":
			position = Vector2(viewport_size.x - size.x - 20, viewport_size.y - size.y - 20)
		_:
			position = Vector2(20, 20)