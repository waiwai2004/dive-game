class_name EventBus
extends Node
## 事件总线（单例）
## 负责全局解耦的事件订阅与推送

static var _events: Dictionary = {}

## 注册一个新事件
static func register_event(event_name: String) -> void:
	if not _events.has(event_name):
		_events[event_name] = []

## 推送事件并传递参数
static func push_event(event_name: String, data: Variant = null) -> void:
	if _events.has(event_name):
		for callback in _events[event_name]:
			if callback.is_valid():
				if data != null:
					callback.call(data)
				else:
					callback.call()

## 连接并监听事件
static func connect_event(event_name: String, callback: Callable) -> void:
	if not _events.has(event_name):
		register_event(event_name)
	if not _events[event_name].has(callback):
		_events[event_name].append(callback)

## 断开事件监听
static func disconnect_event(event_name: String, callback: Callable) -> void:
	if _events.has(event_name) and _events[event_name].has(callback):
		_events[event_name].erase(callback)
