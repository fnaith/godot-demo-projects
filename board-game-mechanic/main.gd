# main.gd
# 主選單腳本

extends Node2D

var phase1_button: Button
var phase2_button: Button
var phase3_button: Button
var all_mechanics_button: Button
var info_button: Button
var info_panel: InfoPanel

var tween: Tween

func _ready() -> void:
	# 檢查是否在簡單場景中
	var test_label = get_node_or_null("CanvasLayer/TestLabel")
	
	if test_label:
		# 簡單場景模式
		print("使用簡單場景模式")
		test_label.text = "🎲 桌遊機制展示館 🃏\nBoardGameGeek 192種機制實作展示"
		
		# 初始化資訊面板
		_init_info_panel()
	else:
		# 完整場景模式
		# 獲取節點引用
		phase1_button = get_node_or_null("CanvasLayer/MainContainer/ContentPanel/VBoxContainer/PhaseButtons/Phase1Button")
		phase2_button = get_node_or_null("CanvasLayer/MainContainer/ContentPanel/VBoxContainer/PhaseButtons/Phase2Button")
		phase3_button = get_node_or_null("CanvasLayer/MainContainer/ContentPanel/VBoxContainer/PhaseButtons/Phase3Button")
		all_mechanics_button = get_node_or_null("CanvasLayer/MainContainer/ContentPanel/VBoxContainer/PhaseButtons/AllMechanicsButton")
		info_button = get_node_or_null("CanvasLayer/MainContainer/ContentPanel/VBoxContainer/Footer/InfoButton")
		
		# 連接按鈕信號（如果節點存在）
		if phase1_button:
			phase1_button.pressed.connect(_on_phase1_button_pressed)
		if phase2_button:
			phase2_button.pressed.connect(_on_phase2_button_pressed)
		if phase3_button:
			phase3_button.pressed.connect(_on_phase3_button_pressed)
		if all_mechanics_button:
			all_mechanics_button.pressed.connect(_on_all_mechanics_button_pressed)
		if info_button:
			info_button.pressed.connect(_on_info_button_pressed)
		
		# 設定按鈕懸停效果
		_setup_button_hover_effects()
		
		# 初始化資訊面板
		_init_info_panel()
		
		# 播放進入動畫
		play_enter_animation()

func _setup_button_hover_effects() -> void:
	# 為所有按鈕設定懸停效果
	var buttons = [
		phase1_button,
		phase2_button,
		phase3_button,
		all_mechanics_button,
		info_button
	]
	
	for button in buttons:
		if button:
			button.mouse_entered.connect(_on_button_mouse_entered.bind(button))
			button.mouse_exited.connect(_on_button_mouse_exited.bind(button))

func _init_info_panel() -> void:
	# 建立資訊面板（如果不存在）
	if not info_panel:
		var info_panel_scene = load("res://common/ui/info_panel.tscn")
		info_panel = info_panel_scene.instantiate() as InfoPanel
		info_panel.name = "InfoPanel"
		$CanvasLayer.add_child(info_panel)
		info_panel.set_position_centered()
		info_panel.hide_panel()
	
	# 設定資訊面板內容
	var project_info = """[b][font_size=22]桌遊機制展示館[/font_size][/b]

[b]專案目標：[/b]
將 BoardGameGeek 的所有桌遊機制（192種）實作成可互動的 Godot 場景，供未來專案參考與重用。

[b]專案特色：[/b]
• 零圖片設計（僅使用 ColorRect + Label + Unicode）
• 完全可互動的原型
• 模組化元件設計
• 響應式 UI 設計
• 流暢的動畫效果

[b]技術規格：[/b]
• Godot 4.6
• GL Compatibility 渲染器
• Jolt Physics 物理引擎
• 1920×1080 解析度

[b]開發階段：[/b]
1. 第1階段：10個核心機制
2. 第2階段：13個策略機制  
3. 第3+階段：169個特殊機制

[b]資料來源：[/b]
BoardGameGeek (BGG) - https://boardgamegeek.com/

[b]更新日期：[/b]2026-03-22"""
	
	info_panel.set_content_from_markdown(project_info)
	info_panel.panel_title = "專案資訊"

func play_enter_animation() -> void:
	# 淡入動畫
	var container = $CanvasLayer/MainContainer/ContentPanel
	container.modulate = Color(1, 1, 1, 0)
	container.scale = Vector2(0.9, 0.9)
	
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(container, "modulate:a", 1.0, 0.8)
	tween.tween_property(container, "scale", Vector2(1.0, 1.0), 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_phase1_button_pressed() -> void:
	# 第1階段按鈕點擊
	animate_button_press(phase1_button)
	
	# 顯示第1階段機制選單
	show_phase1_menu()

func _on_phase2_button_pressed() -> void:
	# 第2階段按鈕點擊
	animate_button_press(phase2_button)
	
	# 顯示提示訊息
	show_message("第2階段：策略機制", "即將實作工人擺放、區域控制等13個策略機制。")

func _on_phase3_button_pressed() -> void:
	# 第3階段按鈕點擊
	animate_button_press(phase3_button)
	
	# 顯示提示訊息
	show_message("第3+階段：特殊機制", "即將實作167個特殊或較少見的機制。")

func _on_all_mechanics_button_pressed() -> void:
	# 查看完整清單按鈕點擊
	animate_button_press(all_mechanics_button)
	
	# 顯示完整機制清單資訊
	show_mechanics_list()

func _on_info_button_pressed() -> void:
	# 資訊按鈕點擊
	animate_button_press(info_button)
	
	# 顯示/隱藏資訊面板
	if info_panel and info_panel.is_open:
		info_panel.hide_panel()
	else:
		info_panel.show_panel()
		info_panel.set_position_centered()

func _on_button_mouse_entered(button: Button) -> void:
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.tween_property(button, "scale", Vector2(1.02, 1.02), 0.1)

func _on_button_mouse_exited(button: Button) -> void:
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.1)

func animate_button_press(button: Button) -> void:
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(button, "scale", Vector2(0.95, 0.95), 0.1)
	tween.tween_property(button, "modulate", Color(0.8, 0.8, 0.8, 1.0), 0.1)
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.1).set_delay(0.1)
	tween.tween_property(button, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.1).set_delay(0.1)

func show_message(title: String, message: String) -> void:
	# 建立臨時訊息面板
	var message_panel = Panel.new()
	message_panel.name = "MessagePanel"
	
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = Constants.COLORS.PANEL
	stylebox.border_color = Constants.COLORS.BUTTON
	stylebox.border_width_left = 2
	stylebox.border_width_top = 2
	stylebox.border_width_right = 2
	stylebox.border_width_bottom = 2
	stylebox.corner_radius_top_left = 8
	stylebox.corner_radius_top_right = 8
	stylebox.corner_radius_bottom_right = 8
	stylebox.corner_radius_bottom_left = 8
	stylebox.shadow_color = Color(0, 0, 0, 0.5)
	stylebox.shadow_size = 4
	
	message_panel.add_theme_stylebox_override("panel", stylebox)
	message_panel.size = Vector2(400, 150)
	message_panel.position = (get_viewport().get_visible_rect().size - message_panel.size) / 2
	
	var vbox = VBoxContainer.new()
	vbox.anchor_right = 1.0
	vbox.anchor_bottom = 1.0
	vbox.offset_left = 20.0
	vbox.offset_top = 20.0
	vbox.offset_right = -20.0
	vbox.offset_bottom = -20.0
	message_panel.add_child(vbox)
	
	var title_label = Label.new()
	title_label.text = title
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 20)
	title_label.add_theme_color_override("font_color", Constants.COLORS.TEXT)
	vbox.add_child(title_label)
	
	var message_label = Label.new()
	message_label.text = message
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.add_theme_font_size_override("font_size", 16)
	message_label.add_theme_color_override("font_color", Constants.COLORS.TEXT_SECONDARY)
	vbox.add_child(message_label)
	
	$CanvasLayer.add_child(message_panel)
	
	# 淡入動畫
	message_panel.modulate = Color(1, 1, 1, 0)
	message_panel.scale = Vector2(0.8, 0.8)
	
	var message_tween = create_tween()
	message_tween.set_parallel(true)
	message_tween.tween_property(message_panel, "modulate:a", 1.0, 0.3)
	message_tween.tween_property(message_panel, "scale", Vector2(1.0, 1.0), 0.3)
	
	# 自動關閉
	await get_tree().create_timer(2.0).timeout
	
	# 淡出動畫
	message_tween = create_tween()
	message_tween.set_parallel(true)
	message_tween.tween_property(message_panel, "modulate:a", 0.0, 0.3)
	message_tween.tween_property(message_panel, "scale", Vector2(0.8, 0.8), 0.3)
	message_tween.tween_callback(message_panel.queue_free).set_delay(0.3)

func show_mechanics_list() -> void:
	# 顯示完整機制清單資訊
	var mechanics_info = """[b][font_size=22]完整機制清單[/font_size][/b]

[b]總機制數量：[/b]192種

[b]優先級分佈：[/b]
• [color=#4ecdc4]高優先級（第1階段）：[/color]10個核心機制
• [color=#ffe66d]中優先級（第2階段）：[/color]13個策略機制  
• [color=#b0b0b0]低優先級（第3+階段）：[/color]169個特殊機制

[b]第1階段核心機制：[/b]
1. Dice Rolling - 骰子擲投
2. Hand Management - 手牌管理
3. Set Collection - 成套收集
4. Action Points - 行動點數
5. Grid Movement - 格子移動
6. Roll and Move - 擲骰移動
7. Deck Building - 牌庫構築
8. Turn Order - 回合順序
9. Victory Points - 勝利點數
10. Player Elimination - 玩家淘汰

[b]資料來源：[/b]
BoardGameGeek (BGG) - https://boardgamegeek.com/

[b]詳細清單：[/b]
請查看 MECHANICS_LIST.md 檔案獲取完整192種機制清單。"""
	
	# 建立機制清單面板
	var list_panel = load("res://common/ui/info_panel.tscn").instantiate() as InfoPanel
	list_panel.name = "MechanicsListPanel"
	list_panel.panel_title = "完整機制清單"
	list_panel.default_size = Vector2(500, 600)
	list_panel.size = Vector2(500, 600)
	list_panel.set_position_centered()
	list_panel.set_content_from_markdown(mechanics_info)
	
	$CanvasLayer.add_child(list_panel)
	list_panel.show_panel()

# 工具函數
func get_phase1_mechanics() -> Array:
	return [
		"Dice Rolling",
		"Hand Management", 
		"Set Collection",
		"Action Points",
		"Grid Movement",
		"Roll and Move",
		"Deck Building",
		"Turn Order",
		"Victory Points",
		"Player Elimination"
	]

func get_phase2_mechanics() -> Array:
	return [
		"Worker Placement",
		"Area Control",
		"Auction/Bidding",
		"Card Drafting",
		"Resource Management",
		"Tile Placement",
		"Route Building",
		"Trading",
		"Voting",
		"Variable Player Powers",
		"Hidden Roles",
		"Simultaneous Action",
		"Push Your Luck",
		"Take That",
		"Pattern Building"
	]

func show_phase1_menu() -> void:
	# 隱藏主選單按鈕
	var phase_buttons = get_node_or_null("CanvasLayer/MainContainer/ContentPanel/VBoxContainer/PhaseButtons")
	if phase_buttons:
		phase_buttons.visible = false
	
	# 建立第1階段機制選單
	var phase1_menu = VBoxContainer.new()
	phase1_menu.name = "Phase1Menu"
	phase1_menu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	phase1_menu.size_flags_vertical = Control.SIZE_EXPAND_FILL
	phase1_menu.theme_override_constants.separation = 15
	
	# 添加標題
	var title_container = CenterContainer.new()
	title_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	var title_label = Label.new()
	title_label.text = "🎯 第1階段：10個核心機制"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.add_theme_color_override("font_color", Constants.COLORS.TEXT)
	title_container.add_child(title_label)
	phase1_menu.add_child(title_container)
	
	# 添加機制按鈕
	var mechanics = get_phase1_mechanics()
	for i in range(mechanics.size()):
		var mechanic_name = mechanics[i]
		var button = Button.new()
		button.name = "MechanicButton_%d" % i
		button.text = "%d. %s" % [i + 1, mechanic_name]
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		button.custom_minimum_size = Vector2(0, 50)
		
		# 設定按鈕樣式
		var stylebox = StyleBoxFlat.new()
		stylebox.bg_color = Constants.COLORS.BUTTON
		stylebox.border_width_left = 2
		stylebox.border_width_top = 2
		stylebox.border_width_right = 2
		stylebox.border_width_bottom = 2
		stylebox.border_color = Constants.COLORS.GRID_LINE
		stylebox.corner_radius_top_left = 8
		stylebox.corner_radius_top_right = 8
		stylebox.corner_radius_bottom_right = 8
		stylebox.corner_radius_bottom_left = 8
		
		button.add_theme_stylebox_override("normal", stylebox)
		button.add_theme_font_size_override("font_size", 16)
		
		# 連接按鈕信號
		if mechanic_name == "Dice Rolling":
			button.pressed.connect(_on_dice_rolling_button_pressed)
		else:
			button.pressed.connect(_on_mechanic_button_pressed.bind(mechanic_name))
		
		phase1_menu.add_child(button)
	
	# 添加返回按鈕
	var back_button_container = CenterContainer.new()
	back_button_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	back_button_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	var back_button = Button.new()
	back_button.name = "BackButton"
	back_button.text = "← 返回主選單"
	back_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	back_button.custom_minimum_size = Vector2(150, 40)
	back_button.pressed.connect(_on_phase1_back_button_pressed)
	
	back_button_container.add_child(back_button)
	phase1_menu.add_child(back_button_container)
	
	# 將選單添加到場景中
	var content_panel = get_node_or_null("CanvasLayer/MainContainer/ContentPanel/VBoxContainer")
	if content_panel:
		content_panel.add_child(phase1_menu)
		
		# 動畫效果
		phase1_menu.modulate = Color(1, 1, 1, 0)
		phase1_menu.scale = Vector2(0.9, 0.9)
		
		if tween:
			tween.kill()
		
		tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(phase1_menu, "modulate:a", 1.0, 0.5)
		tween.tween_property(phase1_menu, "scale", Vector2(1.0, 1.0), 0.5)

func _on_dice_rolling_button_pressed() -> void:
	# 載入骰子擲投場景
	get_tree().change_scene_to_file("res://dice_rolling/dice_rolling.tscn")

func _on_mechanic_button_pressed(mechanic_name: String) -> void:
	# 檢查是否已實作的機制
	match mechanic_name:
		"Hand Management":
			# 載入手牌管理場景
			get_tree().change_scene_to_file("res://hand_management/hand_management.tscn")
		"Set Collection":
			# 載入成套收集場景
			get_tree().change_scene_to_file("res://set_collection/set_collection.tscn")
		"Action Points":
			# 載入行動點數場景
			get_tree().change_scene_to_file("res://action_points/action_points.tscn")
		"Grid Movement":
			# 載入格子移動場景
			get_tree().change_scene_to_file("res://grid_movement/grid_movement.tscn")
		_:
			# 顯示提示訊息（其他機制尚未實作）
			show_message("即將實作", "%s 機制正在開發中，敬請期待！" % mechanic_name)

func _on_phase1_back_button_pressed() -> void:
	# 移除第1階段選單
	var phase1_menu = get_node_or_null("CanvasLayer/MainContainer/ContentPanel/VBoxContainer/Phase1Menu")
	if phase1_menu:
		phase1_menu.queue_free()
	
	# 顯示主選單按鈕
	var phase_buttons = get_node_or_null("CanvasLayer/MainContainer/ContentPanel/VBoxContainer/PhaseButtons")
	if phase_buttons:
		phase_buttons.visible = true
