# 亮度管理器
extends Node

# 导出变量
@export var default_brightness: float = 50.0

# 私有变量
var brightness: float = 50.0
var brightness_overlay: ColorRect = null
var brightness_layer: CanvasLayer = null

# 信号
signal brightness_changed(value: float)

# 当节点准备好时调用
func _ready() -> void:
	# 初始化亮度
	brightness = default_brightness
	
	# 创建亮度覆盖层
	_create_brightness_overlay()
	
	# 更新亮度
	_update_brightness()

# 创建亮度覆盖层
func _create_brightness_overlay() -> void:
	# 创建 CanvasLayer
	brightness_layer = CanvasLayer.new()
	brightness_layer.name = "BrightnessLayer"
	brightness_layer.layer = 100  # 设置一个很高的层级，确保覆盖所有内容
	
	# 创建 ColorRect
	brightness_overlay = ColorRect.new()
	brightness_overlay.name = "BrightnessOverlay"
	
	# 设置布局
	brightness_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	# 设置颜色为半透明黑色
	brightness_overlay.color = Color(0, 0, 0, 0)
	
	# 设置鼠标过滤器，避免干扰游戏操作
	brightness_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# 添加 ColorRect 到 CanvasLayer
	brightness_layer.add_child(brightness_overlay)
	
	# 添加 CanvasLayer 到场景树（使用 call_deferred 避免节点设置冲突）
	get_tree().root.call_deferred("add_child", brightness_layer)

# 设置亮度
func set_brightness(value: float) -> void:
	# 限制亮度值在 0-100 之间
	brightness = clamp(value, 0.0, 100.0)
	
	# 更新亮度
	_update_brightness()
	
	# 发送信号
	brightness_changed.emit(brightness)

# 获取亮度
func get_brightness() -> float:
	return brightness

# 更新亮度
func _update_brightness() -> void:
	if not brightness_overlay or not brightness_layer:
		_create_brightness_overlay()
	
	# 计算亮度因子（50% 为原始亮度）
	var brightness_factor = (brightness - 50.0) / 50.0
	
	if brightness_factor < 0:
		# 调暗：添加黑色覆盖层
		var alpha = abs(brightness_factor) * 0.8
		brightness_overlay.color = Color(0, 0, 0, alpha)
		brightness_overlay.visible = true
	elif brightness_factor > 0:
		# 调亮：添加白色覆盖层
		var alpha = brightness_factor * 0.3
		brightness_overlay.color = Color(1, 1, 1, alpha)
		brightness_overlay.visible = true
	else:
		# 原始亮度：隐藏覆盖层
		brightness_overlay.visible = false
