# constants.gd
# 桌遊機制專案通用常數定義

extends Node

# 顏色定義
const COLORS = {
	"BACKGROUND": Color("#1a1a2e"),
	"PANEL": Color("#16213e"),
	"CARD": Color("#0f3460"),
	"BUTTON": Color("#e94560"),
	"BUTTON_HOVER": Color("#ff6b8b"),
	"TEXT": Color("#ffffff"),
	"TEXT_SECONDARY": Color("#b0b0b0"),
	"GRID_LINE": Color("#2d4059"),
	"PLAYER_1": Color("#ff6b6b"),
	"PLAYER_2": Color("#4ecdc4"),
	"PLAYER_3": Color("#ffe66d"),
	"PLAYER_4": Color("#95e1d3"),
	"RESOURCE_WOOD": Color("#8b4513"),
	"RESOURCE_STONE": Color("#808080"),
	"RESOURCE_GOLD": Color("#ffd700"),
	"RESOURCE_FOOD": Color("#90ee90"),
}

# 遊戲設定
const GAME_SETTINGS = {
	"GRID_SIZE": 64,
	"CARD_WIDTH": 120,
	"CARD_HEIGHT": 180,
	"TOKEN_SIZE": 32,
	"DICE_SIZE": 48,
	"TILE_SIZE": 80,
	"ANIMATION_DURATION": 0.3,
	"MAX_PLAYERS": 4,
	"MIN_PLAYERS": 2,
}

# 機制類型
const MECHANIC_TYPES = {
	"CORE": "core",
	"STRATEGY": "strategy",
	"SPECIAL": "special",
}

# 玩家狀態
const PLAYER_STATES = {
	"ACTIVE": "active",
	"WAITING": "waiting",
	"ELIMINATED": "eliminated",
	"WINNER": "winner",
}

# 資源類型
const RESOURCE_TYPES = {
	"WOOD": "wood",
	"STONE": "stone",
	"GOLD": "gold",
	"FOOD": "food",
	"VICTORY_POINTS": "victory_points",
	"ACTION_POINTS": "action_points",
}

# 卡牌類型
const CARD_TYPES = {
	"ACTION": "action",
	"RESOURCE": "resource",
	"VICTORY": "victory",
	"SPECIAL": "special",
}

# 骰子面數
const DICE_TYPES = {
	"D4": 4,
	"D6": 6,
	"D8": 8,
	"D10": 10,
	"D12": 12,
	"D20": 20,
}

# 輸入動作
const INPUT_ACTIONS = {
	"SELECT": "select",
	"DRAG": "drag",
	"DROP": "drop",
	"ROLL": "roll",
	"DRAW": "draw",
	"PLAY": "play",
	"PASS": "pass",
}

# 信號名稱
const SIGNALS = {
	"CARD_PLAYED": "card_played",
	"DICE_ROLLED": "dice_rolled",
	"RESOURCE_CHANGED": "resource_changed",
	"TURN_CHANGED": "turn_changed",
	"PLAYER_ELIMINATED": "player_eliminated",
	"GAME_OVER": "game_over",
	"MECHANIC_SELECTED": "mechanic_selected",
}

# 場景路徑
const SCENE_PATHS = {
	"MAIN_MENU": "res://main.tscn",
	"CARD": "res://common/components/card.tscn",
	"DICE": "res://common/components/dice.tscn",
	"TOKEN": "res://common/components/token.tscn",
	"TILE": "res://common/components/tile.tscn",
	"BACK_BUTTON": "res://common/ui/back_button.tscn",
	"INFO_PANEL": "res://common/ui/info_panel.tscn",
}

# 工具函數
func get_player_color(player_index: int) -> Color:
	var colors = [
		COLORS.PLAYER_1,
		COLORS.PLAYER_2,
		COLORS.PLAYER_3,
		COLORS.PLAYER_4
	]
	return colors[player_index % colors.size()]

func format_resource_amount(resource_type: String, amount: int) -> String:
	var icons = {
		RESOURCE_TYPES.WOOD: "🪵",
		RESOURCE_TYPES.STONE: "🪨",
		RESOURCE_TYPES.GOLD: "💰",
		RESOURCE_TYPES.FOOD: "🍎",
		RESOURCE_TYPES.VICTORY_POINTS: "🏆",
		RESOURCE_TYPES.ACTION_POINTS: "⚡",
	}
	
	if resource_type in icons:
		return "%s %d" % [icons[resource_type], amount]
	else:
		return "%s: %d" % [resource_type.capitalize(), amount]

func lerp_color(start: Color, end: Color, t: float) -> Color:
	return Color(
		lerpf(start.r, end.r, t),
		lerpf(start.g, end.g, t),
		lerpf(start.b, end.b, t),
		lerpf(start.a, end.a, t)
	)
