class_name SceneManager
extends Node
## 场景管理器（单例）
## 负责游戏场景的切换、压栈与弹栈。

var _current_scene: SceneBase
var _scene_stack: Array[SceneBase] = []

## 切换到全新场景，清空之前的场景数据
func change_scene(scene_path: String, msg: Dictionary = {}) -> void:
	if _current_scene:
		_current_scene._exit()
		_current_scene.queue_free()
	
	var next_scene_res = load(scene_path)
	if next_scene_res is PackedScene:
		_current_scene = next_scene_res.instantiate() as SceneBase
		get_tree().root.add_child(_current_scene)
		_current_scene._enter(msg)
		GameInstance.current_scene = _current_scene

## 压入新场景（如打开UI、进入子地图），暂停当前场景
func push_scene(scene_path: String, msg: Dictionary = {}) -> void:
	if _current_scene:
		_current_scene._pause()
		_scene_stack.push_back(_current_scene)
	
	var next_scene_res = load(scene_path)
	if next_scene_res is PackedScene:
		_current_scene = next_scene_res.instantiate() as SceneBase
		get_tree().root.add_child(_current_scene)
		_current_scene._enter(msg)
		GameInstance.current_scene = _current_scene

## 弹出当前场景，恢复上一层的场景
func pop_scene() -> void:
	if _current_scene:
		_current_scene._exit()
		_current_scene.queue_free()
	
	if _scene_stack.size() > 0:
		_current_scene = _scene_stack.pop_back()
		_current_scene._resume()
		GameInstance.current_scene = _current_scene
	else:
		_current_scene = null
		GameInstance.current_scene = null

## 获取当前正处于活动状态的场景
func get_current_scene() -> SceneBase:
	return _current_scene
