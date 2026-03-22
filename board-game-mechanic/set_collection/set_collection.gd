# set_collection.gd
# 成套收集機制實作

extends Node2D
class_name SetCollectionDemo

signal set_completed(set_name: String, score: int)
signal card_collected(card: Card, set_name: String)
signal score_updated(total_score: int)

@export var max_sets: int = 5
@export var cards_per_set: int = 3
@export var auto_setup: bool = true

var card_scene = preload("res://common/components/card.tscn")
var available_cards: Array = []  # 可用卡牌池
var collected_cards: Array = []  # 已收集的卡牌
var completed_sets: Array = []   # 已完成的套裝
var current_score: int = 0

# 套裝定義
var set_definitions: Dictionary = {
	"紅色套裝": {
		"required_types": [Constants.CARD_TYPES.ACTION, Constants.CARD_TYPES.ACTION, Constants.CARD_TYPES.ACTION],
		"base_score": 10,
		"color": Color(0.8, 0.2, 0.2)
	},
	"藍色套裝": {
		"required_types": [Constants.CARD_TYPES.RESOURCE, Constants.CARD_TYPES.RESOURCE, Constants.CARD_TYPES.RESOURCE],
		"base_score": 8,
		"color": Color(0.2, 0.2, 0.8)
	},
	"綠色套裝": {
		"required_types": [Constants.CARD_TYPES.VICTORY, Constants.CARD_TYPES.VICTORY, Constants.CARD_TYPES.VICTORY],
		"base_score": 12,
		"color": Color(0.2, 0.8, 0.2)
	},
	"紫色套裝": {
		"required_types": [Constants.CARD_TYPES.SPECIAL, Constants.CARD_TYPES.SPECIAL, Constants.CARD_TYPES.SPECIAL],
		"base_score": 15,
		"color": Color(0.8, 0.2, 0.8)
	},
	"混合套裝": {
		"required_types": [Constants.CARD_TYPES.ACTION, Constants.CARD_TYPES.RESOURCE, Constants.CARD_TYPES.VICTORY],
		"base_score": 20,
		"color": Color(0.8, 0.8, 0.2)
	}
}

# UI 節點引用
@onready var available_container: Node2D = $CanvasLayer/Control/VBoxContainer/GameArea/HBoxContainer/AvailableContainer
@onready var collected_container: Node2D = $CanvasLayer/Control/VBoxContainer/GameArea/HBoxContainer/CollectedContainer
@onready var sets_container: Node2D = $CanvasLayer/Control/VBoxContainer/GameArea/SetsContainer
@onready var draw_button: Button = $CanvasLayer/Control/VBoxContainer/ControlPanel/DrawButton
@onready var collect_button: Button = $CanvasLayer/Control/VBoxContainer/ControlPanel/CollectButton
@onready var complete_set_button: Button = $CanvasLayer/Control/VBoxContainer/ControlPanel/CompleteSetButton
@onready var reset_button: Button = $CanvasLayer/Control/VBoxContainer/ControlPanel/ResetButton
@onready var back_button: Button = $CanvasLayer/Control/VBoxContainer/ControlPanel/BackButton
@onready var info_label: Label = $CanvasLayer/Control/VBoxContainer/InfoPanel/InfoLabel
@onready var score_label: RichTextLabel = $CanvasLayer/Control/VBoxContainer/InfoPanel/ScoreLabel
@onready var sets_label: RichTextLabel = $CanvasLayer/Control/VBoxContainer/InfoPanel/SetsLabel

var selected_card: Card = null

func _ready() -> void:
	# 等待一幀確保所有節點都已載入
	await get_tree().process_frame
	
	# 檢查節點是否存在
	if not available_container:
		push_error("無法找到 AvailableContainer 節點！")
		return
	if not collected_container:
		push_error("無法找到 CollectedContainer 節點！")
		return
	if not sets_container:
		push_error("無法找到 SetsContainer 節點！")
		return
	
	# 連接按鈕信號
	if draw_button:
		draw_button.pressed.connect(_on_draw_button_pressed)
	if collect_button:
		collect_button.pressed.connect(_on_collect_button_pressed)
	if complete_set_button:
		complete_set_button.pressed.connect(_on_complete_set_button_pressed)
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
	# 清空所有區域
	_clear_all_areas()
	
	# 建立可用卡牌池
	_create_card_pool()
	
	# 初始化套裝顯示
	_init_sets_display()
	
	# 更新顯示
	_update_display()
	
	info_label.text = "遊戲開始！點擊抽牌獲取卡牌。"

func _clear_all_areas() -> void:
	# 清空可用卡牌池
	for card in available_cards:
		if is_instance_valid(card):
			card.queue_free()
	available_cards.clear()
	
	# 清空已收集卡牌
	for card in collected_cards:
		if is_instance_valid(card):
			card.queue_free()
	collected_cards.clear()
	
	# 清空已完成套裝
	completed_sets.clear()
	
	# 重置分數
	current_score = 0

func _create_card_pool() -> void:
	# 建立卡牌池（每種類型5張）
	var card_types = [
		Constants.CARD_TYPES.ACTION,
		Constants.CARD_TYPES.RESOURCE,
		Constants.CARD_TYPES.VICTORY,
		Constants.CARD_TYPES.SPECIAL
	]
	
	var card_names = {
		Constants.CARD_TYPES.ACTION: ["攻擊", "防禦", "魔法", "治療", "強化"],
		Constants.CARD_TYPES.RESOURCE: ["木材", "石頭", "黃金", "寶石", "水晶"],
		Constants.CARD_TYPES.VICTORY: ["王冠", "城堡", "旗幟", "勳章", "寶座"],
		Constants.CARD_TYPES.SPECIAL: ["龍", "鳳凰", "獨角獸", "獅鷲", "巨龍"]
	}
	
	var card_index = 0
	for card_type in card_types:
		for i in range(5):  # 每種類型5張
			var card = card_scene.instantiate() as Card
			card.name = "Card_%d" % card_index
			card_index += 1
			
			# 設定卡牌屬性
			card.card_name = "%s卡 %d" % [card_names[card_type][i], i + 1]
			card.card_type = card_type
			card.card_value = (i + 1) * 2  # 數值：2, 4, 6, 8, 10
			card.card_description = "這是一張%s卡，可用於收集套裝" % card_names[card_type][i]
			
			available_container.add_child(card)
			card.position = Vector2(50 + (i % 3) * 150, 50 + (i // 3) * 200)
			
			# 連接卡牌信號
			card.card_selected.connect(_on_card_selected.bind(card))
			
			available_cards.append(card)

func _init_sets_display() -> void:
	# 清空套裝容器
	for child in sets_container.get_children():
		if child.name != "SetsLabel":  # 保留標籤
			child.queue_free()
	
	# 建立套裝顯示
	var set_index = 0
	for set_name in set_definitions.keys():
		var set_panel = Panel.new()
		set_panel.name = "SetPanel_%s" % set_name
		set_panel.size = Vector2(180, 100)
		set_panel.position = Vector2(20 + (set_index % 3) * 200, 50 + (set_index // 3) * 120)
		
		# 設定樣式
		var stylebox = StyleBoxFlat.new()
		stylebox.bg_color = set_definitions[set_name]["color"].darkened(0.3)
		stylebox.border_color = set_definitions[set_name]["color"]
		stylebox.border_width_left = 2
		stylebox.border_width_top = 2
		stylebox.border_width_right = 2
		stylebox.border_width_bottom = 2
		stylebox.corner_radius_top_left = 8
		stylebox.corner_radius_top_right = 8
		stylebox.corner_radius_bottom_right = 8
		stylebox.corner_radius_bottom_left = 8
		
		set_panel.add_theme_stylebox_override("panel", stylebox)
		
		# 添加標籤
		var vbox = VBoxContainer.new()
		vbox.anchor_right = 1.0
		vbox.anchor_bottom = 1.0
		vbox.offset_left = 10.0
		vbox.offset_top = 10.0
		vbox.offset_right = -10.0
		vbox.offset_bottom = -10.0
		set_panel.add_child(vbox)
		
		var name_label = Label.new()
		name_label.text = set_name
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 14)
		name_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		vbox.add_child(name_label)
		
		var progress_label = Label.new()
		progress_label.name = "ProgressLabel"
		progress_label.text = "0/%d" % cards_per_set
		progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		progress_label.add_theme_font_size_override("font_size", 12)
		progress_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1))
		vbox.add_child(progress_label)
		
		var score_label = Label.new()
		score_label.name = "ScoreLabel"
		score_label.text = "分數: %d" % set_definitions[set_name]["base_score"]
		score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		score_label.add_theme_font_size_override("font_size", 12)
		score_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.5, 1))
		vbox.add_child(score_label)
		
		sets_container.add_child(set_panel)
		set_index += 1

func draw_card() -> void:
	if available_cards.is_empty():
		info_label.text = "卡牌池已空！"
		return
	
	# 隨機抽取一張卡牌
	var random_index = randi() % available_cards.size()
	var card = available_cards[random_index]
	
	# 移動到可用區域中央（表示抽到）
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(card, "position", Vector2(available_container.size.x / 2 - 60, available_container.size.y / 2 - 90), 0.5)
	tween.tween_property(card, "scale", Vector2(1.1, 1.1), 0.5)
	tween.tween_property(card, "z_index", 10, 0.5)
	
	info_label.text = "抽到卡牌：%s" % card.card_name

func collect_card(card: Card) -> void:
	if not card in available_cards:
		info_label.text = "這張卡不在可用卡牌池中！"
		return
	
	# 從可用卡牌池移除
	available_cards.erase(card)
	
	# 添加到已收集卡牌
	collected_cards.append(card)
	
	# 移動到已收集區域
	collected_container.add_child(card)
	
	# 計算位置（網格排列）
	var grid_x = (collected_cards.size() - 1) % 4
	var grid_y = (collected_cards.size() - 1) // 4
	
	var target_position = Vector2(30 + grid_x * 150, 30 + grid_y * 200)
	
	# 動畫移動
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(card, "position", target_position, 0.5)
	tween.tween_property(card, "scale", Vector2(1.0, 1.0), 0.5)
	tween.tween_property(card, "z_index", collected_cards.size(), 0.5)
	
	# 發送信號
	card_collected.emit(card, "已收集")
	
	# 更新顯示
	_update_set_progress()
	_update_display()
	
	info_label.text = "收集卡牌：%s" % card.card_name

func check_sets() -> Dictionary:
	# 檢查可以完成哪些套裝
	var completable_sets = {}
	
	for set_name in set_definitions.keys():
		if set_name in completed_sets:
			continue  # 已經完成的套裝
		
		var required_types = set_definitions[set_name]["required_types"].duplicate()
		var matched_cards = []
		
		# 檢查已收集的卡牌是否符合套裝要求
		for card in collected_cards:
			if card.card_type in required_types:
				matched_cards.append(card)
				required_types.erase(card.card_type)
		
		# 如果找到所有需要的卡牌類型
		if required_types.is_empty():
			completable_sets[set_name] = matched_cards
	
	return completable_sets

func complete_set(set_name: String) -> void:
	if set_name in completed_sets:
		info_label.text = "這個套裝已經完成了！"
		return
	
	var completable_sets = check_sets()
	if not set_name in completable_sets:
		info_label.text = "無法完成這個套裝！"
		return
	
	var matched_cards = completable_sets[set_name]
	var set_info = set_definitions[set_name]
	
	# 從已收集卡牌中移除這些卡牌
	for card in matched_cards:
		collected_cards.erase(card)
		card.queue_free()
	
	# 添加到已完成套裝
	completed_sets.append(set_name)
	
	# 計算分數
	var set_score = set_info["base_score"]
	current_score += set_score
	
	# 更新套裝顯示
	_update_set_display(set_name, true)
	
	# 發送信號
	set_completed.emit(set_name, set_score)
	score_updated.emit(current_score)
	
	# 更新顯示
	_update_display()
	
	info_label.text = "完成套裝：%s！獲得 %d 分" % [set_name, set_score]

func _update_set_progress() -> void:
	# 更新所有套裝的進度
	for set_name in set_definitions.keys():
		if set_name in completed_sets:
			continue
		
		var required_types = set_definitions[set_name]["required_types"].duplicate()
		var matched_count = 0
		
		# 計算已收集的符合卡牌數量
		for card in collected_cards:
			if card.card_type in required_types:
				matched_count += 1
				required_types.erase(card.card_type)
		
		# 更新進度標籤
		var set_panel = sets_container.get_node_or_null("SetPanel_%s" % set_name)
		if set_panel:
			var progress_label = set_panel.get_node_or_null("VBoxContainer/ProgressLabel")
			if progress_label:
				progress_label.text = "%d/%d" % [matched_count, cards_per_set]
				
				# 根據進度改變顏色
				if matched_count == cards_per_set:
					progress_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.2, 1))
				elif matched_count > 0:
					progress_label.add_theme_color_override("font_color", Color(0.7, 0.9, 0.7, 1))

func _update_set_display(set_name: String, is_completed: bool) -> void:
	var set_panel = sets_container.get_node_or_null("SetPanel_%s" % set_name)
	if not set_panel:
		return
	
	if is_completed:
		# 套裝完成，改變樣式
		var stylebox = StyleBoxFlat.new()
		stylebox.bg_color = set_definitions[set_name]["color"]
		stylebox.border_color = Color(0.9, 0.9, 0.2, 1)
		stylebox.border_width_left = 4
		stylebox.border_width_top = 4
		stylebox.border_width_right = 4
		stylebox.border_width_bottom = 4
		stylebox.corner_radius_top_left = 8
