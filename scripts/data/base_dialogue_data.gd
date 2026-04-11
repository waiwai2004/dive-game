extends RefCounted
class_name BaseDialogueData

static func first_dialogue() -> Array:
	return [
		{
			"speaker": "基地管家",
			"portrait": "butler",
			"text": "你来了。"
		},
		{
			"speaker": "基地管家",
			"portrait": "butler",
			"text": "先说清楚，这不是什么正式任命，也不是什么值得庆祝的第一次下潜。"
		},
		{
			"speaker": "基地管家",
			"portrait": "butler",
			"text": "这次下潜，是要直面一个异常，一个足以让你连死亡都成为苛求的异常。"
		},
		{
			"speaker": "基地管家",
			"portrait": "butler",
			"text": "我们收到了一段信号。信号源是一个已经死去的潜航员。"
		},
		{
			"speaker": "基地管家",
			"portrait": "butler",
			"text": "或者说——"
		},
		{
			"speaker": "基地管家",
			"portrait": "butler",
			"text": "至少在我们的记录里，他已经死了。"
		},
		{
			"speaker": "信号接收器",
			"portrait": "receiver",
			"text": "不要相信报告上的[color=red][shake]死亡时间[/shake][/color]。"
		},
		{
			"speaker": "信号接收器",
			"portrait": "receiver",
			"text": "[shake]我还在下面。[/shake]"
		},
		{
			"speaker": "信号接收器",
			"portrait": "receiver",
			"text": "[shake]我还活着。[/shake]"
		},
		{
			"speaker": "信号接收器",
			"portrait": "receiver",
			"text": "[b][color=red][shake]来找我！[/shake][/color][/b]"
		},
		{
			"speaker": "基地管家",
			"portrait": "butler",
			"text": "站里的老手没人愿意接。"
		},
		{
			"speaker": "基地管家",
			"portrait": "butler",
			"text": "不是因为他们胆小，而是因为他们知道，"
		},
		{
			"speaker": "基地管家",
			"portrait": "butler",
			"text": "有些地方一旦下去，带回来的就不一定还是自己。"
		},
		{
			"speaker": "基地管家",
			"portrait": "butler",
			"text": "甚至会给我们这个本就脆弱的文明带来灭顶之灾。"
		},
		{
			"speaker": "基地管家",
			"portrait": "butler",
			"text": "即便如此，你还是要去。"
		},
		{
			"speaker": "基地管家",
			"portrait": "butler",
			"text": "说实话，我想不明白你为什么会这么积极？"
		},
		{
			"speaker": "基地管家",
			"portrait": "butler",
			"text": "所以在正式下潜前，先回答我。"
		},
		{
			"speaker": "基地管家",
			"portrait": "butler",
			"text": "也回答你自己。"
		},
		{
			"speaker": "基地管家",
			"portrait": "butler",
			"text": "你为什么想要下潜？",
			"choices": [
				{
					"text": "因为我想知道，下面到底藏着什么。",
					"next_index": 19
				},
				{
					"text": "因为总得有人往下走。",
					"next_index": 19
				},
				{
					"text": "因为每次想到更深的地方，我都会觉得……我迟早要下去。",
					"next_index": 19
				}
			]
		},
		{
			"speaker": "基地管家",
			"portrait": "butler",
			"text": "好。不管你的理由是什么，都要小心！"
		},
		{
			"speaker": "基地管家",
			"portrait": "butler",
			"text": "说回任务，这次目标很简单。"
		},
		{
			"speaker": "基地管家",
			"portrait": "butler",
			"text": "下潜，沿坐标前进。"
		},
		{
			"speaker": "基地管家",
			"portrait": "butler",
			"text": "确认讯号来源的真伪。"
		},
		{
			"speaker": "基地管家",
			"portrait": "butler",
			"text": "带回深潜记录，别忘了，也请带回你自己。"
		},
		{
			"speaker": "基地管家",
			"portrait": "butler",
			"text": "你一个人去吧，我就不送你了。"
		}
	]

static func final_only_dialogue() -> Array:
	return [
		{
			"speaker": "基地管家",
			"portrait": "butler",
			"text": "你一个人去吧，我就不送你了。"
		}
	]
