class_name GameInstance
extends Node
## 游戏全局实例（单例）
## 负责全局数据与顶级实体的管理。

static var player: Player
static var current_scene: Node

## 创建并实例化实体
static func create_entity(path: String) -> Node:
	var scene = load(path)
	if scene is PackedScene:
		return scene.instantiate()
	return null

## 获取当前玩家实例
static func get_player() -> Player:
	return player

## 设置当前玩家实例
static func set_player(new_player: Player) -> void:
	player = new_player
