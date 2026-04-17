extends RefCounted

const PAGES: Array[Dictionary] = [
	{
		# 没有 image，会被当作居中文字处理
		"text": "深海残响\nThe Depth of Danger\n\nDemo版本\n\n还是报错队\n\n音乐由[乌鸦Producer]提供"
	},
	{
		# 有 image，会被当作带底图和对话框的故事页处理
		"image": "res://assets/art/story/story-1.PNG",
		"text": "在当今的岛屿城邦中，下潜并不稀奇。稀奇的是——来自海底最深处的来讯。"
	},
	{
		"image": "res://assets/art/story/story-2.PNG",
		"text": "我们收到了一封来自深海底部的讯息。"
	},
	{
		"image": "res://assets/art/story/story-3.PNG",
		"text": "发出讯息的人，是一名已经确认死亡的潜航员。至少在基地档案里，他早就死了。"
	},
	{
		# 靠 BBCode 控制颜色和抖动
		"text": "不要相信报告上的[color=red]死亡时间[/color]。\n\n[shake rate=20.0 level=5 connected=1][color=red]我还在下面。[/color][/shake]\n\n我还活着。\n\n来找我。"
	},
	{
		"image": "res://assets/art/story/story-4.PNG",
		"text": "就在这时，只有你听见了另一个声音。那不是电流杂音，也不是管理者的说话声。"
	},
	{
		# 靠 BBCode 控制红字
		"text": "[color=red]下来。[/color]\n\n那声音古老、低沉，像隔着无数层海水，直接落进你的脑海。"
	},
	{
		"image": "res://assets/art/story/story-5.PNG",
		"text": "管理者：你怎么了？……你听见什么了？"
	},
	{
		"image": "res://assets/art/story/story-5.PNG",
		"text": "那不是杂音。有人在海底说话。"
	},
	{
		"image": "res://assets/art/story/story-6.PNG",
		"text": "管理者：只有你听见了内容。这就意味着，这次调查只能由你去。这可能是陷阱，但如果让别人去，只会让他白白送死。\n\n不管下面是什么，基地都必须知道那东西是谁——或者，是什么。"
	},
	{
		"text": "于是，你接受了这份不该开始的下潜任务。\n\n目标只有一个——\n找到那封电报真正的来源。"
	}
]
