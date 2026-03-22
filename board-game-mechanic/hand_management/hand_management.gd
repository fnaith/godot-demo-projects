# hand_management.gd
# 手牌管理機制實作

extends Node2D
class_name HandManagementDemo

signal card_drawn(card: Card, from_deck: bool)
signal card_discarded(card: Card, to_discard: bool)
signal card_played(card: Card, target: String)
signal hand_updated(hand_size: int, deck_size: int, discard_size: int)

@export var max_hand_size: int = 7
@export var initial_hand_size: int = 5
@export var deck_size: int = 30
@export var auto_setup: bool = true

var card_scene = preload("res://common/components/card.tscn")
var deck: Array = []  # 牌庫
var hand: Array = []  # 手牌
var discard_pile: Array = []  # 棄牌堆
var selected_card: Card = null
var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO

# UI 節點引用
@onready var deck_container: Node2D = $CanvasLayer/Control/VBoxContainer/GameArea/HBoxContainer/DeckContainer
@onready var discard_container: Node2D = $CanvasLayer/Control/VBoxContainer/GameArea/HBoxContainer/DiscardContainer
@onready var hand_container: Node2D = $CanvasLayer/Control/VBoxContainer/GameArea/HandContainer
@onready var draw_button: Button = $CanvasLayer/Control/VBoxContainer/ControlPanel/DrawButton
@onready var discard_button: Button = $CanvasLayer/Control/VBoxContainer/ControlPanel/DiscardButton
@onready var shuffle_button: Button = $CanvasLayer/Control/VBoxContainer/ControlPanel/ShuffleButton
@onready var reset_button: Button = $CanvasLayer/Control/VBoxContainer/ControlPanel/ResetButton
@onready var back_button: Button = $CanvasLayer/Control/VBoxContainer/ControlPanel/BackButton
@onready var info_label: Label = $CanvasLayer/Control/VBoxContainer/InfoPanel/InfoLabel
@onready var stats_label: RichTextLabel = $CanvasLayer/Control/VBoxContainer/InfoPanel/StatsLabel

func _ready() -> void:
	# 等待一幀確保所有節點都已載入
	await get_tree().process_frame
	
	# 檢查節點是否存在
	if not deck_container:
		push_error("無法找到 DeckContainer 節點！")
		return
	if not discard_container:
		push_error("無法找到 DiscardContainer 節點！")
		return
	if not hand_container:
		push_error("無法找到 HandContainer 節點！")
		return
	
	# 連接按鈕信號
	if draw_button:
		draw_button.pressed.connect(_on_draw_button_pressed)
	if discard_button:
		discard_button.pressed.connect(_on_discard_button_pressed)
	if shuffle_button:
		shuffle_button.pressed.connect(_on_shuffle_button_pressed)
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
	
	# 建立牌庫
	_create_deck()
	
	# 洗牌
	shuffle_deck()
	
	# 抽初始手牌
	for i in range(initial_hand_size):
		draw_card(true)
	
	# 更新顯示
	_update_display()

func _clear_all_areas() -> void:
	# 清空牌庫
	for card in deck:
		if is_instance_valid(card):
			card.queue_free()
	deck.clear()
	
	# 清空手牌
	for card in hand:
		if is_instance_valid(card):
			card.queue_free()
	hand.clear()
	
	# 清空棄牌堆
	for card in discard_pile:
		if is_instance_valid(card):
			card.queue_free()
	discard_pile.clear()

func _create_deck() -> void:
	# 建立標準牌庫（示例卡牌）
	var card_types = [
		{"name": "攻擊", "value": 5, "type": Constants.CARD_TYPES.ACTION},
		{"name": "防禦", "value": 3, "type": Constants.CARD_TYPES.RESOURCE},
		{"name": "治療", "value": 4, "type": Constants.CARD_TYPES.VICTORY},
		{"name": "魔法", "value": 6, "type": Constants.CARD_TYPES.SPECIAL},
		{"name": "道具", "value": 2, "type": Constants.CARD_TYPES.ACTION},
		{"name": "陷阱", "value": 4, "type": Constants.CARD_TYPES.RESOURCE},
		{"name": "強化", "value": 3, "type": Constants.CARD_TYPES.VICTORY},
		{"name": "弱化", "value": 3, "type": Constants.CARD_TYPES.SPECIAL}
	]
	
	for i in range(deck_size):
		var card_type = card_types[i % card_types.size()]
		var card = card_scene.instantiate() as Card
		card.name = "Card_%d" % i
		
		# 設定卡牌屬性
		card.card_name = "%s卡 %d" % [card_type["name"], i + 1]
		card.card_value = card_type["value"]
		card.card_type = card_type["type"]
		card.card_description = "這是一張%s卡，數值為%d" % [card_type["name"], card_type["value"]]
		
		deck_container.add_child(card)
		card.position = Vector2.ZERO
		card.visible = false  # 牌庫中的卡牌隱藏
		
		# 連接卡牌信號
		card.card_selected.connect(_on_card_selected.bind(card))
		card.card_dragged.connect(_on_card_dragged.bind(card))
		card.card_dropped.connect(_on_card_dropped.bind(card))
		
		deck.append(card)

func shuffle_deck() -> void:
	# Fisher-Yates 洗牌算法
	for i in range(deck.size() - 1, 0, -1):
		var j = randi() % (i + 1)
		var temp = deck[i]
		deck[i] = deck[j]
		deck[j] = temp
	
	# 更新顯示
	_update_display()
	
	# 發送信號
	info_label.text = "牌庫已洗牌！"

func draw_card(from_deck: bool = true) -> void:
	if from_deck:
		# 從牌庫抽牌
		if deck.is_empty():
			info_label.text = "牌庫已空！"
			return
		
		if hand.size() >= max_hand_size:
			info_label.text = "手牌已滿！"
			return
		
		var card = deck.pop_back()
		hand.append(card)
		
		# 顯示卡牌並移動到手牌區域
		card.visible = true
		_update_hand_layout()
		
		# 發送信號
		card_drawn.emit(card, true)
		hand_updated.emit(hand.size(), deck.size(), discard_pile.size())
		
		info_label.text = "抽到一張卡牌：%s" % card.card_name
	else:
		# 從棄牌堆抽牌（如果有）
		if discard_pile.is_empty():
			info_label.text = "棄牌堆已空！"
			return
		
		if hand.size() >= max_hand_size:
			info_label.text = "手牌已滿！"
			return
		
		var card = discard_pile.pop_back()
		hand.append(card)
		
		# 顯示卡牌並移動到手牌區域
		card.visible = true
		_update_hand_layout()
		
		# 發送信號
		card_drawn.emit(card, false)
		hand_updated.emit(hand.size(), deck.size(), discard_pile.size())
		
		info_label.text = "從棄牌堆抽到：%s" % card.card_name

func discard_card(card: Card, to_discard: bool = true) -> void:
	if not card in hand:
		info_label.text = "這張卡不在手牌中！"
		return
	
	# 從手牌移除
	hand.erase(card)
	
	if to_discard:
		# 移動到棄牌堆
		discard_pile.append(card)
		card.position = discard_container.position
		card.z_index = discard_pile.size()
		
		# 發送信號
		card_discarded.emit(card, true)
		info_label.text = "棄置卡牌：%s" % card.card_name
	else:
		# 放回牌庫底部
		deck.push_front(card)
		card.position = deck_container.position
		card.visible = false
		
		# 發送信號
		card_discarded.emit(card, false)
		info_label.text = "放回牌庫：%s" % card.card_name
	
	# 更新手牌佈局
	_update_hand_layout()
	
	# 更新顯示
	hand_updated.emit(hand.size(), deck.size(), discard_pile.size())

func play_card(card: Card, target: String = "default") -> void:
	if not card in hand:
		info_label.text = "這張卡不在手牌中！"
		return
	
	# 從手牌移除
	hand.erase(card)
	
	# 移動到遊戲區域中央（表示打出）
	card.position = get_viewport().get_visible_rect().size / 2
	card.z_index = 100
	
	# 發送信號
	card_played.emit(card, target)
	info_label.text = "打出卡牌：%s (目標：%s)" % [card.card_name, target]
	
	# 更新手牌佈局
	_update_hand_layout()
	
	# 更新顯示
	hand_updated.emit(hand.size(), deck.size(), discard_pile.size())

func _update_hand_layout() -> void:
	# 計算手牌位置（扇形展開）
	var hand_center = hand_container.position
	var hand_width = 800.0
	var card_spacing = 100.0
	var card_angle = 15.0  # 角度
	
	for i in range(hand.size()):
		var card = hand[i]
		var t = float(i) / max(1, hand.size() - 1)
		var x = hand_center.x + (t - 0.5) * min(hand_width, card_spacing * hand.size())
		var y = hand_center.y + abs(t - 0.5) * 50.0  # 輕微的弧形
		
		# 創建 Tween 動畫
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(card, "position", Vector2(x, y), 0.3)
		tween.tween_property(card, "rotation_degrees", (t - 0.5) * card_angle, 0.3)
		tween.tween_property(card, "z_index", i, 0.3)

func _update_display() -> void:
	# 更新統計資訊
	var stats_text = """[b]遊戲狀態：[/b]
手牌：%d/%d
牌庫：%d 張
棄牌堆：%d 張

[b]操作說明：[/b]
• 點擊卡牌：選擇卡牌
• 拖曳卡牌：移動卡牌
• 點擊抽牌：從牌庫抽一張牌
• 點擊棄牌：棄置選中的卡牌
• 點擊洗牌：重新洗牌
• 點擊重置：重新開始遊戲""" % [
		hand.size(), max_hand_size,
		deck.size(),
		discard_pile.size()
	]
	
	stats_label.text = stats_text
	
	# 更新按鈕狀態
	if draw_button:
		draw_button.disabled = deck.is_empty() or hand.size() >= max_hand_size
	
	if discard_button:
		discard_button.disabled = selected_card == null or not selected_card in hand

# 信號處理函數
func _on_card_selected(card: Card) -> void:
	# 取消之前選中的卡牌
	if selected_card and selected_card != card:
		selected_card.deselect()
	
	# 選中新的卡牌
	selected_card = card
	card.select()
	
	info_label.text = "選中卡牌：%s (數值：%d)" % [card.card_name, card.card_value]

func _on_card_dragged(card: Card, drag_position: Vector2) -> void:
	is_dragging = true
	
	# 將卡牌置頂
	card.z_index = 100
	
	# 更新卡牌位置
	card.position = drag_position

func _on_card_dropped(card: Card, drop_position: Vector2) -> void:
	is_dragging = false
	
	# 檢查放置位置
	var _viewport_rect = get_viewport().get_visible_rect()
	
	if discard_container.get_global_rect().has_point(drop_position):
		# 放到棄牌堆
		discard_card(card, true)
	elif deck_container.get_global_rect().has_point(drop_position):
		# 放回牌庫
		discard_card(card, false)
	elif hand_container.get_global_rect().has_point(drop_position):
		# 放回手牌區域
		_update_hand_layout()
	else:
		# 放到遊戲區域（視為打出）
		play_card(card, "場上")

# 按鈕處理函數
func _on_draw_button_pressed() -> void:
	draw_card(true)

func _on_discard_button_pressed() -> void:
	if selected_card:
		discard_card(selected_card, true)
		selected_card = null

func _on_shuffle_button_pressed() -> void:
	shuffle_deck()

func _on_reset_button_pressed() -> void:
	setup_game()

func _on_back_button_pressed() -> void:
	# 返回主選單
	get_tree().change_scene_to_file("res://main.tscn")

# 工具函數
func get_hand_value() -> int:
	var total = 0
	for card in hand:
		total += card.card_value
	return total

func get_hand_by_type() -> Dictionary:
	var by_type = {}
	for card in hand:
		var type = card.card_name.split(" ")[0]  # 取得類型名稱
		if not by_type.has(type):
			by_type[type] = 0
		by_type[type] += 1
	return by_type

func can_play_card(card: Card, requirement: int = 0) -> bool:
	# 檢查是否可以打出卡牌（示例：需要足夠的資源）
	return card.card_value >= requirement

func auto_discard_worst() -> void:
	# 自動棄置數值最低的卡牌
	if hand.is_empty():
		return
	
	var worst_card = hand[0]
	for card in hand:
		if card.card_value < worst_card.card_value:
			worst_card = card
	
	discard_card(worst_card, true)

func draw_multiple(count: int) -> void:
	# 抽多張牌
	for i in range(count):
		if hand.size() >= max_hand_size or deck.is_empty():
			break
		draw_card(true)
		await get_tree().create_timer(0.2).timeout