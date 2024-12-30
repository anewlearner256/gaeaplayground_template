extends Object

static func visible_all_children(parent:Node):
	for child in parent.get_children():
		if child is CullInstance:
			child.visible = false

static func set_children_layers(parent:Node,layer:int):
	if parent == null:
		return
	if parent is VisualInstance:
		parent.layers = layer
	for child in parent.get_children():
		if child is VisualInstance:
			child.layers = layer
		set_children_layers(child,layer)
