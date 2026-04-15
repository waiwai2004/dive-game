extends Node

const MANAGER_PORTRAIT = preload("res://assets/art/characters/NPC/base_npc.PNG")
const PLAYER_PORTRAIT = preload("res://assets/art/characters/player/base_player.PNG")

func first_dialogue() -> Array:
	return [
		{
			"type": "line",
			"name": "管理员",
			"text": "我们收到了一封来自深海底部的异常电报。发讯人，是一名已经确认死亡的潜航员。",
			"left_portrait": MANAGER_PORTRAIT
		},
		{
			"type": "line",
			"name": "管理员",
			"text": "我们校验过坐标，也尝试过回拨。全部结果都是错乱的。可那封电报，的确来自深海底部。",
			"left_portrait": MANAGER_PORTRAIT
		},
		{
			"type": "line",
			"name": "管理员",
			"text": "更麻烦的是，只有你听见了那段讯息真正的内容。也就是说，这次调查只能由你去。",
			"left_portrait": MANAGER_PORTRAIT
		},
		{
			"type": "choice",
			"name": "管理员",
			"text": "告诉我，你为什么还愿意下潜？",
			"left_portrait": MANAGER_PORTRAIT,
			"right_portrait": PLAYER_PORTRAIT,
			"choices": [
				{
					"text": "因为我想知道，下面到底藏着什么。",
					"result": "aggressive"
				},
				{
					"text": "总得有人去做这件事。",
					"result": "orderly"
				}
			]
		},
		{
			"type": "line",
			"name": "管理员",
			"text": "好。先去浅海中继点，确认讯号，回收记录。记住，如果你再次听见那个声音，别回答它。",
			"left_portrait": MANAGER_PORTRAIT
		}
	]

func repeat_dialogue_before_finish() -> Array:
	return [
		{
			"type": "line",
			"name": "管理员",
			"text": "准备好了就去右侧舱门。我们没有第二个人选。",
			"left_portrait": MANAGER_PORTRAIT
		}
	]

func repeat_dialogue_after_finish() -> Array:
	return [
		{
			"type": "line",
			"name": "管理员",
			"text": "去吧。深潜记录比你的猜测更重要。",
			"left_portrait": MANAGER_PORTRAIT
		}
	]
