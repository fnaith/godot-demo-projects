# info_panel.gd
# 通用資訊面板元件

extends Panel
class_name InfoPanel

signal panel_closed
signal panel_opened

@export var panel_title: String = "資訊面板"
@export var auto_show: bool = false
@export var show_close_button: bool = true
@export var draggable: bool = true
@export var resizable: bool = false
@export var default_size: Vector2 = Vector2(400, 300)
@export var min_size: Vector2 = Vector2(200, 150)
@export var max_size: Vector2 = Vector2(800, 600)

@onready var title_label: Label = $VBoxContainer/Header/TitleLabel
@onready var content_container: ScrollContainer = $VBoxContainer/ContentContainer
@onready var content_label: RichTextLabel = $VBoxContainer/ContentContainer/ContentLabel
@onready var close_button: Button = $VBoxContainer/Header/CloseButton
@onready var tween: Tween

var is_open: bool = false
var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var original_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	# 設定面板樣式
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = Constants.COLORS.PANEL
	stylebox.border_width_left = 2
	stylebox.border_width_top = 2
	stylebox.border_width_right = 2
	stylebox.border_width_bottom = 2
	stylebox.border_color = Constants.COLORS.GRID_LINE
	stylebox.corner_radius_top_left = 8
	stylebox.corner_radius_top_right = 8
	stylebox.corner_radius_bottom_right = 8
	stylebox.corner_radius_bottom_left = 8
	stylebox.shadow_color = Color(0, 0, 0, 0.5)
	stylebox.shadow_size = 4
	
	add_theme_stylebox_override("panel", stylebox)
	
	# 設定標題
	title_label.text = panel_title
	title_label.add_theme_color_override("font_color", Constants.COLORS.TEXT)
	title_label.add_theme_font_size_override("font_size", 20)
	
	# 設定內容文字
	content_label.add_theme_color_override("default_color", Constants.COLORS.TEXT_SECONDARY)
	content_label.add_theme_font_size_override("normal_font_size", 14)
	
	# 設定關閉按鈕
	if show_close_button:
		close_button.visible = true
		close_button.pressed.connect(_on_close_button_pressed)
		
		# 設定關閉按鈕樣式
		var close_stylebox = StyleBoxFlat.new()
		close_stylebox.bg_color = Constants.COLORS.BUTTON
		close_stylebox.corner_radius_top_left = 4
		close_stylebox.corner_radius_top_right = 4
		close_stylebox.corner_radius_bottom_right = 4
		close_stylebox.corner_radius_bottom_left = 4
		
		close_button.add_theme_stylebox_override("normal", close_stylebox)
		close_button.text = "×"
		close_button.add_theme_font_size_override("font_size", 18)
	else:
		close_button.visible = false
	
	# 初始狀態
	if auto_show:
		show_panel()
	else:
		# 直接隱藏，不執行動畫
		is_open = false
		visible = false

func show_panel() -> void:
	if is_open:
		return
	
	is_open = true
	visible = true
	panel_opened.emit()
	
	# 顯示動畫
	animate_show()

func hide_panel() -> void:
	if not is_open:
		return
	
	is_open = false
	panel_closed.emit()
	
	# 隱藏動畫
	animate_hide()

func toggle_panel() -> void:
	if is_open:
		hide_panel()
	else:
		show_panel()

func set_content(text: String) -> void:
	content_label.text = text

func set_title(title: String) -> void:
	panel_title = title
	title_label.text = title

func set_position_centered() -> void:
	var viewport_size = get_viewport().get_visible_rect().size
	position = (viewport_size - size) / 2

func animate_show() -> void:
	if tween:
		tween.kill()
	
	# 初始狀態
	modulate = Color(1, 1, 1, 0)
	scale = Vector2(0.8, 0.8)
	
	tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, Constants.GAME_SETTINGS.ANIMATION_DURATION)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), Constants.GAME_SETTINGS.ANIMATION_DURATION)

func animate_hide() -> void:
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, Constants.GAME_SETTINGS.ANIMATION_DURATION)
	tween.tween_property(self, "scale", Vector2(0.8, 0.8), Constants.GAME_SETTINGS.ANIMATION_DURATION)
	tween.tween_callback(set_visible.bind(false)).set_delay(Constants.GAME_SETTINGS.ANIMATION_DURATION)

func _on_close_button_pressed() -> void:
	hide_panel()

func _gui_input(event: InputEvent) -> void:
	if draggable and event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if mouse_event.pressed:
				# 開始拖曳
				is_dragging = true
				drag_offset = get_global_mouse_position() - global_position
				original_position = global_position
			else:
				# 結束拖曳
				is_dragging = false
	
	elif draggable and event is InputEventMouseMotion and is_dragging:
		global_position = get_global_mouse_position() - drag_offset

func _process(_delta: float) -> void:
	# 限制面板在視窗內
	if is_open:
		var viewport_rect = get_viewport().get_visible_rect()
		var panel_rect = Rect2(global_position, size)
		
		# 確保面板不會超出視窗邊界
		if panel_rect.position.x < 0:
			global_position.x = 0
		if panel_rect.position.y < 0:
			global_position.y = 0
		if panel_rect.end.x > viewport_rect.end.x:
			global_position.x = viewport_rect.end.x - size.x
		if panel_rect.end.y > viewport_rect.end.y:
			global_position.y = viewport_rect.end.y - size.y

# 工具函數
func set_content_from_markdown(markdown_text: String) -> void:
	# 簡單的 Markdown 轉換（可擴展）
	var bbcode_text = markdown_text
	bbcode_text = bbcode_text.replace("### ", "[b][font_size=18]").replace("\n", "[/font_size][/b]\n")
	bbcode_text = bbcode_text.replace("## ", "[b][font_size=20]").replace("\n", "[/font_size][/b]\n")
	bbcode_text = bbcode_text.replace("# ", "[b][font_size=22]").replace("\n", "[/font_size][/b]\n")
	bbcode_text = bbcode_text.replace("**", "[b]").replace("**", "[/b]")
	bbcode_text = bbcode_text.replace("*", "[i]").replace("*", "[/i]")
	
	content_label.text = bbcode_text

func set_mechanic_info(mechanic_name: String, description: String, examples: Array = []) -> void:
	var content = "[b][font_size=18]%s[/font_size][/b]\n\n" % mechanic_name
	content += "%s\n\n" % description
	
	if examples.size() > 0:
		content += "[b]範例遊戲：[/b]\n"
		for example in examples:
			content += "• %s\n" % example
	
	set_content(content)

func clear_content() -> void:
	content_label.text = ""