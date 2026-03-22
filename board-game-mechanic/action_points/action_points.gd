# action_points.gd
# 行動點數機制實作

extends Node2D
class_name ActionPointsDemo

signal action_points_changed(player_id: int, new_points: int)
signal action_completed(player_id: int, action_name: String, cost: int)
signal turn_ended(player_id: int)
signal game_over(winner_id: int)

@export var max_players: int = 2
@export var starting_action_points: int = 5
@export var max_action_points: int = 10
@export var auto_setup: bool = true

# 玩家資料
var players: Array = []
var current_player_index: int = 0
var game_active: bool = false

# 可用行動
var available_actions: Array = [
	{"name": "移動", "cost": 1, "description": "移動到相鄰位置"},
	{"name": "攻擊", "cost": 2, "description": "攻擊敵人"},
	{"name": "防禦", "cost": 1, "description": "提升防禦力"},
	{"name": "治療", "cost": 3, "description": "恢復生命值"},
	{"name": "強化", "cost": 2, "description": "提升攻擊力"},
	{"name": "偵查", "cost": 1, "description": "查看敵人資訊"},
	{"name": "休息", "cost": 0, "description": "恢復1點行動點數"},
	{"name": "特殊技能", "cost": 4, "description": "使用特殊技能"}
]

# UI 節點引用
@onready var background: ColorRect = $Background
@onready var canvas_layer: CanvasLayer = $CanvasLayer
@onready var control: Control = $CanvasLayer/Control
@onready var title_label: Label = $CanvasLayer/Control/VBoxContainer/TitleLabel
@onready var game_area: VBoxContainer = $CanvasLayer/Control/VBoxContainer/GameArea
@onready var players_container: HBoxContainer = $CanvasLayer/Control/VBoxContainer/GameArea/PlayersContainer
@onready var actions_container: VBoxContainer = $CanvasLayer/Control/VBoxContainer/GameArea/ActionsContainer
@onready var info_panel: VBoxContainer = $CanvasLayer/Control/VBoxContainer/InfoPanel
@onready var info_label: Label = $CanvasLayer/Control/VBoxContainer/InfoPanel/InfoLabel
@onready var log_label: RichTextLabel = $CanvasLayer/Control/VBoxContainer/InfoPanel/LogLabel
@onready var control_panel: HBoxContainer = $CanvasLayer/Control/VBoxContainer/ControlPanel
@onready var next_turn_button: Button = $CanvasLayer/Control/VBoxContainer/ControlPanel/NextTurnButton
@onready var reset_button: Button = $CanvasLayer/Control/VBoxContainer/ControlPanel/ResetButton
@onready var back_button: Button = $CanvasLayer/Control/VBoxContainer/ControlPanel/BackButton

var selected_action: Dictionary = {}

func _ready() -> void:
	# 等待一幀確保所有節點都已載入
	await get_tree().process_frame
	
	# 檢查節點是否存在
	if not players_container:
		push_error("無法找到 PlayersContainer 節點！")
		return
	if not actions_container:
		push_error("無法找到 ActionsContainer 節點！")
		return
	
	# 連接按鈕信號
	if next_turn_button:
		next_turn_button.pressed.connect(_on_next_turn_button_pressed)
	if reset_button:
		reset_button.pressed.connect(_on_reset_button_pressed)
	if back_button:
		back_button.pressed.connect(_on_back_button_pressed)
	
	# 初始化遊戲
	if auto_setup:
		setup_game()
	
	# 更新顯示
	_update_display()

func setup_game() -> void:
	# 清空遊戲區域
	_clear_game_area()
	
	# 建立玩家
	_create_players()
	
	# 建立行動面板
	_create_actions_panel()
	
	# 開始遊戲
	game_active = true
	current_player_index = 0
	
	# 更新顯示
	_update_display()
	
	info_label.text = "遊戲開始！玩家1的回合。"

func _clear_game_area() -> void:
	# 清空玩家容器
	for child in players_container.get_children():
		child.queue_free()
	
	# 清空行動容器
	for child in actions_container.get_children():
		if child.name != "ActionsLabel":  # 保留標籤
			child.queue_free()
	
	# 清空玩家資料
	players.clear()
	
	# 重置遊戲狀態
	current_player_index = 0
	game_active = false
	selected_action = {}

func _create_players() -> void:
	# 建立玩家
	for i in range(max_players):
		var player = {
			"id": i + 1,
			"name": "玩家%d" % (i + 1),
			"action_points": starting_action_points,
			"max_action_points": max_action_points,
			"health": 20,
			"max_health": 20,
			"attack": 5,
			"defense": 3,
			"actions_taken": [],
			"color": Constants.COLORS.PLAYER_COLORS[i % Constants.COLORS.PLAYER_COLORS.size()]
		}
		players.append(player)
		
		# 建立玩家面板
		_create_player_panel(player)

func _create_player_panel(player: Dictionary) -> void:
	var player_panel = Panel.new()
	player_panel.name = "PlayerPanel_%d" % player.id
	player_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	player_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	player_panel.custom_minimum_size = Vector2(200, 300)
	
	# 設定樣式
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = player.color.darkened(0.2)
	stylebox.border_color = player.color
	stylebox.border_width_left = 2
	stylebox.border_width_top = 2
	stylebox.border_width_right = 2
	stylebox.border_width_bottom = 2
	stylebox.corner_radius_top_left = 8
	stylebox.corner_radius_top_right = 8
	stylebox.corner_radius_bottom_right = 8
	stylebox.corner_radius_bottom_left = 8
	
	player_panel.add_theme_stylebox_override("panel", stylebox)
	
	# 添加內容
	var vbox = VBoxContainer.new()
	vbox.anchor_right = 1.0
	vbox.anchor_bottom = 1.0
	vbox.offset_left = 10.0
	vbox.offset_top = 10.0
	vbox.offset_right = -10.0
	vbox.offset_bottom = -10.0
	vbox.theme_override_constants.separation = 10
	player_panel.add_child(vbox)
	
	# 玩家名稱
	var name_label = Label.new()
	name_label.name = "NameLabel"
	name_label.text = player.name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	vbox.add_child(name_label)
	
	# 行動點數
	var ap_container = HBoxContainer.new()
	ap_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(ap_container)
	
	var ap_label = Label.new()
	ap_label.text = "行動點數:"
	ap_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ap_label.add_theme_font_size_override("font_size", 14)
	ap_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1))
	ap_container.add_child(ap_label)
	
	var ap_value = Label.new()
	ap_value.name = "APValue"
	ap_value.text = "%d/%d" % [player.action_points, player.max_action_points]
	ap_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ap_value.add_theme_font_size_override("font_size", 14)
	ap_value.add_theme_color_override("font_color", Color(0.9, 0.9, 0.5, 1))
	ap_container.add_child(ap_value)
	
	# 生命值
	var hp_container = HBoxContainer.new()
	hp_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(hp_container)
	
	var hp_label = Label.new()
	hp_label.text = "生命值:"
	hp_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hp_label.add_theme_font_size_override("font_size", 14)
	hp_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1))
	hp_container.add_child(hp_label)
	
	var hp_value = Label.new()
	hp_value.name = "HPValue"
	hp_value.text = "%d/%d" % [player.health, player.max_health]
	hp_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hp_value.add_theme_font_size_override("font_size", 14)
	hp_value.add_theme_color_override("font_color", Color(0.9, 0.5, 0.5, 1))
	hp_container.add_child(hp_value)
	
	# 攻擊力
	var attack_label = Label.new()
	attack_label.text = "攻擊力: %d" % player.attack
	attack_label.add_theme_font_size_override("font_size", 12)
	attack_label.add_theme_color_override("font_color", Color(0.9, 0.7, 0.7, 1))
	vbox.add_child(attack_label)
	
	# 防禦力
	var defense_label = Label.new()
	defense_label.text = "防禦力: %d" % player.defense
	defense_label.add_theme_font_size_override("font_size", 12)
	defense_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.9, 1))
	vbox.add_child(defense_label)
	
	# 已採取行動列表
	var actions_label = Label.new()
	actions_label.text = "已採取行動:"
	actions_label.add_theme_font_size_override("font_size", 12)
	actions_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1))
	vbox.add_child(actions_label)
	
	var actions_list = RichTextLabel.new()
	actions_list.name = "ActionsList"
	actions_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	actions_list.custom_minimum_size = Vector2(0, 100)
	actions_list.bbcode_enabled = true
	actions_list.text = "無"
	vbox.add_child(actions_list)
	
	# 當前玩家指示器
	var current_indicator = Label.new()
	current_indicator.name = "CurrentIndicator"
	current_indicator.text = "▶ 當前回合"
	current_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	current_indicator.add_theme_font_size_override("font_size", 12)
	current_indicator.add_theme_color_override("font_color", Color(0.9, 0.9, 0.2, 1))
	current_indicator.visible = false
	vbox.add_child(current_indicator)
	
	players_container.add_child(player_panel)

func _create_actions_panel() -> void:
	# 清空行動容器（保留標籤）
	for child in actions_container.get_children():
		if child.name != "ActionsLabel":
			child.queue_free()
	
	# 建立行動按鈕
	for i in range(available_actions.size()):
		var action = available_actions[i]
		var button = Button.new()
		button.name = "ActionButton_%s" % action.name
		button.text = "%s (%d AP)" % [action.name, action.cost]
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		button.custom_minimum_size = Vector2(0, 40)
		
		# 設定樣式
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
		button.add_theme_font_size_override("font_size", 14)
		
		# 連接按鈕信號
		button.pressed.connect(_on_action_button_pressed.bind(action))
		
		actions_container.add_child(button)

func get_current_player() -> Dictionary:
	if players.is_empty():
		return {}
	return players[current_player_index]

func can_perform_action(action_cost: int) -> bool:
	var current_player = get_current_player()
	if current_player.is_empty():
		return false
	
	return current_player.action_points >= action_cost

func perform_action(action: Dictionary) -> bool:
	var current_player = get_current_player()
	if current_player.is_empty():
		return false
	
	# 檢查是否有足夠的行動點數
	if not can_perform_action(action.cost):
		info_label.text = "行動點數不足！需要 %d AP，但只有 %d AP" % [action.cost, current_player.action_points]
		return false
	
	# 扣除行動點數
	current_player.action_points -= action.cost
	
	# 記錄行動
	current_player.actions_taken.append({
		"name": action.name,
		"cost": action.cost,
		"turn": current_player_index + 1
	})
	
	# 根據行動類型產生效果
	_apply_action_effects(current_player, action)
	
	# 發送信號
	action_points_changed.emit(current_player.id, current_player.action_points)
	action_completed.emit(current_player.id, action.name, action.cost)
	
	# 更新顯示
	_update_player_display(current_player)
	_update_display()
	
	info_label.text = "玩家%d 執行了 %s 行動 (-%d AP)" % [current_player.id, action.name, action.cost]
	
	# 檢查遊戲是否結束
	_check_game_over()
	
	return true

func _apply_action_effects(player: Dictionary, action: Dictionary) -> void:
	match action.name:
		"移動":
			# 移動沒有直接效果，只是消耗行動點數
			pass
		"攻擊":
			# 攻擊其他玩家
			var target_index = (current_player_index + 1) % players.size()
			var target = players[target_index]
			var damage = max(1, player.attack - (target.defense // 2))
			target.health -= damage
			info_label.text += "\n對玩家%d 造成 %d 點傷害！" % [target.id, damage]
			_update_player_display(target)
		"防禦":
			# 提升防禦力
			player.defense += 1
			info_label.text += "\n防禦力提升至 %d！" % player.defense
		"治療":
			# 恢復生命值
			var heal_amount = 5
			player.health = min(player.max_health, player.health + heal_amount)
			info_label.text += "\n恢復了 %d 點生命值！" % heal_amount
		"強化":
			# 提升攻擊力
			player.attack += 1
			info_label.text += "\n攻擊力提升至 %d！" % player.attack
		"偵查":
			# 查看敵人資訊
			var target_index = (current_player_index + 1) % players.size()
			var target = players[target_index]
			info_label.text += "\n玩家%d 狀態：生命值 %d/%d，攻擊力 %d，防禦力 %d" % [
				target.id, target.health, target.max_health, target.attack, target.defense
			]
		"休息":
			# 恢復行動點數
			var recover_amount = 1
			player.action_points = min(player.max_action_points, player.action_points + recover_amount)
			info_label.text += "\n恢復了 %d 點行動點數！" % recover_amount
		"特殊技能":
			# 特殊技能：同時提升攻擊和防禦
			player.attack += 2
			player.defense += 2
			info_label.text += "\n特殊技能發動！攻擊力+2，防禦力+2！"

func end_turn() -> void:
	if not game_active:
		return
	
	var current_player = get_current_player()
	if current_player.is_empty():
		return
	
	# 發送回合結束信號
	turn_ended.emit(current_player.id)
	
	# 切換到下一個玩家
	current_player_index = (current_player_index + 1) % players.size()
	
	# 重置選擇的行動
	selected_action = {}
	
	# 更新顯示
	_update_display()
	
	# 檢查遊戲是否結束
	_check_game_over()
	
	info_label.text = "玩家%d 的回合結束，輪到玩家%d。" % [current_player.id, get_current_player().id]

func _update_player_display(player: Dictionary) -> void:
	var player_panel = players_container.get_node_or_null("PlayerPanel_%d" % player.id)
	if not player_panel:
		return
	
	# 更新行動點數 - 使用 find_child 查找 APValue 節點
	var ap_value = player_panel.find_child("APValue", true, false)
	if ap_value:
		ap_value.text = "%d/%d" % [player.action_points, player.max_action_points]
	
	# 更新生命值 - 使用 find_child 查找 HPValue 節點
	var hp_value = player_panel.find_child("HPValue", true, false)
	if hp_value:
		hp_value.text = "%d/%d" % [player.health, player.max_health]
	
	# 更新攻擊力 - 查找第一個 Label（攻擊力標籤）
	var attack_label = null
	for child in player_panel.get_children():
		if child is VBoxContainer:
			for subchild in child.get_children():
				if subchild is Label and subchild.text.begins_with("攻擊力:"):
					attack_label = subchild
					break
			if attack_label:
				break
	
	if attack_label:
		attack_label.text = "攻擊力: %d" % player.attack
	
	# 更新防禦力 - 查找第二個 Label（防禦力標籤）
	var defense_label = null
	var label_count = 0
	for child in player_panel.get_children():
		if child is VBoxContainer:
			for subchild in child.get_children():
				if subchild is Label and subchild.text.begins_with("防禦力:"):
					defense_label = subchild
					break
			if defense_label:
				break
	
	if defense_label:
		defense_label.text = "防禦力: %d" % player.defense
	
	# 更新已採取行動列表
	var actions_list = player_panel.find_child("ActionsList", true, false)
	if actions_list:
		if player.actions_taken.is_empty():
			actions_list.text = "無"
		else:
			var actions_text = ""
			for i in range(player.actions_taken.size()):
				var action = player.actions_taken[i]
				actions_text += "• %s (-%d AP)\n" % [action.name, action.cost]
			actions_list.text = actions_text
	
	# 更新當前玩家指示器
	var current_indicator = player_panel.find_child("CurrentIndicator", true, false)
	if current_indicator:
		current_indicator.visible = (player.id == get_current_player().id)

func _update_display() -> void:
	if not game_active:
		return
	
	# 更新所有玩家顯示
	for player in players:
		_update_player_display(player)
	
	# 更新行動按鈕狀態
	for i in range(available_actions.size()):
		var action = available_actions[i]
		var button_name = "ActionButton_" + action.name
		var button = actions_container.get_node_or_null(button_name)
		if button:
			var can_afford = can_perform_action(action.cost)
			button.disabled = not can_afford
			
			# 更新按鈕顏色
			var stylebox = button.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
			if can_afford:
				stylebox.bg_color = Constants.COLORS.BUTTON
			else:
				stylebox.bg_color = Constants.COLORS.BUTTON.darkened(0.5)
			button.add_theme_stylebox_override("normal", stylebox)
	
	# 更新回合資訊
	var current_player = get_current_player()
	if not current_player.is_empty():
		title_label.text = "行動點數機制 - 玩家%d 的回合 (%d AP)" % [current_player.id, current_player.action_points]

func _check_game_over() -> void:
	var alive_players = []
	for player in players:
		if player.health > 0:
			alive_players.append(player)
	
	if alive_players.size() <= 1:
		game_active = false
		
		if alive_players.size() == 1:
			var winner = alive_players[0]
			game_over.emit(winner.id)
			info_label.text = "遊戲結束！玩家%d 獲勝！" % winner.id
		else:
			game_over.emit(-1)  # 平局
			info_label.text = "遊戲結束！平局！"
		
		# 禁用行動按鈕
		for i in range(available_actions.size()):
			var action = available_actions[i]
			var button_name = "ActionButton_" + action.name
			var button = actions_container.get_node_or_null(button_name)
			if button:
				button.disabled = true

func _on_action_button_pressed(action: Dictionary) -> void:
	if not game_active:
		return
	
	selected_action = action
	var success = perform_action(action)
	
	if success:
		# 添加日誌記錄
		var current_player = get_current_player()
		var log_text = log_label.text
		if log_text == "無":
			log_text = ""
		
		log_text = "玩家%d: %s (-%d AP)\n" % [current_player.id, action.name, action.cost] + log_text
		if log_text.count("\n") > 10:  # 限制日誌長度
			var lines = log_text.split("\n")
			log_text = "\n".join(lines.slice(0, 10))
		
		log_label.text = log_text

func _on_next_turn_button_pressed() -> void:
	end_turn()

func _on_reset_button_pressed() -> void:
	setup_game()

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://main.tscn")
