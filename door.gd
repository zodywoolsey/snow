@tool
extends StaticBody3D

@onready var object_root = $"../"

@export var rotation_closed := Vector3()
@export var rotation_open := Vector3()

@export var open:=false
@export var degrees:=true

func click(data:Dictionary):
	open = !open

func _process(delta):
	if open:
		object_root.rotation.x = lerpf(object_root.rotation.x, deg_to_rad(rotation_open.x), .1)
		object_root.rotation.y = lerpf(object_root.rotation.y, deg_to_rad(rotation_open.y), .1)
		object_root.rotation.z = lerpf(object_root.rotation.z, deg_to_rad(rotation_open.z), .1)
	elif !open:
		object_root.rotation.x = lerpf(object_root.rotation.x, deg_to_rad(rotation_closed.x), .1)
		object_root.rotation.y = lerpf(object_root.rotation.y, deg_to_rad(rotation_closed.y), .1)
		object_root.rotation.z = lerpf(object_root.rotation.z, deg_to_rad(rotation_closed.z), .1)
