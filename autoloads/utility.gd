extends Node2D

func get_weighted_random_type(weights: Array[int]) -> int:
	var total_weight = weights.reduce(func(acc, num): return acc + num, 0)
	var roll = randi_range(1, total_weight)
	
	var current_sum = 0
	for i in range(weights.size()):
		current_sum += weights[i]
		if roll <= current_sum:
			return i
	
	return 0
