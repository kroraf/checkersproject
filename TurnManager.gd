extends Resource
class_name TurnManager

enum {BLACK_TURN, WHITE_TURN}

signal black_turn_started
signal white_turn_started

var turn:
	set(value):
		turn = value
		match turn:
			BLACK_TURN: black_turn_started.emit()
			WHITE_TURN: white_turn_started.emit()
