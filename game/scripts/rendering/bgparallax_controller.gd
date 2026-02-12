class_name BGParallax
extends Node
## Dynamically scales and positions parallax background layers


func setup(camera: Camera2D) -> void:
	for sibling in get_children():
		if sibling is Parallax2D:
			_configure_layer(sibling)


func _configure_layer(layer: Parallax2D) -> void:
	var max_width = 0
	for child in layer.get_children():
		if not (child is Sprite2D and child.texture):
			continue
		max_width = max(child.texture.get_size().x, max_width)
	
	layer.scroll_scale = Vector2(layer.scroll_scale.x, 0.8)
	# Update repeat_size to match the scaled texture width
	if max_width > 0:
		layer.repeat_size = Vector2(max_width, 0)
		layer.repeat_times = 5
