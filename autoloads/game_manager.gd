extends Node

var _board: Array[Array]
var _op_stack: Array[Tile]

func add_operator_tile(tile: Tile):
	_op_stack.append(tile)

func update_board(row: int, col: int, new_value: int):
	_board[row][col] = new_value

func consume_operator(used_op_tile: Tile):
	var index = _op_stack.find(used_op_tile)
	if index == -1:
		return
	
	_op_stack.remove_at(index)
	for i in range(_op_stack.size()):
		_op_stack[i].drop_operator_tile(index+1)
	
	used_op_tile.queue_free()
	
