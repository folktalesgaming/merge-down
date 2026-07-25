extends Node2D

@onready var main_grid = %MainGrid
@onready var operator_stack = %OperatorStack
@onready var drop_zones = %DropZones
@onready var container = %Container
@onready var complete_heading = %CompleteHeading
@onready var next_lvl_btn = %NextLvlBtn
@onready var no_btn = %NoBtn
@onready var score = %Score
@onready var description = %Description

const TilePrefab = preload("res://prefabs/Tile.tscn")
const DropZonePrefab = preload("res://prefabs/DropZone.tscn")

var board: Array[Array]
var drop_top_zones: Array[Array]
var drop_in_zones: Array[Array]

var level: int = 1
var _board_gap: int = 90
var _op_gap: int = 80
var is_stucked: bool = false

func _ready():
	GameManager.board_updated.connect(on_board_updated)
	GameManager.new_operator_tile_added.connect(on_operator_tile_added)
	GameManager.tile_cleared.connect(on_tile_cleared)
	GameManager.negative_hazard.connect(on_negative_hazard)
	GameManager.level_completed.connect(on_level_completed)
	GameManager.level_stuck.connect(on_level_stuck)
	GameManager.in_between_tile_status_changed.connect(on_in_between_tile_status_changed)
	GameManager.action_num_increased.connect(change_description_text)
	
	reset()
	new_game()

func reset():
	GameManager.set_lower_limit(8) # setting loweset number in board
	GameManager.set_upper_limit(40) # setting highest number in board
	
	GameManager.set_stack_size(7) # setting number of operator at a time
	
	for op_tile in operator_stack.get_children():
		op_tile.remove_tile()
	
	for child in drop_zones.get_children():
		child.queue_free()
	
	for child in main_grid.get_children():
		child.queue_free()
	
	board.clear()
	drop_in_zones.clear()
	drop_top_zones.clear()

func new_game():
	# Initializing board and operator stack data
	GameManager.Initialize_Board_Tutorial(level)
	GameManager.Initialize_Stack_Tutorial(level)
	
	var board_size = GameManager.get_board_size()
	for i in range(board_size):
		var row: Array[Tile] = []
		var zones: Array[DropZone] = []
		var in_zones: Array[DropZone] = []
		row.resize(board_size)
		zones.resize(board_size)
		for j in range(board_size):
			zones[j] = add_on_top_drop_zone(i, j)
			var between_zones = add_in_between_drop_zone(i, j)
			for b_z in between_zones:
				in_zones.append(b_z)
			row[j] = initiate_num_tile(GameManager.get_board_tile_data(i, j), i, j)
			
		board.append(row)
		drop_top_zones.append(zones)
		drop_in_zones.append(in_zones)
		GameManager._in_between_drop_zone_status.append(in_zones)
	
	# Initialize a stack of operators with random operator tiles
	for i in range(GameManager.get_stack_size()):
		initiate_operator_tile(i)
	
	score.text = "Score: " + str(GameManager._total)
	change_description_text()

func change_description_text():
	match GameManager.action_num:
		0:
			description.text = "Welcome to Merge Doown!!! You merge numbers down instead of up. Let's get started drag the -14 operator tile and drop on top of tile 34."
		1:
			description.text = "Great. As expected we merge the number 34 down to 20, now drag the '/' operator in between tiles 6 & 30"
		2:
			description.text = "As you can see, operator tiles with no number can be dropped between two adjacent number tiles to operate smaller number to bigger. Now drag the '-' operator tile between tiles 55 && 20"
		3:
			description.text = "In each turn you have access to the first 3 operators in the list. You don't have to use the first tile all the time. Play ahead by dragging the '/' operator between tiles 35 & 5"
		4:
			description.text = "Nice, Now you can use the first opertor -7 to end the level"
		5:
			description.text = ""
		6:
			description.text = "Aren't you curious. Well in this one we will look into something amazing, drag -24 on top of the 24 tile"
		7:
			description.text = "If the number hits 0 we clear that tile and our goal is as you have noticed too clear all tiles. Lets clear the tile drag -17 on top of tile 17"
		8:
			description.text = ""
		9:
			description.text = "Sorry about earlier but had to show that sooner or later. But now we will see some actual something, go ahead drag /12 on top of 43. Trust me go ahead"
		10:
			description.text = "When we have a floating division instead of the quotient, it converts the number to reminder watch out for that. Now drag the /45 on top of the bottom 7"
		11:
			description.text = "If the dividing number is greater though you get rid of the big divider operator tile for new tile your number gets increased by 3. Why 3 idk just like the number 3. Let's complete the tutorial drag '/' in between 20 and 10"
		12:
			description.text = "Now drag '-' in between 7 & 2"
		13:
			description.text = "drag '/' in between 5 & 31"
		14:
			description.text = "As you see the operators with no numbers are powerful but they also can cause you loose the game as seen before so be wise. Let's end by dragging the -1 on top of 1"
		15:
			description.text = ""
		16:
			description.text = "You are determined to learn. I like it. Let's get going drag the -25 on top of 12"
		17:
			description.text = "What was that. If you ever count your numbers down to negative a hazard will happen (the negative result will replace any random operator on the list). Alright that's it for now. I am learning alot of things. You can complete this tutorial and play some randomly generated levels. Thank you!!!"

# Initiate number tile in the board
func initiate_num_tile(v: int, r: int, c: int) -> Tile:
	var tile: Tile = TilePrefab.instantiate()
	tile.position = Vector2((c+1) * _board_gap, (r+1) * _board_gap)
	main_grid.add_child(tile)
	tile.Initialize_Value(v)
	tile.set_board_pos(r, c)
	
	return tile

func add_on_top_drop_zone(r: int, c: int) -> DropZone:
	if r >= 0 and r < drop_top_zones.size() and c >= 0 and c < drop_top_zones[r].size():
		drop_top_zones[r][c].tiles.clear()
		return drop_top_zones[r][c]
	
	var dropZone: DropZone = DropZonePrefab.instantiate()
	dropZone.type = GlobalConst.DropZone.ON_TOP
	dropZone.is_active = true
	dropZone.add_board_pos(Vector2(r, c))
	dropZone.position = Vector2((c+1) * _board_gap, (r+1) * _board_gap)
	drop_zones.add_child(dropZone)
	
	return dropZone

func add_in_between_drop_zone(r: int, c: int) -> Array[DropZone]:
	var d_zones: Array[DropZone] = [];
	
	if r+1 < GameManager.get_board_size():
		var d_zone: DropZone = DropZonePrefab.instantiate()
		d_zone.type = GlobalConst.DropZone.IN_BETWEEN
		d_zone.is_active = true
		d_zone.visible = false
		d_zone.add_board_pos(Vector2(int(r), int(c)))
		d_zone.add_board_pos(Vector2(int(r + 1), int(c)))
		d_zone.scale = Vector2(0.4, 0.5)
		
		d_zone.position = Vector2((c+1) * _board_gap, (r+1.5) * _board_gap)
		drop_zones.add_child(d_zone)
		d_zones.append(d_zone)
	
	if c+1 < GameManager.get_board_size():
		var d_zone: DropZone = DropZonePrefab.instantiate()
		d_zone.type = GlobalConst.DropZone.IN_BETWEEN
		d_zone.is_active = true
		d_zone.visible = false
		if !d_zone.check_board_pos(Vector2(int(r), int(c))):
			d_zone.add_board_pos(Vector2(int(r), int(c)))
		d_zone.add_board_pos(Vector2(int(r), int(c + 1)))
		d_zone.scale = Vector2(0.5, 0.4)
		
		d_zone.position = Vector2((c+1.5) * _board_gap, (r+1) * _board_gap)
		drop_zones.add_child(d_zone)
		d_zones.append(d_zone)
		
	return d_zones

func has_decimal(n: float) -> bool:
	return abs(fmod(n, 1.0)) > 0.00001

# Initiate operator tile in the operator stack
func initiate_operator_tile(p: int):
	var tile: Tile = TilePrefab.instantiate()
	var width = get_window().size.x
	var height = get_window().size.y
	tile.position = Vector2(width - _op_gap, height - (p+1) * _op_gap)
	
	operator_stack.add_child(tile)
	tile.set_stack_pos(p)
	tile.Initialize_Value(
		GameManager._op_stack[p]["value"], 
		GameManager._op_stack[p]["symbol"],
		GameManager._op_stack[p]["type"]
	)

func negative_op_tile(val: int, index: int, r: int, c: int):
	var tile: Tile = TilePrefab.instantiate()
	tile.position = Vector2((c+1) * _board_gap, (r+1) * _board_gap)
	var width = get_window().size.x
	var height = get_window().size.y
	tile.initial_position = Vector2(width - _op_gap, height - (index+1) * _op_gap)
	
	operator_stack.add_child(tile)
	operator_stack.move_child(tile, index)
	tile.Initialize_Value(
		val, 
		GlobalConst.OperatorSymbol.SUB, 
		GlobalConst.OperatorType.SINGLE
	)
	await get_tree().create_timer(0.2).timeout
	tile.set_stack_pos(index)
	tile.set_state(Tile.STATE.BACKTOIDLE)

func on_board_updated(row: int, col: int, new_val: int):
	var tile = board[row][col]
	if is_instance_valid(tile):
		tile.render_tile(new_val)
	else:
		initiate_num_tile(new_val, row, col)
		drop_top_zones[row][col].is_active = true
		check_in_between_zones_status(row, col)
	AudioManager.Play_Consume_Operator_SFX()
	score.text = "Score: " + str(GameManager._total)
	change_description_text()

func on_tile_cleared(row: int, col: int):
	var tile: Tile = board[row][col]
	drop_top_zones[row][col].is_active = false
	tile.remove_tile()
	AudioManager.Play_Tile_Clear_SFX()

func on_operator_tile_added(removed_op_pos: int):
	for op_tile in operator_stack.get_children():
		op_tile.drop_op_tile(removed_op_pos)
	
	initiate_operator_tile(6)

func on_negative_hazard(s_i: int, val: int, r: int, c: int, r_i: int):
	var op_tile: Tile = operator_stack.get_child(s_i)
	negative_op_tile(abs(val), s_i, r, c)
	op_tile.remove_tile_by_swap()
	
	await get_tree().create_timer(0.7).timeout
	
	if s_i != r_i:
		on_operator_tile_added(r_i)

func check_in_between_zones_status(r: int, c: int):
	for i in range(drop_in_zones.size()):
		for j in range(drop_in_zones[i].size()):
			if drop_in_zones[i][j].check_board_pos(Vector2(r, c)):
				var next_pair = drop_in_zones[i][j].get_another_pair(Vector2(r, c))
				if is_instance_valid(board[int(next_pair.x)][int(next_pair.y)]):
					drop_in_zones[i][j].is_active = true

func on_in_between_tile_status_changed(r: int, c: int, s: bool):
	for i in range(drop_in_zones.size()):
		for j in range(drop_in_zones[i].size()):
			if drop_in_zones[i][j].check_board_pos(Vector2(r, c)):
				drop_in_zones[i][j].is_active = s

func on_level_completed():
	score.text = "Score: " + str(GameManager._total)
	
	is_stucked = false
	if level == 3:
		complete_heading.text = "Ready for next feature"
		next_lvl_btn.text = "One more? Ok"
		no_btn.text = "I am bored play the game"
	elif level == 4:
		complete_heading.text = "Ready to play the game"
		next_lvl_btn.text = "Yess, finally"
		no_btn.text = "Born ready"
	else:
		complete_heading.text = "Learn new thing"
		next_lvl_btn.text = "Yess"
		no_btn.text = "No, Just play the game"
	container.visible = true

func on_level_stuck():
	is_stucked = true
	complete_heading.text = "If you have 3 no number opertors to choose but no adjacent tiles that's game over"
	next_lvl_btn.text = "Learn next thing"
	no_btn.text = "That's enough let's play"
	level += 1
	container.visible = true

func _on_next_lvl_btn_pressed():
	AudioManager.Play_Button_Click_SFX()
	if level == 4:
		GameManager.set_board_size(3)
		get_tree().change_scene_to_file("res://scenes/GamePlay.tscn")
		return
	if !is_stucked:
		level += 1
	reset()
	new_game()
	container.visible = false
	GameManager.increase_action_num()

func _on_no_btn_pressed():
	AudioManager.Play_Button_Click_SFX()
	reset()
	container.visible = false
	GameManager.reset_action_num()
	GameManager.set_board_size(3)
	get_tree().change_scene_to_file("res://scenes/GamePlay.tscn")
