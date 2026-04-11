extends Node

var bgm_player: AudioStreamPlayer = null
var bgm_enabled: bool = true
var bgm_volume: float = 0.7

func _ready() -> void:
	# 创建音频播放器
	bgm_player = AudioStreamPlayer.new()
	bgm_player.name = "BGMPlayer"
	add_child(bgm_player)
	
	# 设置节点在游戏暂停时仍然继续处理
	set_process_mode(Node.PROCESS_MODE_ALWAYS)
	
	# 设置初始音量
	bgm_player.volume_db = linear_to_db(bgm_volume)
	
	# 加载并播放背景音乐
	load_and_play_bgm()

func load_and_play_bgm() -> void:
	var bgm_path = "res://assets/audio/music/bgm.mp3"
	var bgm_stream = load(bgm_path)
	
	if bgm_stream:
		bgm_player.stream = bgm_stream
		# 设置循环播放
		if bgm_stream is AudioStreamMP3:
			bgm_stream.loop = true
		bgm_player.volume_db = linear_to_db(bgm_volume)
		
		if bgm_enabled:
			bgm_player.play()

func set_bgm_enabled(enabled: bool) -> void:
	bgm_enabled = enabled
	
	if bgm_enabled:
		if not bgm_player.playing:
			bgm_player.play()
	else:
		bgm_player.stop()

func set_bgm_volume(volume: float) -> void:
	bgm_volume = volume / 100.0  # 转换为0-1范围
	bgm_player.volume_db = linear_to_db(bgm_volume)

func get_bgm_enabled() -> bool:
	return bgm_enabled

func get_bgm_volume() -> float:
	return bgm_volume * 100.0  # 转换为0-100范围

# 每帧检查游戏暂停状态，确保音乐继续播放
func _process(delta: float) -> void:
	if bgm_enabled and get_tree().paused and not bgm_player.playing:
		# 强制播放音乐，即使游戏暂停
		bgm_player.play()