# grid_movement.gd
# 格子移動機制演示
# 實現棋盤網格上的棋子移動功能

extends Node2D
class_name GridMovementDemo

# 信號定義
signal piece_moved(piece, from_grid, to_grid)
signal turn_changed(player_index)
signal game_over(winner_index)

# 匯出變數
@export var grid_size: int = 8  # 棋盤大小 (8x8)
@export var tile_size: int = 80  # 格子大小
@export var max_players: int = 2  # 最大玩家數量
@export var movement_range: int = 3  # 每次移動的最大距離

# 節點引用
@onready var background: ColorRect = $Background
@onready var canvas_layer: CanvasLayer = $CanvasLayer
@onready var ui_container: Control = $CanvasLayer/UIContainer
@onready var title_label: Label = $CanvasLayer/UIContainer/VBoxContainer/TitleLabel
@onready var game_area: Control = $CanvasLayer/UIContainer/VBoxContainer/GameArea
@onready var control_panel: HBoxContainer = $CanvasLayer/UIContainer/VBoxContainer/ControlPanel
@onready var info_panel: Control = $CanvasLayer/UIContainer/VBoxContainer/InfoPanel
@onready var back_button: Button = $CanvasLayer/UIContainer/VBoxContainer/ControlPanel/BackButton
@onready var reset_button: Button = $CanvasLayer/UIContainer/VBoxContainer/ControlPanel/ResetButton
@onready var next_turn_button: Button = $CanvasLayer/UIContainer/VBoxContainer/ControlPanel/NextTurnButton
@onready var grid_container: GridContainer = $CanvasLayer/UIContainer/VBoxContainer/GameArea/GridContainer

# 遊戲狀態變數
var current_player: int = 0
var players: Array = []
var grid: Array = []  # 2D 網格陣列
var pieces: Array = []  # 所有棋子
var selected_piece: Node2D = null
var valid_moves: Array = []  # 有效移動位置
var game_active: bool = true

func _ready() -> void:
	# 檢查節點是否存在
	if not background:
		push_error("Background 節點不存在！")
		return
	
	if not title_label:
		push_error("TitleLabel 節點不存在！")
		return
	
	if not grid_container:
		push_error("GridContainer 節點不存在！")
		return
	
	# 設定背景顏色
	background.color = Constants.COLORS.BACKGROUND
	
	# 設定標題
	title_label.text = "格子移動 (Grid Movement)"
	
	# 初始化玩家
	_initialize_players()
	
	# 初始化棋盤網格
	_initialize_grid()
	
	# 初始化棋子
	_initialize_pieces()
	
	# 連接按鈕信號
	back_button.pressed.connect(_on_back_button_pressed)
	reset_button.pressed.connect(_on_reset_button_pressed)
	next_turn_button.pressed.connect(_on_next_turn_button_pressed)
	
	# 更新資訊面板
	_update_info_panel()

func _process(_delta: float) -> void:
	# 空函數，避免未使用參數警告
	pass

func _initialize_players() -> void:
	players.clear()
	for i in range(max_players):
		var player = {
			"index": i,
			"color": Constants.get_player_color(i),
			"pieces": [],
			"score": 0
		}
		players.append(player)

func _initialize_grid() -> void:
	# 清空現有網格
	for child in grid_container.get_children():
		child.queue_free()
	
	grid.clear()
	grid_container.columns = grid_size
	
	# 創建網格
	for y in range(grid_size):
		var row = []
		for x in range(grid_size):
			# 創建格子
			var tile_scene = load(Constants.SCENE_PATHS.TILE)
			var tile = tile_scene.instantiate()
			grid_container.add_child(tile)
			
			# 設定格子屬性
			tile.tile_name = "(%d, %d)" % [x, y]
			tile.tile_value = 0
			
			# 使用 set_deferred 設定格子顏色（棋盤格效果）
			if (x + y) % 2 == 0:
				tile.background.set_deferred("color", Constants.COLORS.PANEL)
			else:
				tile.background.set_deferred("color", Constants.COLORS.PANEL.darkened(0.1))
			
			# 連接點擊信號
			tile.tile_selected.connect(_on_tile_selected.bind(tile, Vector2(x, y)))
			
			row.append(tile)
		grid.append(row)

func _initialize_pieces() -> void:
	# 清空現有棋子
	for piece in pieces:
		piece.queue_free()
	pieces.clear()
	
	# 為每個玩家創建棋子
	for player_index in range(max_players):
		var player = players[player_index]
		player.pieces.clear()
		
		# 根據玩家數量決定初始位置
		var start_positions = []
		if max_players == 2:
			# 2 玩家：對角線放置
			if player_index == 0:
				start_positions = [Vector2(1, 1), Vector2(1, 2), Vector2(2, 1)]
			else:
				start_positions = [Vector2(grid_size-2, grid_size-2), Vector2(grid_size-2, grid_size-3), Vector2(grid_size-3, grid_size-2)]
		else:
			# 多玩家：四角放置
			if player_index == 0:
				start_positions = [Vector2(1, 1), Vector2(1, 2)]
			elif player_index == 1:
				start_positions = [Vector2(grid_size-2, 1), Vector2(grid_size-2, 2)]
			elif player_index == 2:
				start_positions = [Vector2(1, grid_size-2), Vector2(2, grid_size-2)]
			elif player_index == 3:
				start_positions = [Vector2(grid_size-2, grid_size-2), Vector2(grid_size-3, grid_size-2)]
		
		# 創建棋子
		for i in range(start_positions.size()):
			var pos = start_positions[i]
			_create_piece(player_index, pos, i)

func _create_piece(player_index: int, grid_pos: Vector2, piece_index: int) -> void:
	# 載入棋子場景
	var token_scene = load(Constants.SCENE_PATHS.TOKEN)
	var piece = token_scene.instantiate()
	game_area.add_child(piece)
	
	# 設定棋子屬性
	piece.token_name = "玩家 %d - 棋子 %d" % [player_index + 1, piece_index + 1]
	piece.token_value = piece_index + 1
	
	# 使用 set_deferred 設定棋子擁有者
	piece.set_deferred("owner_index", player_index)
	piece.background.set_deferred("color", Constants.get_player_color(player_index))
	
	# 設定棋子位置
	_set_piece_position(piece, grid_pos)
	
	# 連接點擊信號
	piece.token_clicked.connect(_on_piece_clicked.bind(piece))
	
	# 儲存棋子
	pieces.append(piece)
	players[player_index].pieces.append({
		"piece": piece,
		"grid_pos": grid_pos
	})
	
	# 更新格子顯示
	_update_tile_display(grid_pos)

func _set_piece_position(piece: Node2D, grid_pos: Vector2) -> void:
	# 計算棋子在遊戲區域中的實際位置
	var tile = grid[grid_pos.y][grid_pos.x]
	var tile_global_pos = tile.global_position
	var tile_size_vec = Vector2(tile_size, tile_size)
	
	# 使用常數中的 TOKEN_SIZE 計算棋子大小
	var token_size = Constants.GAME_SETTINGS.TOKEN_SIZE
	var token_size_vec = Vector2(token_size, token_size)
	
	# 設定棋子位置（居中）
	piece.position = tile_global_pos + tile_size_vec / 2.0 - token_size_vec / 2.0
	
	# 儲存網格位置
	piece.grid_position = grid_pos

func _on_piece_clicked(piece: Node2D) -> void:
	if not game_active:
		return
	
	# 檢查是否輪到該棋子的玩家
	var piece_owner = piece.owner_index
	if piece_owner != current_player:
		return
	
	# 選擇棋子
	if selected_piece == piece:
		# 取消選擇
		_deselect_piece()
	else:
		# 選擇新棋子
		_select_piece(piece)

func _select_piece(piece: Node2D) -> void:
	# 取消之前選擇的棋子
	if selected_piece:
		_deselect_piece()
	
	# 選擇新棋子
	selected_piece = piece
	piece.select()
	
	# 計算有效移動位置
	_calculate_valid_moves(piece.grid_position)
	
	# 高亮顯示有效移動位置
	_highlight_valid_moves()

func _deselect_piece() -> void:
	if selected_piece:
		selected_piece.deselect()
		selected_piece = null
	
	# 清除有效移動高亮
	_clear_valid_moves_highlight()

func _calculate_valid_moves(start_pos: Vector2) -> void:
	valid_moves.clear()
	
	# 簡單的移動規則：可以移動到相鄰的格子（上下左右）
	var directions = [
		Vector2(0, -1),  # 上
		Vector2(1, 0),   # 右
		Vector2(0, 1),   # 下
		Vector2(-1, 0)   # 左
	]
	
	# 檢查每個方向
	for dir in directions:
		for distance in range(1, movement_range + 1):
			var target_pos = start_pos + dir * distance
			
			# 檢查是否在棋盤範圍內
			if _is_within_grid(target_pos):
				# 檢查目標位置是否已有棋子
				if not _has_piece_at(target_pos):
					valid_moves.append(target_pos)
				else:
					# 如果遇到棋子，停止在這個方向繼續檢查
					break
			else:
				# 如果超出棋盤，停止在這個方向繼續檢查
				break

func _is_within_grid(pos: Vector2) -> bool:
	return pos.x >= 0 and pos.x < grid_size and pos.y >= 0 and pos.y < grid_size

func _has_piece_at(grid_pos: Vector2) -> bool:
	for player in players:
		for piece_data in player.pieces:
			if piece_data.grid_pos == grid_pos:
				return true
	return false

func _highlight_valid_moves() -> void:
	for move_pos in valid_moves:
		var tile = grid[move_pos.y][move_pos.x]
		# 高亮顯示有效移動位置
		tile.background.color = Constants.COLORS.BUTTON_HOVER

func _clear_valid_moves_highlight() -> void:
	for y in range(grid_size):
		for x in range(grid_size):
			var tile = grid[y][x]
			# 恢復原始顏色（棋盤格效果）
			if (x + y) % 2 == 0:
				tile.background.color = Constants.COLORS.PANEL
			else:
				tile.background.color = Constants.COLORS.PANEL.darkened(0.1)

func _on_tile_selected(_tile: Node, grid_pos: Vector2) -> void:
	if not game_active or not selected_piece:
		return
	
	# 檢查是否點擊了有效移動位置
	if grid_pos in valid_moves:
		# 移動棋子
		_move_piece(selected_piece, grid_pos)
		
		# 清除選擇
		_deselect_piece()
		
		# 發送信號
		piece_moved.emit(selected_piece, selected_piece.grid_position, grid_pos)
		
		# 檢查遊戲是否結束
		_check_game_over()

func _move_piece(piece: Node2D, target_pos: Vector2) -> void:
	var old_pos = piece.grid_position
	
	# 更新玩家數據中的棋子位置
	for player in players:
		for i in range(player.pieces.size()):
			if player.pieces[i].piece == piece:
				player.pieces[i].grid_pos = target_pos
				break
	
	# 更新棋子網格位置
	piece.grid_position = target_pos
	
	# 使用 Tween 動畫移動棋子
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	
	# 計算目標位置
	var tile = grid[target_pos.y][target_pos.x]
	var tile_global_pos = tile.global_position
	var tile_size_vec = Vector2(tile_size, tile_size)
	
	# 使用常數中的 TOKEN_SIZE 計算棋子大小
	var token_size = Constants.GAME_SETTINGS.TOKEN_SIZE
	var token_size_vec = Vector2(token_size, token_size)
	
	var target_position = tile_global_pos + tile_size_vec / 2.0 - token_size_vec / 2.0
	
	# 執行移動動畫
	tween.tween_property(piece, "position", target_position, Constants.GAME_SETTINGS.ANIMATION_DURATION)
	
	# 更新格子顯示
	_update_tile_display(old_pos)
	_update_tile_display(target_pos)

func _update_tile_display(grid_pos: Vector2) -> void:
	var tile = grid[grid_pos.y][grid_pos.x]
	
	# 檢查該位置是否有棋子
	var piece_at_pos = _get_piece_at(grid_pos)
	if piece_at_pos:
		# 顯示棋子資訊
		var owner_index = piece_at_pos.owner_index
		tile.tile_value = owner_index + 1
		tile.value_label.text = "P%d" % (owner_index + 1)
	else:
		# 清空顯示
		tile.tile_value = 0
		tile.value_label.text = ""

func _get_piece_at(grid_pos: Vector2) -> Node2D:
	for player in players:
		for piece_data in player.pieces:
			if piece_data.grid_pos == grid_pos:
				return piece_data.piece
	return null

func _on_next_turn_button_pressed() -> void:
	if not game_active:
		return
	
	# 切換到下一個玩家
	current_player = (current_player + 1) % max_players
	
	# 發送信號
	turn_changed.emit(current_player)
	
	# 更新資訊面板
	_update_info_panel()
	
	# 清除當前選擇
	_deselect_piece()

func _check_game_over() -> void:
	# 簡單的勝利條件：玩家到達對面底線
	for player_index in range(max_players):
		var player = players[player_index]
		for piece_data in player.pieces:
			var pos = piece_data.grid_pos
			
			# 檢查是否到達對面底線
			if player_index == 0 and pos.y == grid_size - 1:
				_end_game(player_index)
				return
			elif player_index == 1 and pos.y == 0:
				_end_game(player_index)
				return

func _end_game(winner_index: int) -> void:
	game_active = false
	
	# 發送遊戲結束信號
	game_over.emit(winner_index)
	
	# 更新資訊面板
	_update_info_panel()
	
	# 顯示勝利訊息
	title_label.text = "遊戲結束！玩家 %d 獲勝！" % (winner_index + 1)

func _update_info_panel() -> void:
	if info_panel.has_method("update_info"):
		var info_text = "當前玩家: 玩家 %d\n" % (current_player + 1)
		info_text += "棋子數量: %d\n" % pieces.size()
		info_text += "移動範圍: %d 格\n" % movement_range
		
		if not game_active:
			info_text += "\n遊戲已結束"
		
		info_panel.update_info(info_text)

func _on_back_button_pressed() -> void:
	# 返回主選單
	get_tree().change_scene_to_file(Constants.SCENE_PATHS.MAIN_MENU)

func _on_reset_button_pressed() -> void:
	# 重置遊戲
	game_active = true
	current_player = 0
	selected_piece = null
	valid_moves.clear()
	
	# 重新初始化
	_initialize_grid()
	_initialize_pieces()
	
	# 更新標題
	title_label.text = "格子移動 (Grid Movement)"
	
	# 更新資訊面板
	_update_info_panel()
	
	# 發送回合變更信號
	turn_changed.emit(current_player)