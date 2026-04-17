## 战斗音频管理
## 职责：集中封装战斗场景内的 BGM / SFX 调用，避免到处 `has_node("/root/AudioManager")`。
class_name BattleAudioManager
extends Node


func play_battle_bgm() -> void:
	if has_node("/root/AudioManager"):
		AudioManager.play_bgm_segment("battle")


func play_sfx(sfx_name: String) -> void:
	if sfx_name.is_empty():
		return
	if has_node("/root/AudioManager") and AudioManager.has_method("play_sfx"):
		AudioManager.play_sfx(sfx_name)
