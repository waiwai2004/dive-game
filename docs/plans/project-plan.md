# 类杀戮尖塔游戏开发分工文档（5 人团队版）

## 项目概述

基于 Godot 引擎开发的类杀戮尖塔卡牌游戏，采用模块化架构设计，包含核心架构、角色系统、卡牌系统、效果系统、战斗系统、敌人 AI 系统和 UI 系统等核心模块。

---

## 团队成员分工总览

<table>
<tr>
<td>成员<br/></td><td>负责模块<br/></td><td>优先级<br/></td><td>依赖模块<br/></td></tr>
<tr>
<td>奇军<br/></td><td>1. 核心架构与数据管理2. 角色系统<br/></td><td>P0<br/></td><td>无核心架构<br/></td></tr>
<tr>
<td>zjw<br/></td><td>3. 卡牌系统4. 数据管理与处理<br/></td><td>P0<br/></td><td>核心架构、角色系统<br/></td></tr>
<tr>
<td>抓青蛙<br/></td><td>5. 效果与Buff系统<br/></td><td>P1<br/></td><td>核心架构、角色系统<br/></td></tr>
<tr>
<td>歪歪<br/></td><td>6. 敌人AI与意图系统7. 战斗系统<br/></td><td>P1<br/></td><td>角色系统、效果系统所有系统<br/></td></tr>
<tr>
<td>kk<br/></td><td>8. UI系统<br/></td><td>P2<br/></td><td>所有系统<br/></td></tr>
</table>

---

## 奇军：核心架构与数据管理 + 角色系统

### 模块 1：核心架构与数据管理

**工作内容**：搭建项目基础框架，实现数据管理和场景管理

#### 1.1 文件位置

```
source/
├── auto/
│   ├── game_instance.gd       # 游戏全局实例
│   └── scene_manager.gd       # 场景管理器
├── procedure_manager.gd       # 流程管理器
└── utility/
    └── asset_utility.gd       # 资源工具类
```

#### 1.2 类定义

##### GameInstance（游戏全局实例）

```
class_name GameInstance
extends Node

# 静态变量
static var player: Player           # 玩家实例
static var current_scene: Node      # 当前场景

# 函数
static func create_entity(path: String) -> Node    # 创建实体
static func get_player() -> Player                 # 获取玩家
static func set_player(player: Player) -> void     # 设置玩家
```

##### SceneManager（场景管理器）

```
class_name SceneManager
extends Node

# 变量
var _current_scene: SceneBase       # 当前场景
var _scene_stack: Array             # 场景栈

# 函数
func change_scene(scene_path: String, msg: Dictionary = {}) -> void   # 切换场景
func push_scene(scene_path: String, msg: Dictionary = {}) -> void     # 压入场景
func pop_scene() -> void                                              # 弹出场景
func get_current_scene() -> SceneBase                                 # 获取当前场景
```

##### SceneBase（场景基类）

```
class_name SceneBase
extends Node2D

# 函数（虚函数，子类必须实现）
func _enter(msg: Dictionary = {}) -> void      # 进入场景
func _exit() -> void                           # 退出场景
func _pause() -> void                          # 暂停场景
func _resume() -> void                         # 恢复场景
```

##### DatatableManager（数据表管理器）

```
class_name DatatableManager
extends Node

# 静态变量
static var _datatables: Dictionary   # 数据表缓存

# 静态函数
static func load_datatable(name: String, path: String) -> void                    # 加载数据表
static func get_datatable_row(table_name: String, row_id: String) -> Dictionary   # 获取数据行
static func get_datatable(table_name: String) -> Dictionary                       # 获取整个数据表
```

##### EventBus（事件总线）

```
class_name EventBus
extends Node

# 静态变量
static var _events: Dictionary       # 事件字典

# 静态函数
static func register_event(event_name: String) -> void                            # 注册事件
static func push_event(event_name: String, data: Variant = null) -> void          # 推送事件
static func connect_event(event_name: String, callback: Callable) -> void         # 连接事件
static func disconnect_event(event_name: String, callback: Callable) -> void      # 断开事件
```

#### 1.3 数据表结构（CSV 格式）

##### card.csv（卡牌表）

```
ID,card_name,card_type,cost,card_description,icon,target_type,play_animation,effects,buff_des
编号,卡牌名,卡牌类型,成本,描述,图标,目标类型,施法动作,效果ID列表,BUFF描述
```

##### monster.csv（怪物表）

```
ID,name,enemy_scene,intent_pool
ID,怪物名,怪物场景,意图池
```

##### buff.csv（Buff 表）

```
ID,name,description,is_stacked,buff_type,duration_type,callback_type,icon,effects
编号,效果名,描述,能否堆叠,类型,持续类型,回调类型,图标,效果ID列表
```

##### ability_effect.csv（效果表）

```
ID,effect_name,effect_type,description,target_type,value
编号,效果名,效果类型,描述,目标类型,数值
```

##### combat.csv（战斗配置表）

```
ID,mark_04,mark_05,mark_06
编号,怪物1,怪物2,怪物3
```

### 模块 2：角色系统

**工作内容**：实现角色基类、玩家类和敌人类，包含属性管理和状态管理

#### 2.1 文件位置

```
source/entities/
├── character.gd              # 角色基类
├── character.tscn            # 角色场景
├── player.gd                 # 玩家类
├── player.tscn               # 玩家场景
├── enemy.gd                  # 敌人类
├── enemy.tscn                # 敌人场景
├── character_model.gd        # 角色数据模型
├── player_model.gd           # 玩家数据模型
├── enemy_model.gd            # 敌人数据模型
└── Damage.gd                 # 伤害类
```

#### 2.2 类定义

##### Character（角色基类）

```
class_name Character
extends Node2D

# 导出变量
@export var cha_type: String = ""           # 角色类型

# 内部变量
var cha_id: StringName                      # 角色ID
var _model: CharacterModel                  # 数据模型
var _is_selected: bool = false              # 是否被选中

# 属性（只读）
var current_health: float                   # 当前生命值
var max_health: float                       # 最大生命值
var shielded: int                           # 护盾值
var is_death: bool                          # 是否死亡

# 信号
signal turn_begined                         # 回合开始
signal turn_completed                       # 回合结束
signal damaged                              # 受到伤害
signal shielded_changed                     # 护盾改变
signal died                                 # 死亡

# 函数
func _ready() -> void                       # 初始化
func _begin_combat() -> void                # 开始战斗
func _end_combat() -> void                  # 结束战斗
func _begin_turn() -> void                  # 回合开始
func _end_turn() -> void                    # 回合结束
func add_shielded(value: int) -> void       # 添加护盾
func damage(damage: Damage) -> void         # 受到伤害
func death() -> void                        # 死亡处理
func play_animation_with_reset(anim: StringName) -> void   # 播放动画
func selected() -> void                     # 选中
func unselected() -> void                   # 取消选中
```

##### Player（玩家类）继承自 Character

```
class_name Player
extends Character

# 组件引用
@onready var c_card_system: C_CardSystem    # 卡牌系统

# 属性（只读）
var current_energy: int                     # 当前能量
var max_energy: int                         # 最大能量
var coin: int                               # 货币数量

# 信号
signal energy_changed                       # 能量改变

# 函数
func _ready() -> void                       # 初始化
func _begin_combat() -> void                # 开始战斗
func _begin_turn() -> void                  # 回合开始
func _end_turn() -> void                    # 回合结束
func use_energy(amount: int) -> void        # 使用能量
func reset_energy() -> void                 # 重置能量
```

##### Enemy（敌人类）继承自 Character

```
class_name Enemy
extends Character

# 组件引用
@onready var c_intent_system: C_IntentSystem    # 意图系统
@onready var w_tooltip: MarginContainer         # 提示框

# 函数
func _ready() -> void                       # 初始化
func _begin_turn() -> void                  # 回合开始
func _end_turn() -> void                    # 回合结束
func show_tooltip() -> void                 # 显示意图提示
```

##### CharacterModel（角色数据模型）

```
class_name CharacterModel
extends RefCounted

# 属性
var cha_id: StringName                      # 角色ID
var cha_name: String                        # 角色名
var max_health: float                       # 最大生命值
var current_health: float                   # 当前生命值
var shielded: int                           # 护盾值

# 函数
func _init(id: StringName) -> void          # 构造函数
```

##### PlayerModel（玩家数据模型）继承自 CharacterModel

```
class_name PlayerModel
extends CharacterModel

# 属性
var max_energy: int                         # 最大能量
var current_energy: int                     # 当前能量
var coin: int                               # 货币

# 函数
func _init(id: StringName) -> void          # 构造函数
```

##### EnemyModel（敌人数据模型）继承自 CharacterModel

```
class_name EnemyModel
extends CharacterModel

# 属性
var intent_pool: PackedStringArray          # 意图池

# 函数
func _init(id: StringName) -> void          # 构造函数
```

##### Damage（伤害类）

```
class_name Damage
extends RefCounted

# 属性
var value: float                            # 伤害值
var source: Character                       # 伤害来源
var damage_type: int                        # 伤害类型

# 函数
func _init(value: float, source: Character, type: int = 0) -> void   # 构造函数
```

---

## zjw：卡牌系统 + 数据管理与处理

### 模块 3：卡牌系统

**工作内容**：实现卡牌管理、抽牌堆、弃牌堆、手牌管理等功能

#### 3.1 文件位置

```
source/system/card_system/
├── C_CardSystem.gd           # 卡牌系统核心
├── card.gd                   # 卡牌类
├── card_model.gd             # 卡牌数据模型
└── card_deck.gd              # 牌堆类
```

#### 3.2 类定义

##### C_CardSystem（卡牌系统）

```
class_name C_CardSystem
extends Node

# 变量
var _draw_deck: CardDeck                    # 抽牌堆
var _discard_deck: CardDeck                 # 弃牌堆
var _hand_cards: Array[Card]                # 手牌
var _player_id: StringName                  # 玩家ID

# 常量
const MAX_HAND_CARDS: int = 10              # 最大手牌数
const DEFAULT_DRAW_COUNT: int = 5           # 默认抽牌数

# 信号
signal card_drawn(card: Card)               # 抽到卡牌
signal card_played(card: Card)              # 打出卡牌
signal card_discarded(card: Card)           # 弃掉卡牌
signal hand_changed                         # 手牌变化

# 函数
func init(player_id: StringName) -> void                    # 初始化
func init_draw_deck() -> void                               # 初始化抽牌堆
func distribute_card(count: int = DEFAULT_DRAW_COUNT) -> void   # 分发卡牌（抽牌）
func draw_card() -> Card                                    # 抽一张牌
func play_card(card: Card, target: Character) -> void       # 打出卡牌
func discard_card(card: Card) -> void                       # 弃掉卡牌
func discard_all() -> void                                  # 弃掉所有手牌
func shuffle_discard_to_draw() -> void                      # 洗牌（弃牌堆->抽牌堆）
func get_hand_cards() -> Array[Card]                        # 获取手牌
func can_play_card(card: Card) -> bool                      # 能否打出卡牌
```

##### Card（卡牌类）

```
class_name Card
extends RefCounted

# 变量
var _model: CardModel                       # 数据模型
var caster: Character                       # 释放者

# 属性（只读）
var card_name: String                       # 卡牌名称
var card_type: CardModel.CARD_TYPE          # 卡牌类型
var card_description: String                # 卡牌描述
var cost: int                               # 消耗能量
var icon: Texture                           # 卡牌图标
var target_type: CardModel.TARGET_TYPE      # 目标类型
var play_animation: String                  # 施法动画
var effects: Array                          # 效果列表
var buff_des: PackedStringArray             # Buff描述

# 函数
func _init(cardID: StringName) -> void                      # 构造函数
func needs_target() -> bool                                 # 是否需要目标
func can_release() -> bool                                  # 能否释放
func release(caster: Character, selected_cha: Character) -> void   # 释放卡牌
func get_card_type_name() -> String                         # 获取类型名
```

##### CardModel（卡牌数据模型）

```
class_name CardModel
extends RefCounted

# 枚举
enum CARD_TYPE {
    ATTACK,                                 # 攻击
    SKILL,                                  # 技能
    POWER                                   # 能力
}

enum TARGET_TYPE {
    SELF,                                   # 自身
    SINGLE_ENEMY,                           # 敌方单体
    ALL_ENEMIES,                            # 敌方全体
    NONE                                    # 无目标
}

# 属性
var card_id: StringName                     # 卡牌ID
var card_name: String                       # 卡牌名
var card_type: CARD_TYPE                    # 类型
var cost: int                               # 消耗
var card_description: String                # 描述
var icon: Texture                           # 图标
var target_type: TARGET_TYPE                # 目标类型
var play_animation: String                  # 动画
var effects: PackedStringArray              # 效果ID列表
var buff_des: PackedStringArray             # Buff描述

# 函数
func _init(id: StringName) -> void          # 构造函数
func needs_target() -> bool                 # 是否需要目标
func get_card_type_name() -> String         # 获取类型名
```

##### CardDeck（牌堆类）

```
class_name CardDeck
extends RefCounted

# 变量
var _cards: Array[Card]                     # 卡牌列表

# 函数
func add_card(card: Card) -> void           # 添加卡牌
func remove_card(card: Card) -> void        # 移除卡牌
func draw_card() -> Card                    # 抽取卡牌
func shuffle() -> void                      # 洗牌
func is_empty() -> bool                     # 是否为空
func get_count() -> int                     # 获取数量
func clear() -> void                        # 清空
func get_cards() -> Array[Card]             # 获取所有卡牌
```

### 模块 4：数据管理与处理

**工作内容**：管理所有 CSV 数据表，实现数据加载、缓存和访问接口

#### 4.1 文件位置

```
source/
├── datatables/               # CSV数据表目录
└── utility/
    └── datatable_manager.gd  # 数据表管理工具
```

#### 4.2 数据表管理

##### 数据表加载与缓存

```
# 扩展DatatableManager
static func load_all_datatables() -> void:
    load_datatable("card", "res://datatables/card.csv")
    load_datatable("monster", "res://datatables/monster.csv")
    load_datatable("buff", "res://datatables/buff.csv")
    load_datatable("ability_effect", "res://datatables/ability_effect.csv")
    load_datatable("combat", "res://datatables/combat.csv")
    load_datatable("hero", "res://datatables/hero.csv")
    load_datatable("intent", "res://datatables/intent.csv")
    load_datatable("attribute", "res://datatables/attribute.csv")
```

##### 数据访问接口

```
# 卡牌数据访问
static func get_card_data(card_id: StringName) -> Dictionary:
    return get_datatable_row("card", card_id)

# 怪物数据访问
static func get_monster_data(monster_id: StringName) -> Dictionary:
    return get_datatable_row("monster", monster_id)

# 战斗配置访问
static func get_combat_data(combat_id: StringName) -> Dictionary:
    return get_datatable_row("combat", combat_id)

# 效果数据访问
static func get_effect_data(effect_id: StringName) -> Dictionary:
    return get_datatable_row("ability_effect", effect_id)
```

---

## 抓青蛙：效果与 Buff 系统

### 模块 5：效果与 Buff 系统

**工作内容**：实现各种效果（伤害、护盾、Buff 等）的处理逻辑

#### 5.1 文件位置

```
source/system/effect_system/
├── effect.gd                 # 效果基类
├── effect_damage.gd          # 伤害效果
├── effect_shielded.gd        # 护盾效果
├── effect_apply_buff.gd      # 添加Buff效果
└── effect_vulnerable.gd      # 易伤效果

source/system/buff_system/
├── C_BuffSystem.gd           # Buff系统
├── buff.gd                   # Buff类
└── buff_model.gd             # Buff数据模型
```

#### 5.2 类定义

##### Effect（效果基类）

```
class_name Effect
extends RefCounted

# 枚举
enum EFFECT_TYPE {
    NONE,                                   # 未知
    DAMAGE,                                 # 造成伤害
    SHIELDED,                               # 护盾
    ADD_BUFF,                               # 给予Buff
    VULNERABLE                              # 易伤
}

enum TARGET_TYPE {
    NONE,                                   # 继承
    SELF,                                   # 自身
    SINGLE_ENEMY,                           # 敌方单体
    ALL_ENEMIES                             # 敌方全体
}

# 变量
var _caster: Character                      # 效果来源
var _targets: Array[Character]              # 目标列表
var effect_name: String                     # 效果名
var effect_description: String              # 效果描述
var target_type: int                        # 目标类型

# 函数
func _init(data: Dictionary) -> void                            # 构造函数
func execute() -> void                                          # 执行效果（虚函数）
func get_effect_targets(caster: Character, targets: Array[Character]) -> Array[Character]   # 获取目标
static func create_effect(effectID: String, caster: Character, targets: Array[Character]) -> Effect   # 创建效果
static func try_execute(effectID: String, caster: Character, targets: Array[Character]) -> void       # 尝试执行
```

##### EffectDamage（伤害效果）继承自 Effect

```
class_name EffectDamage
extends Effect

# 属性
var damage_value: float                     # 伤害值

# 函数
func _init(data: Dictionary) -> void        # 构造函数
func execute() -> void                      # 执行伤害
```

##### EffectShielded（护盾效果）继承自 Effect

```
class_name EffectShielded
extends Effect

# 属性
var shield_value: int                       # 护盾值

# 函数
func _init(data: Dictionary) -> void        # 构造函数
func execute() -> void                      # 执行加护盾
```

##### EffectApplyBuff（添加 Buff 效果）继承自 Effect

```
class_name EffectApplyBuff
extends Effect

# 属性
var buff_id: StringName                     # Buff ID
var buff_stack: int                         # 堆叠层数

# 函数
func _init(data: Dictionary) -> void        # 构造函数
func execute() -> void                      # 执行添加Buff
```

##### EffectVulnerable（易伤效果）继承自 Effect

```
class_name EffectVulnerable
extends Effect

# 属性
var vulnerable_stack: int                   # 易伤层数

# 函数
func _init(data: Dictionary) -> void        # 构造函数
func execute() -> void                      # 执行添加易伤
```

##### C_BuffSystem（Buff 系统）

```
class_name C_BuffSystem
extends Node

# 变量
var buffs: Array[Buff]                      # Buff列表

# 信号
signal buff_applied(buff: Buff)             # Buff被应用

# 函数
func _ready() -> void                       # 初始化
func before_damage(damage: Damage) -> void  # 伤害前回调
func after_damage(damage: Damage) -> void   # 伤害后回调
func _on_turn_begined() -> void             # 回合开始回调
func _on_turn_ended() -> void               # 回合结束回调
func apply_buff(new_buff: Buff) -> void     # 应用Buff
func has_buff(buff_name: StringName) -> bool    # 是否有某Buff
func _add_buff(buff: Buff) -> void          # 添加Buff
func _remove_buff(buff: Buff) -> void       # 移除Buff
```

##### Buff（Buff 类）

```
class_name Buff
extends RefCounted

# 枚举
enum BUFF_TYPE {
    VALUE,                                  # 数值型
    STATUS                                  # 状态型
}

enum DURATION_TYPE {
    PERMANENT,                              # 永久
    TURN                                    # 持续回合
}

enum CALLBACK_TYPE {
    TURN_BEGIN,                             # 回合开始
    TURN_END,                               # 回合结束
    BEFORE_DAMAGE,                          # 受伤前
    AFTER_DAMAGE,                           # 受伤后
    BEFORE_ATTACK,                          # 攻击前
    AFTER_ATTACK,                           # 攻击后
    ON_HEAL,                                # 被治疗时
    ON_PLAY_CARD                            # 使用卡牌时
}

# 属性
var buff_id: StringName                     # Buff ID
var buff_name: String                       # Buff名
var description: String                     # 描述
var is_stacked: bool                        # 是否可堆叠
var buff_type: BUFF_TYPE                    # Buff类型
var duration_type: DURATION_TYPE            # 持续类型
var callback_type: CALLBACK_TYPE            # 回调类型
var value: int                              # 数值/层数
var icon: Texture                           # 图标
var effects: Array                          # 效果列表
var execute_func: Callable                  # 执行函数

# 函数
func _init(id: StringName) -> void          # 构造函数
func can_stacked(other: Buff) -> bool       # 能否与另一个Buff堆叠
func stack(other: Buff) -> void             # 堆叠
```

##### BuffModel（Buff 数据模型）

```
class_name BuffModel
extends RefCounted

# 属性
var buff_id: StringName                     # Buff ID
var buff_name: String                       # Buff名
var description: String                     # 描述
var is_stacked: bool                        # 是否可堆叠
var buff_type: int                          # 类型
var duration_type: int                      # 持续类型
var callback_type: int                      # 回调类型
var icon: Texture                           # 图标
var effects: PackedStringArray              # 效果列表

# 函数
func _init(id: StringName) -> void          # 构造函数
```

---

## 歪歪：敌人 AI 与意图系统 + 战斗系统

### 模块 6：敌人 AI 与意图系统

**工作内容**：实现敌人的 AI 决策、意图选择、意图执行

#### 6.1 文件位置

```
source/system/intent_system/
├── C_IntentSystem.gd         # 意图系统
├── intent.gd                 # 意图类
└── intent_model.gd           # 意图数据模型
```

#### 6.2 类定义

##### C_IntentSystem（意图系统）

```
class_name C_IntentSystem
extends Node

# 变量
var _intent_pool: Array[Intent]             # 意图池
var _current_intent: Intent                 # 当前意图
var _cooldowns: Dictionary                  # 冷却时间

# 信号
signal intent_chosen(intent: Intent)        # 意图被选择
signal intent_executed(intent: Intent)      # 意图执行完成

# 函数
func _ready() -> void                       # 初始化
func init_intent_pool(intent_ids: PackedStringArray) -> void    # 初始化意图池
func choose_intent() -> void                # 选择意图
func execute_intent() -> void               # 执行意图
func _get_available_intents() -> Array[Intent]    # 获取可用意图
func _calculate_weights() -> Dictionary     # 计算权重
func _is_intent_on_cooldown(intent: Intent) -> bool   # 意图是否在冷却
func _set_cooldown(intent: Intent) -> void  # 设置冷却
func _update_cooldowns() -> void            # 更新冷却
```

##### Intent（意图类）

```
class_name Intent
extends RefCounted

# 变量
var _model: IntentModel                     # 数据模型

# 属性（只读）
var intent_id: StringName                   # 意图ID
var intent_name: String                     # 意图名
var description: String                     # 描述
var icon: Texture                           # 图标
var effects: Array                          # 效果列表
var weight: int                             # 权重
var cooldown: int                           # 冷却回合

# 函数
func _init(id: StringName) -> void          # 构造函数
func execute(caster: Enemy) -> void         # 执行意图
```

##### IntentModel（意图数据模型）

```
class_name IntentModel
extends RefCounted

# 属性
var intent_id: StringName                   # 意图ID
var intent_name: String                     # 意图名
var description: String                     # 描述
var icon: Texture                           # 图标
var effects: PackedStringArray              # 效果ID列表
var weight: int                             # 权重
var cooldown: int                           # 冷却回合

# 函数
func _init(id: StringName) -> void          # 构造函数
```

### 模块 7：战斗系统

**工作内容**：实现战斗场景、回合管理、战斗流程控制

#### 7.1 文件位置

```
source/scenes/
├── combat_scene.gd           # 战斗场景
├── combat_scene.tscn         # 战斗场景文件
├── scene_base.gd             # 场景基类
├── map_scene.gd              # 地图场景
└── map_scene.tscn            # 地图场景文件
```

#### 7.2 类定义

##### CombatScene（战斗场景）继承自 SceneBase

```
class_name CombatScene
extends SceneBase

# 导出变量
@export var markers: Array                  # 角色出生点位
@export var combat_form: Control            # 战斗UI

# 变量
var characters: Array[Character]            # 战斗角色列表
var current_character: Character            # 当前回合角色

# 信号
signal succeeded                            # 战斗胜利
signal failed                               # 战斗失败

# 函数
func _enter(msg: Dictionary = {}) -> void   # 进入场景
func _exit() -> void                        # 退出场景
func _init_combat(combat_id: StringName, player: Character) -> void   # 初始化战斗
func _begin_combat() -> void                # 开始战斗
func _next_turn() -> void                   # 下一回合
func _end_combat() -> void                  # 结束战斗
func _init_player(player: Character) -> void    # 初始化玩家
func _create_enemy(enemyID: StringName, markerID: int) -> void    # 创建敌人
func _get_next_character() -> Character     # 获取下一个角色
func _is_player_turn(player: Character) -> bool   # 是否玩家回合
```

##### MapScene（地图场景）继承自 SceneBase

```
class_name MapScene
extends SceneBase

# 变量
var _current_node: MapNode                  # 当前节点
var _map_data: MapData                      # 地图数据

# 信号
signal node_selected(node: MapNode)         # 节点选择
signal combat_started(combat_id: String)    # 开始战斗

# 函数
func _enter(msg: Dictionary = {}) -> void   # 进入场景
func _exit() -> void                        # 退出场景
func _generate_map() -> void                # 生成地图
func _on_node_selected(node: MapNode) -> void   # 节点被选择
func _enter_combat(combat_id: String) -> void   # 进入战斗
```

---

## kk：UI 系统

### 模块 8：UI 系统

**工作内容**：实现游戏界面、卡牌显示、状态显示、交互逻辑

#### 8.1 文件位置

```
source/UI/
├── form/
│   ├── combat_form.gd        # 战斗界面
│   ├── combat_form.tscn      # 战斗界面场景
│   ├── map_form.tscn         # 地图界面
│   └── menu_form.tscn        # 菜单界面
└── widgets/
    ├── w_status_bar.gd       # 状态条（血条、护盾）
    ├── w_status_bar.tscn     # 状态条场景
    ├── w_buff.gd             # Buff显示
    ├── w_turn.gd             # 回合指示器
    ├── w_tooltip.gd          # 提示框
    ├── w_tooltip.tscn        # 提示框场景
    └── w_card.gd             # 卡牌显示
```

#### 8.2 类定义

##### CombatForm（战斗界面）

```
class_name CombatForm
extends Control

# 导出变量
@export var hand_container: HBoxContainer   # 手牌容器
@export var end_turn_button: Button         # 结束回合按钮
@export var energy_label: Label             # 能量显示
@export var draw_pile_button: Button        # 抽牌堆按钮
@export var discard_pile_button: Button     # 弃牌堆按钮

# 信号
signal end_turn_pressed                     # 结束回合按钮按下
signal card_selected(card: Card)            # 卡牌被选择

# 函数
func _ready() -> void                       # 初始化
func next_turn(character: Character) -> void    # 下一回合
func update_hand(cards: Array[Card]) -> void    # 更新手牌显示
func update_energy(current: int, max: int) -> void  # 更新能量显示
func _on_end_turn_pressed() -> void         # 结束回合按钮回调
func _on_card_clicked(card_ui: W_Card) -> void  # 卡牌点击回调
```

##### W_StatusBar（状态条控件）

```
class_name W_HealthBar
extends Control

# 导出变量
@export var health_bar: ProgressBar         # 血条
@export var shield_label: Label             # 护盾标签
@export var buff_container: HBoxContainer   # Buff容器

# 函数
func update_display(current: float, max: float, shield: int) -> void    # 更新显示
func add_buff_widget(buff: Buff) -> void    # 添加Buff显示
func remove_buff_widget(buff: Buff) -> void # 移除Buff显示
```

##### W_Card（卡牌控件）

```
class_name W_Card
extends Control

# 导出变量
@export var card_name_label: Label          # 卡牌名标签
@export var cost_label: Label               # 消耗标签
@export var icon_texture: TextureRect       # 图标
@export var description_label: RichTextLabel   # 描述

# 变量
var _card: Card                             # 卡牌数据

# 信号
signal clicked(card: W_Card)                # 被点击
signal hovered(card: W_Card)                # 鼠标悬停
signal exited(card: W_Card)                 # 鼠标离开

# 函数
func set_card(card: Card) -> void           # 设置卡牌数据
func update_display() -> void               # 更新显示
func set_interactive(enable: bool) -> void  # 设置交互状态
func highlight(enable: bool) -> void        # 高亮显示
```

##### W_Tooltip（提示框控件）

```
class_name W_Tooltip
extends MarginContainer

# 导出变量
@export var title_label: Label              # 标题
@export var content_label: RichTextLabel    # 内容

# 函数
func set_tooltip(title: String, content: String) -> void    # 设置提示内容
func show_at(position: Vector2) -> void     # 在指定位置显示
```

##### W_Buff（Buff 显示控件）

```
class_name W_Buff
extends Control

# 导出变量
@export var icon_texture: TextureRect       # Buff图标
@export var stack_label: Label              # 堆叠层数

# 变量
var _buff: Buff                             # Buff数据

# 函数
func set_buff(buff: Buff) -> void           # 设置Buff数据
func update_display() -> void               # 更新显示
```

##### W_Turn（回合指示器）

```
class_name W_Turn
extends Control

# 导出变量
@export var turn_label: Label               # 回合数标签
@export var character_name_label: Label     # 角色名标签

# 函数
func update_turn(turn_number: int) -> void  # 更新回合数
func update_character(character: Character) -> void  # 更新当前角色
```

---

## 开发顺序与依赖关系

### 第一阶段（基础框架）

1. **奇军**：核心架构与数据管理

   - 实现 GameInstance、SceneManager、SceneBase
   - 实现 EventBus
   - 创建所有 CSV 数据表结构
2. **奇军**：角色系统

   - 实现 Character、CharacterModel
   - 实现 Player、PlayerModel
   - 实现 Enemy、EnemyModel
   - 实现 Damage 类

### 第二阶段（核心系统）

1. **zjw**：数据管理与处理

   - 实现 DatatableManager
   - 加载和管理所有 CSV 数据表
   - 提供数据访问接口
2. **zjw**：卡牌系统

   - 实现 CardModel
   - 实现 Card
   - 实现 CardDeck
   - 实现 C_CardSystem

### 第三阶段（扩展系统）

1. **抓青蛙**：效果与 Buff 系统

   - 实现 Effect 基类
   - 实现 EffectDamage、EffectShielded
   - 实现 EffectApplyBuff、EffectVulnerable
   - 实现 BuffModel、Buff、C_BuffSystem
2. **歪歪**：敌人 AI 与意图系统

   - 实现 IntentModel、Intent
   - 实现 C_IntentSystem

### 第四阶段（整合与 UI）

1. **歪歪**：战斗系统

   - 实现 CombatScene
   - 实现 MapScene
   - 整合所有系统
2. **kk**：UI 系统

   - 实现 CombatForm
   - 实现 W_StatusBar、W_Card
   - 实现 W_Tooltip、W_Buff
   - 实现 W_Turn

---

## 接口约定

### 角色系统对外接口

```
# Character
func damage(damage: Damage) -> void
func add_shielded(value: int) -> void
func death() -> void
signal damaged
signal died
signal turn_begined
signal turn_completed

# Player
func use_energy(amount: int) -> void
func reset_energy() -> void
signal energy_changed
```

### 卡牌系统对外接口

```
# C_CardSystem
func distribute_card(count: int) -> void
func play_card(card: Card, target: Character) -> void
func discard_all() -> void
signal card_drawn
signal card_played
signal hand_changed

# Card
func can_release() -> bool
func release(caster: Character, target: Character) -> void
```

### 效果系统对外接口

```
# Effect
static func try_execute(effectID: String, caster: Character, targets: Array[Character]) -> void

# C_BuffSystem
func apply_buff(buff: Buff) -> void
func has_buff(buff_name: StringName) -> bool
signal buff_applied
```

### 战斗系统对外接口

```
# CombatScene
func _init_combat(combat_id: StringName, player: Character) -> void
func _begin_combat() -> void
func _next_turn() -> void
signal succeeded
signal failed
```

### UI 系统对外接口

```
# CombatForm
func next_turn(character: Character) -> void
func update_hand(cards: Array[Card]) -> void
func update_energy(current: int, max: int) -> void
signal end_turn_pressed
signal card_selected
```

---

## 注意事项

1. **命名规范**：

   - 类名使用 PascalCase（如 `CardSystem`）
   - 函数名使用 snake_case（如 `draw_card`）
   - 常量使用 UPPER_SNAKE_CASE（如 `MAX_HAND_CARDS`）
   - 私有变量使用下划线前缀（如 `_model`）
2. **信号命名**：

   - 使用过去分词形式（如 `turn_begined`、`card_played`）
3. **数据表**：

   - 所有配置数据使用 CSV 格式
   - ID 字段使用 StringName 类型
   - 数组使用 `*` 分隔（如 `effect1*effect2*effect3`）
4. **依赖注入**：

   - 使用 `@onready` 获取节点引用
   - 通过构造函数或 init 函数传入必要参数
5. **代码注释**：

   - 使用 `##` 进行文档注释
   - 关键逻辑添加行内注释
6. **协作注意**：

   - 遵循开发顺序，确保依赖模块先完成
   - 定期沟通，确保接口约定一致
   - 使用版本控制工具管理代码
   - 及时解决依赖问题
7. **测试要求**：

   - 每个模块完成后进行单元测试
   - 集成测试确保系统间协作正常
   - 性能测试确保游戏流畅运行

---

## 交付物清单

<table>
<tr>
<td>成员<br/></td><td>交付物<br/></td><td>数量<br/></td></tr>
<tr>
<td>奇军<br/></td><td>核心架构文件<br/></td><td>4个<br/></td></tr>
<tr>
<td>奇军<br/></td><td>角色系统文件<br/></td><td>8个<br/></td></tr>
<tr>
<td>奇军<br/></td><td>CSV数据表结构<br/></td><td>8个<br/></td></tr>
<tr>
<td>zjw<br/></td><td>卡牌系统文件<br/></td><td>4个<br/></td></tr>
<tr>
<td>zjw<br/></td><td>数据管理工具<br/></td><td>1个<br/></td></tr>
<tr>
<td>zjw<br/></td><td>数据表加载逻辑<br/></td><td>1套<br/></td></tr>
<tr>
<td>抓青蛙<br/></td><td>效果系统文件<br/></td><td>5个<br/></td></tr>
<tr>
<td>抓青蛙<br/></td><td>Buff系统文件<br/></td><td>3个<br/></td></tr>
<tr>
<td>歪歪<br/></td><td>意图系统文件<br/></td><td>3个<br/></td></tr>
<tr>
<td>歪歪<br/></td><td>战斗系统文件<br/></td><td>5个<br/></td></tr>
<tr>
<td>kk<br/></td><td>UI界面文件<br/></td><td>4个<br/></td></tr>
<tr>
<td>kk<br/></td><td>UI控件文件<br/></td><td>5个<br/></td></tr>
</table>

---
