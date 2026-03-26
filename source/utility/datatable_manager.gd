class_name DatatableManager
extends Node
## 数据表管理器（全局工具类/单例）
## 负责解析并缓存游戏 CSV 格式的配置表

static var _datatables: Dictionary = {}

## 加载 CSV 数据表并缓存
static func load_datatable(table_name: String, path: String) -> void:
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("DatatableManager: Cannot open file " + path)
		return
		
	var headers: PackedStringArray = []
	var data: Dictionary = {}
	var line_count = 0
	
	while not file.eof_reached():
		var line = file.get_csv_line()
		
		# 忽略空行
		if line.size() == 0 or line[0] == "":
			continue
			
		# 第一行为纯标题/键名
		if line_count == 0:
			headers = line
		# 第二行为中文注释，直接跳过
		elif line_count == 1:
			pass
		# 数据行
		else:
			var id = StringName(line[0]) # 强制将主键使用 StringName
			var row_data: Dictionary = {}
			for i in range(line.size()):
				if i < headers.size():
					var key = headers[i]
					var value = line[i]
					
					# 根据规范，数组类型通过 '*' 分隔，如包含则自动处理
					if value.contains("*"):
						row_data[key] = value.split("*")
					else:
						row_data[key] = value
					
			data[id] = row_data
			
		line_count += 1
		
	_datatables[table_name] = data
	print("DatatableManager: Loaded ", table_name, " successfully.")

## 获取整张数据表
static func get_datatable(table_name: String) -> Dictionary:
	if _datatables.has(table_name):
		return _datatables[table_name]
	return {}

## 获取数据表中特定行数据的字典
static func get_datatable_row(table_name: String, row_id: StringName) -> Dictionary:
	var table = get_datatable(table_name)
	if table.has(row_id):
		return table[row_id]
	return {}
