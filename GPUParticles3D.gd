extends GPUParticles3D

var s = 5

func _process(delta):
	var pp : Vector3 = get_tree().get_first_node_in_group('player').global_position
	global_position.x = pp.x
	global_position.z = pp.z
