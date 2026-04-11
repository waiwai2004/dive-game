class_name SceneBase
extends Node2D
## 场景基类
## 所有可被 SceneManager 管理的游戏场景应继承自此类

## 进入场景时调用，支持传入初始化参数
func _enter(msg: Dictionary = {}) -> void:
	pass

## 退出场景并销毁前调用
func _exit() -> void:
	pass

## 场景被新场景覆盖压入后台时调用
func _pause() -> void:
	pass

## 从后台恢复到最前台时调用
func _resume() -> void:
	pass
