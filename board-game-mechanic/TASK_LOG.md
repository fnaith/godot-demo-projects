# Board Game Mechanic - 任務記錄

## 專案目標

將 BoardGameGeek 的所有桌遊機制（180+）實作成可互動的 Godot 場景，供未來專案參考與重用。

## 決策記錄

| 項目 | 決策 |
|------|------|
| 範圍 | 分階段逐步實作所有機制 |
| 實作深度 | 可互動原型 |
| 視覺風格 | 2D 為主（必要時可用 3D） |
| 素材 | 零圖片（ColorRect + Label + Unicode） |
| 動畫 | Tween（程式碼） |
| 元件溝通 | 信號串接 |
| Input | InputEvent 直接處理 |
| Node | 簡單優先（必要時可用其他） |

## 技術規格

### Godot 環境
- 版本: 4.6
- 渲染器: GL Compatibility
- 物理引擎: Jolt Physics
- 解析度: 1920 × 1080

### 優先使用的 Node
```
結構: Node, Node2D, CanvasLayer
視覺: ColorRect, Label, RichTextLabel
UI:   Control, Button, Panel
互動: Area2D, CollisionShape2D (RectangleShape2D)
其他: Timer, Tween (程式碼)
```

### 可用的 Node
```
Sprite2D, TextureButton, Line2D, 其他 2D Nodes
```

### 必要時可用
```
3D Nodes, Polygon2D, Container 系列, AnimationPlayer
```

---

## 進度追蹤

### 第 0 階段：基礎建設

- [x] TASK_LOG.md - 任務進度追蹤
- [x] MECHANICS_LIST.md - 完整機制清單
- [x] common/constants.gd - 常數定義
- [x] /card.gd + .tscn
- [x] common/components/dice.gd + .tscn
- [x] common/components/token.gd + .tscn
- [x] common/components/tile.gd + .tscn
- [x] common/ui/back_button.gd + .tscn
- [x] common/ui/info_panel.gd + .tscn
- [x] main.tscn - 主選單

### 第 1 階段：核心機制（10 個）

- [x] dice_rolling - 骰子擲投
- [x] hand_management - 手牌管理
- [x] set_collection - 成套收集（有編碼問題，需修復）
- [x] action_points - 行動點數
- [x] grid_movement - 格子移動
- [ ] roll_and_move - 擲骰移動
- [ ] deck_building - 牌庫構築
- [ ] turn_order - 回合順序
- [ ] victory_points - 勝利點數
- [ ] player_elimination - 玩家淘汰

### 第 2 階段：策略機制（15 個）

- [ ] worker_placement - 工人擺放
- [ ] area_control - 區域控制
- [ ] auction_bidding - 競標
- [ ] card_drafting - 卡牌輪抽
- [ ] resource_management - 資源管理
- [ ] tile_placement - 板塊放置
- [ ] route_building - 路線建設
- [ ] trading - 交易
- [ ] voting - 投票
- [ ] variable_player_powers - 可變玩家能力
- [ ] hidden_roles - 隱藏角色
- [ ] simultaneous_action - 同時行動
- [ ] push_your_luck - 得寸進尺
- [ ] take_that - 直接攻擊
- [ ] pattern_building - 圖案建構

### 第 3+ 階段

詳見 MECHANICS_LIST.md

---

## 變更日誌

### 2026-03-22
- 建立專案基礎結構
- 建立 TASK_LOG.md
- 修復 common/components 場景檔案：
  - card.tscn：簡化結構，確保所有 GDScript 引用的節點都存在
  - dice.tscn：簡化結構，移除不必要的節點
  - token.tscn：修正 ValueLabel 路徑（$CenterContainer/ValueLabel）
  - tile.tscn：修正 NameLabel 和 ValueLabel 路徑（$Content/NameLabel, $Content/ValueLabel）
- 設定 Constants 為 Autoload
- 修正 main.gd 節點引用問題
- 修復 info_panel.gd 中的節點路徑問題（$VBoxContainer/TitleLabel → $VBoxContainer/Header/TitleLabel）
- 建立簡單測試場景 main_simple.tscn 並成功運行專案
- 專案現在可以正常啟動並顯示主選單
- 實作第1階段第一個機制：骰子擲投（Dice Rolling）
  - 建立 dice_rolling/dice_rolling.gd 腳本
  - 建立 dice_rolling/dice_rolling.tscn 場景
  - 實現完整的骰子擲投功能，包含動畫、歷史記錄、統計等功能
  - 更新主選單以連接骰子擲投場景
- 修復函數簽名衝突錯誤：
  - card.gd：將 set_owner() 重新命名為 set_card_owner() 以避免與 Node 原生類的方法衝突
  - tile.gd：將 get_rotation_degrees() 重新命名為 get_tile_rotation_degrees() 以避免與 Node2D 原生類的方法衝突
  - token.gd：將 set_owner() 重新命名為 set_token_owner() 以避免與 Node 原生類的方法衝突
- 修復 Tween 錯誤：
  - info_panel.gd：修正 _ready() 函數中 Tween 的初始化問題，避免創建空 Tween
  - main.gd：移除 _ready() 函數中不必要的 Tween 創建，延遲到需要時才創建
- 修復 UI 佈局問題：
  - main.tscn：增加 ContentPanel 大小（800x600 → 1000x800）
  - 增加內邊距和間距，避免 UI 元素擠在一起
  - 調整 SubtitleLabel 位置以適應新的面板大小
- 專案成功運行，僅有一個不影響功能的警告（delta 參數未使用）
- 修復骰子擲投場景錯誤：
  - 修復 dice_rolling.gd 中的節點查找問題，添加多種查找方式（完整路徑、簡單路徑、find_child）
  - 更新 project.godot 主要場景設定為 main.tscn（完整主選單）而非 main_simple.tscn（測試場景）
  - 確保主選單正確連接到簡化版骰子擲投場景（dice_rolling_simple.tscn）
  - 解決「無法找到 DiceContainer 節點！」錯誤
- 實作第1階段第二個機制：手牌管理（Hand Management）
  - 建立 hand_management/hand_management.gd 腳本
  - 建立 hand_management/hand_management.tscn 場景
  - 實現完整的手牌管理功能：牌庫管理、手牌管理、棄牌堆管理
  - 實現扇形手牌佈局動畫和卡牌拖曳功能
  - 修復 card.gd 中的拖曳邏輯錯誤（is_dragging 從未設定為 true）
  - 修正 hand_management.gd 中的信號參數不匹配問題
  - 修正 _create_deck 函數中的屬性設定問題（使用 card_type 而非 card_color）
  - 更新主選單以連接手牌管理場景
- 實作第1階段第三個機制：成套收集（Set Collection）
  - 建立 set_collection/set_collection.gd 腳本
  - 建立 set_collection/set_collection.tscn 場景
  - 實現成套收集機制：卡片收集、套裝組合、分數計算
  - 實現卡片拖曳、套裝高亮顯示、分數追蹤功能
  - 發現編碼問題導致場景無法運行（第163行解析錯誤）
- 實作第1階段第四個機制：行動點數（Action Points）
  - 建立 action_points/action_points.gd 腳本
  - 建立 action_points/action_points.tscn 場景
  - 實現行動點數機制：玩家管理、行動點數系統、回合系統
  - 實現8種不同行動（移動、攻擊、防禦、治療、強化、偵查、休息、特殊技能）
  - 實現行動效果系統（攻擊傷害、防禦提升、治療恢復等）
  - 實現玩家面板、行動按鈕、資訊顯示等UI系統
  - 更新主選單以連接行動點數場景
- 實作第1階段第五個機制：格子移動（Grid Movement）
  - 建立 grid_movement/grid_movement.gd 腳本
  - 建立 grid_movement/grid_movement.tscn 場景
  - 實現格子移動機制：棋盤網格系統、棋子移動、回合系統
  - 實現棋子選擇、有效移動位置計算、移動動畫
  - 實現簡單的勝利條件（到達對面底線）
  - 修復未使用參數警告和節點引用問題
  - 更新主選單以連接格子移動場景
