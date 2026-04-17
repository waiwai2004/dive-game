## 战斗状态机
## 职责：持有战斗的抽象状态（玩家回合 / 敌人回合 / 奖励 / 结束），并通过信号对外广播切换。
class_name BattleStateManager
extends Node

enum State {
	PLAYER_TURN,
	ENEMY_TURN,
	REWARD,
	FINISHED
}

signal state_changed(new_state: int)

var current_state: int = State.PLAYER_TURN


func change_state(new_state: int) -> void:
	if current_state == new_state:
		return
	current_state = new_state
	state_changed.emit(new_state)


func is_player_turn() -> bool:
	return current_state == State.PLAYER_TURN


func is_finished() -> bool:
	return current_state == State.FINISHED


func is_reward() -> bool:
	return current_state == State.REWARD
