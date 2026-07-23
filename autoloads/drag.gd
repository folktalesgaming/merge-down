extends Node

var picked_operator_tile: Tile = null

func change_picked_tile(new_tile: Tile):
	picked_operator_tile = new_tile

func remove_picked_tile():
	picked_operator_tile = null
