extends Node

var player : CharacterBody3D
var world : Node3D
var environment : Environment
var pause : Control
var seed : String = "10"
var loadingProgress := 0

@export_enum("main","pause","none") var UI_STATE : int = 1

func _ready():
	find_environment()
	match OS.get_name():
		"Web", "Android", "IOS":
			environment.fog_enabled = true
		_:
			environment.volumetric_fog_enabled = true
	find_player()

func _process(delta):
	if pause or true:
		if UI_STATE == 1:
#			pause.show()
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		elif UI_STATE == 2:
#			pause.hide()
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if Input.is_action_just_pressed("ui_cancel") or Input.is_key_pressed(KEY_ESCAPE):
		UI_STATE = 1
	if Input.is_action_just_pressed("shoot"):
		UI_STATE = 2

func find_player():
	player = get_tree().get_first_node_in_group('player')

func find_environment():
	var tmp = get_tree().get_first_node_in_group("environment")
	print(tmp)
	if tmp is WorldEnvironment:
		environment = tmp.environment
	elif tmp is Environment:
		environment = tmp
