tool
extends EditorPlugin

var ResourceCreaterDialog
func _enter_tree():
	ResourceCreaterDialog = preload("res://addons/EmbeddedResourceCreater/Creater.tscn").instance()
#	ResourceCreaterDialog.editor_interface = get_editor_interface()
	add_control_to_dock(DOCK_SLOT_LEFT_UL, ResourceCreaterDialog)

func _exit_tree():
	remove_control_from_docks(ResourceCreaterDialog)
	ResourceCreaterDialog.free()
