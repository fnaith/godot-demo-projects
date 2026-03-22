# dice_rolling.gd
# 骰子擲投機制實作 - 簡化版本

extends Node2D
class_name DiceRollingDemo

signal dice_rolled(result: int)
signal dice_stopped
signal dice_animation_started
signal dice_animation_ended

@export var dice_count: int = 1
@export var dice_sides: int = 6
@export var auto_roll_on_ready: bool = false
@export var roll_animation_duration: float = 1.0
@export var bounce_animation: bool = true
@export var max_bounces: int = 3

var dice_scene = preload("res://common/components/dice.tscn")
var dice_instances: Array = []
var current_results: Array = []
var roll_history: Array = []
var is_rolling: bool = false
var total_rolls: int = 0

func _ready() -> void:
	# 等待一幀確保所有節點都已載入
	await get_tree().process_frame
	
	print("開始查找 DiceContainer 節點...")
	
	# 嘗試多種方式獲取節點引用
	var dice_container = get_node_or_null("CanvasLayer/MainContainer/ContentPanel/VBoxContainer/DiceArea/DiceContainer")
	print("路徑1結果: ", dice_container)
	
	# 如果找不到，嘗試其他路徑
	if not dice_container:
		dice_container = get_node_or_null("DiceContainer")
		print("路徑2結果: ", dice_container)
	
	if not dice_container:
		# 使用更簡單的查找方式
		dice_container = _find_node_by_name("DiceContainer")
		print("路徑3結果: ", dice_container)
	
	var roll_button = get_node_or_null("CanvasLayer/MainContainer/ContentPanel/VBoxContainer/UI/ButtonContainer/RollButton")
	if not roll_button:
		roll_button = get_node_or_null("RollButton")
	if not roll_button:
		roll_button = _find_node_by_name("RollButton")
	
	var result_label = get_node_or_null("CanvasLayer/MainContainer/ContentPanel/VBoxContainer/UI/ResultContainer/ResultLabel")
	if not result_label:
		result_label = get_node_or_null("ResultLabel")
	if not result_label:
		result_label = _find_node_by_name("ResultLabel")
	
	var history_label = get_node_or_null("CanvasLayer/MainContainer/ContentPanel/VBoxContainer/UI/HistoryContainer/HistoryLabel")
	if not history_label:
		history_label = get_node_or_null("HistoryLabel")
	if not history_label:
		history_label = _find_node_by_name("HistoryLabel")
	
	var back_button = get_node_or_null("CanvasLayer/MainContainer/ContentPanel/VBoxContainer/BackButtonContainer/BackButton")
	if not back_button:
		back_button = get_node_or_null("BackButton")
	if not back_button:
		back_button = _find_node_by_name("BackButton")
	
	# 檢查節點是否存在
	if not dice_container:
		push_error("無法找到 DiceContainer 節點！")
		print("當前場景樹結構:")
		_print_scene_tree(self, 0)
		return
	if not roll_button:
		push_error("無法找到 RollButton 節點！")
		return
	if not result_label:
		push_error("無法找到 ResultLabel 節點！")
		return
	if not history_label:
		push_error("無法找到 HistoryLabel 節點！")
		return
	if not back_button:
		push_error("無法找到 BackButton 節點！")
		return
	
	print("所有節點找到成功！")
	
	# 建立骰子
	_create_dice(dice_container)
	
	# 連接按鈕信號
	roll_button.pressed.connect(_on_roll_button_pressed.bind(dice_container, result_label, history_label))
	back_button.pressed.connect(_on_back_button_pressed)
	
	# 初始狀態
	_update_result_display(result_label)
	
	# 如果需要自動擲骰
	if auto_roll_on_ready:
		await get_tree().create_timer(0.5).timeout
		roll_dice(dice_container, result_label, history_label)

# 輔助函數：遞迴查找節點
func _find_node_by_name(node_name: String) -> Node:
	return _find_node_recursive(self, node_name)

func _find_node_recursive(node: Node, target_name: String) -> Node:
	if node.name == target_name:
		return node
	
	for child in node.get_children():
		var result = _find_node_recursive(child, target_name)
		if result:
			return result
	
	return null

# 輔助函數：打印場景樹
func _print_scene_tree(node: Node, depth: int) -> void:
	var indent = "  ".repeat(depth)
	print(indent + "└─ " + node.name + " (" + node.get_class() + ")")
	
	for child in node.get_children():
		_print_scene_tree(child, depth + 1)

func _create_dice(dice_container: Node2D) -> void:
	# 清除現有的骰子
	for dice in dice_instances:
		dice.queue_free()
	dice_instances.clear()
	
	# 建立新的骰子
	for i in range(dice_count):
		var dice = dice_scene.instantiate()
		dice.name = "Dice%d" % (i + 1)
		dice_container.add_child(dice)
		dice_instances.append(dice)
		
		# 設定骰子位置
		var spacing = 120
		var start_x = -((dice_count - 1) * spacing) / 2.0
		dice.position = Vector2(start_x + i * spacing, 0)
		
		# 設定骰子面數
		if dice.has_method("set_sides"):
			dice.set_sides(dice_sides)
		
		# 設定初始值
		if dice.has_method("set_value"):
			dice.set_value(1)

func roll_dice(dice_container: Node2D, result_label: Label, history_label: RichTextLabel) -> void:
	if is_rolling:
		return
	
	is_rolling = true
	total_rolls += 1
	dice_animation_started.emit()
	
	# 清除之前的結果
	current_results.clear()
	
	# 隨機生成結果
	for i in range(dice_count):
		var result = randi_range(1, dice_sides)
		current_results.append(result)
	
	# 開始動畫
	_start_roll_animation(dice_container, result_label, history_label)

func _start_roll_animation(dice_container: Node2D, result_label: Label, history_label: RichTextLabel) -> void:
	var tween = create_tween()
	tween.set_parallel(true)
	
	# 為每個骰子設定動畫
	for i in range(dice_instances.size()):
		var dice = dice_instances[i]
		var result = current_results[i]
		
		# 旋轉動畫
		tween.tween_property(dice, "rotation", dice.rotation + TAU * 2, roll_animation_duration)
		
		# 彈跳動畫（如果啟用）
		if bounce_animation:
			var bounces = randi_range(1, max_bounces)
			for bounce in range(bounces):
				var bounce_height = 30.0 * (1.0 - float(bounce) / bounces)
				var bounce_time = roll_animation_duration / (bounces * 2)
				var start_time = bounce_time * bounce * 2
				
				# 向上
				tween.tween_property(dice, "position:y", dice.position.y - bounce_height, bounce_time).set_delay(start_time)
				# 向下
				tween.tween_property(dice, "position:y", dice.position.y, bounce_time).set_delay(start_time + bounce_time)
		
		# 更新骰子顯示（在動畫結束時）
		tween.tween_callback(_update_dice_value.bind(dice, result)).set_delay(roll_animation_duration - 0.1)
	
	# 動畫結束後更新顯示
	tween.tween_callback(_on_roll_animation_completed.bind(result_label, history_label)).set_delay(roll_animation_duration)

func _update_dice_value(dice: Node, value: int) -> void:
	if dice.has_method("set_value"):
		dice.set_value(value)

func _on_roll_animation_completed(result_label: Label, history_label: RichTextLabel) -> void:
	is_rolling = false
	
	# 計算總和
	var total = 0
	for result in current_results:
		total += result
	
	# 更新顯示
	_update_result_display(result_label)
	
	# 記錄歷史
	_add_to_history(total, history_label)
	
	# 發送信號
	dice_rolled.emit(total)
	dice_stopped.emit()
	dice_animation_ended.emit()

func _update_result_display(result_label: Label) -> void:
	if current_results.is_empty():
		result_label.text = "點擊擲骰子開始"
		return
	
	var total = 0
	var result_text = ""
	
	if dice_count == 1:
		total = current_results[0]
		result_text = "結果: %d" % total
	else:
		for i in range(current_results.size()):
			total += current_results[i]
			if i > 0:
				result_text += " + "
			result_text += str(current_results[i])
		
		result_text += " = %d" % total
	
	result_label.text = result_text

func _add_to_history(total: int, history_label: RichTextLabel) -> void:
	# 建立歷史項目
	var history_item = {
		"roll_number": total_rolls,
		"results": current_results.duplicate(),
		"total": total,
		"timestamp": Time.get_datetime_string_from_system()
	}
	
	# 添加到歷史
	roll_history.append(history_item)
	
	# 更新顯示（只顯示最近10次）
	_update_history_display(history_label)

func _update_history_display(history_label: RichTextLabel) -> void:
	var display_count = min(10, roll_history.size())
	var start_index = max(0, roll_history.size() - display_count)
	
	var history_text = "[b]擲骰歷史:[/b]\n"
	
	for i in range(start_index, roll_history.size()):
		var item = roll_history[i]
		var results_text = ""
		
		if item.results.size() == 1:
			results_text = str(item.results[0])
		else:
			results_text = str(item.results) + " = " + str(item.total)
		
		history_text += "%d. %s\n" % [item.roll_number, results_text]
	
	history_label.text = history_text

func _on_roll_button_pressed(dice_container: Node2D, result_label: Label, history_label: RichTextLabel) -> void:
	roll_dice(dice_container, result_label, history_label)

func _on_back_button_pressed() -> void:
	# 返回主選單
	get_tree().change_scene_to_file("res://main_simple.tscn")

# 公開函數
func set_dice_count(count: int, dice_container: Node2D, result_label: Label) -> void:
	dice_count = count
	_create_dice(dice_container)
	_update_result_display(result_label)

func set_dice_sides(sides: int) -> void:
	dice_sides = sides
	for dice in dice_instances:
		if dice.has_method("set_sides"):
			dice.set_sides(sides)

func get_total_rolls() -> int:
	return total_rolls

func get_average_result() -> float:
	if roll_history.is_empty():
		return 0.0
	
	var total = 0.0
	for item in roll_history:
		total += item.total
	
	return total / roll_history.size()

func get_result_distribution() -> Dictionary:
	var distribution = {}
	
	for item in roll_history:
		var total = item.total
		if distribution.has(total):
			distribution[total] += 1
		else:
			distribution[total] = 1
	
	return distribution

func clear_history(history_label: RichTextLabel, result_label: Label) -> void:
	roll_history.clear()
	total_rolls = 0
	_update_history_display(history_label)
	_update_result_display(result_label)

# 工具函數
func simulate_rolls(count: int, dice_container: Node2D, result_label: Label, history_label: RichTextLabel) -> Array:
	var results = []
	
	for i in range(count):
		roll_dice(dice_container, result_label, history_label)
		await dice_stopped
		results.append(current_results.duplicate())
	
	return results