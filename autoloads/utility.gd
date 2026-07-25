extends Node2D

# get random integer from 0 to size of the weights array
# with weight determining the probability of each integer
func get_weighted_random_type(weights: Array[int]) -> int:
	var total_weight = weights.reduce(func(acc, num): return acc + num, 0)
	var roll = randi_range(1, total_weight)
	
	var current_sum = 0
	for i in range(weights.size()):
		current_sum += weights[i]
		if roll <= current_sum:
			return i
	
	return 0

# check the contrast of the color with white text
func ensure_contrast_with_white(color: Color, min_contrast: float = 4.5) -> Color:
	var c := color
	var attempts := 0
	while contrast_ratio(c, Color.WHITE) < min_contrast and attempts < 20:
		c = c.darkened(0.05)
		attempts += 1
	return c

# get the contrast ratio between the color and white
func contrast_ratio(c1: Color, c2: Color) -> float:
	var l1 := relative_luminance(c1) + 0.05
	var l2 := relative_luminance(c2) + 0.05
	return max(l1, l2) / min(l1, l2)

# get relative luminance of the given color
func relative_luminance(c: Color) -> float:
	var r := linearize(c.r)
	var g := linearize(c.g)
	var b := linearize(c.b)
	return 0.2126 * r + 0.7152 * g + 0.0722 * b

# linearize the channel of color
func linearize(channel: float) -> float:
	if channel <= 0.03928:
		return channel / 12.92
	return pow((channel + 0.055) / 1.055, 2.4)



# get valid neighbour tiles
func get_valid_next_tile(r: int, c: int, size: int) -> Vector2:
	var valid_tiles: Array[Vector2] = [
		Vector2(r-1, c),
		Vector2(r+1, c),
		Vector2(r, c-1),
		Vector2(r, c+1)
	]
	var to_remove_indices: Array[Vector2] = []
	
	for i in 4:
		if valid_tiles[i].x < 0 or valid_tiles[i].y < 0:
			to_remove_indices.append(valid_tiles[i])
		elif valid_tiles[i].x >= size or valid_tiles[i].y >= size:
			to_remove_indices.append(valid_tiles[i])
	
	for i in range(to_remove_indices.size()):
		valid_tiles.erase(to_remove_indices[i])
	
	return valid_tiles.pick_random()
