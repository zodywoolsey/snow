extends CharacterBody3D

const HIGHLIGHT = preload("res://assets/highlight.tres")

@export var VR : bool = false
@onready var hand = $cameraParent/Camera3D/hand
@onready var ray_cast_3d:RayCast3D = $cameraParent/Camera3D/RayCast3D
@onready var interaction_ray = $cameraParent/Camera3D/InteractionRay
@onready var audio_stream_player_3d = $AudioStreamPlayer3D
@onready var wind = $wind
var windMinVol = -50.0
var windMaxVol = -30.0

@export var SPEED : float = 2
@export var JUMP_VELOCITY : float = 5
@export var GRAVITY : float = 10
@export var MOUSE_SENSITIVITY : float = 100
@export var HEADBOB_INTENSITY : float = 0.01
@export var HEADBOB_SPEED : float = 1.0
var hbi
var hbs
var currentFallSpeed
var camera : Camera3D
var camera_parent
@onready var flare = preload("res://player/flare.tscn")
var direction
var mouseMotion : Vector2
var shootTimer = 0

@onready var grab_collider = $cameraParent/Camera3D/Area3D

var stepSoundFlag = false

var handSidePos := Vector3(.568,-.329,-1.395)
var handFrontPos := Vector3(0.0,0.0,-1.0)

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var prev_looking_at
var prev_interact_looking_at

func _ready():
	if !VR:
		camera = $cameraParent/Camera3D
		camera_parent = $cameraParent
		hand = $cameraParent/Camera3D/hand
	currentFallSpeed = GRAVITY
	hbs = HEADBOB_SPEED
	hbi = HEADBOB_INTENSITY

func _process(delta):
	if !hand.pickedObject:
		grab_check()
	handle_interaction()

func handle_interaction():
	if Input.is_action_just_pressed("activate"):
		if prev_interact_looking_at and "click" in prev_interact_looking_at:
			prev_interact_looking_at.click({})
	if interaction_ray.is_colliding():
		var tmp = interaction_ray.get_collider()
		if prev_interact_looking_at != tmp:
			if prev_interact_looking_at:
				clear_overlay(prev_interact_looking_at)
			set_overlay(tmp)
			prev_interact_looking_at = tmp
	else:
		if prev_interact_looking_at:
			if prev_interact_looking_at:
				clear_overlay(prev_interact_looking_at)
			prev_interact_looking_at = null

func grab_check():
	if ray_cast_3d.is_colliding():
		var tmp = ray_cast_3d.get_collider()
		if prev_looking_at != tmp:
			if prev_looking_at:
				clear_overlay(prev_looking_at)
			set_overlay(tmp)
			prev_looking_at = tmp
	else:
		if prev_looking_at and grab_collider.get_overlapping_bodies().size() == 0:
			if prev_looking_at:
				clear_overlay(prev_looking_at)
			prev_looking_at = null
		for body in grab_collider.get_overlapping_bodies():
			if body is RigidBody3D:
				if prev_looking_at:
					clear_overlay(prev_looking_at)
				set_overlay(body)
				prev_looking_at = body

func set_overlay(node:Node3D):
	if "object_root" in node and node.object_root is GeometryInstance3D:
		node.object_root.material_overlay = HIGHLIGHT
	else:
		for child in node.get_children():
			if child is GeometryInstance3D:
				child.material_overlay = HIGHLIGHT

func clear_overlay(node:Node3D):
	if "object_root" in node and node.object_root is GeometryInstance3D:
		node.object_root.material_overlay = null
	else:
		for child in node.get_children():
			if child is GeometryInstance3D:
				print('set null')
				child.material_overlay = null

func _physics_process(delta):
	var currentspeed = SPEED
	shootTimer += delta
	var kinput_dir = Vector2()
	var cinput_dir = Vector2()
	direction = Vector3()
	var jumped = false
	if not is_on_floor():
		velocity.y -= currentFallSpeed * delta
		stepSoundFlag = true
	
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		cinput_dir = Input.get_vector("cleft", "cright", "cforward", "cbackward")
		kinput_dir = Input.get_vector("kleft", "kright", "kforward", "kbackward")
		kinput_dir += cinput_dir
#		kinput_dir = kinput_dir
		direction = (transform.basis * Vector3(kinput_dir.x, 0, kinput_dir.y))
		
		if Input.is_action_pressed("jump"):
			jumped = jump()
	
	
	if direction and is_on_floor():
		if Input.is_action_pressed("run"):
			currentspeed*=2.0
			hbs = HEADBOB_SPEED*16.0
			hbi = HEADBOB_INTENSITY*2.0
		else:
			hbs = HEADBOB_SPEED*8.0
			hbi = HEADBOB_INTENSITY*1.5
		velocity.x = direction.x * currentspeed
		velocity.z = direction.z * currentspeed
	elif is_on_floor():
		velocity.x = move_toward(velocity.x, 0, currentspeed)
		velocity.z = move_toward(velocity.z, 0, currentspeed)
		hbs = HEADBOB_SPEED
		hbi = HEADBOB_INTENSITY
	if Globals.UI_STATE != 0:
		if Input.is_action_pressed("focus"):
			hand.position = handFrontPos
		else:
			hand.position = handSidePos
		if Input.is_action_just_pressed('shoot'):
			if prev_interact_looking_at and "click" in prev_interact_looking_at:
				prev_interact_looking_at.click({})
			hand.placed = false
			if hand.pickedObject == null:
				hand.pickedObject = prev_looking_at
				if hand.pickedObject:
					clear_overlay(hand.pickedObject)
			else:
				hand.placed = true
				hand.pickedObject = null
	
	var look = Input.get_vector("lookLeft","lookRight","lookDown","lookUp")
	if look.length() > .1:
		camera.rotate(Vector3.RIGHT, (look.y/1000)*MOUSE_SENSITIVITY)
		rotate(Vector3.UP, (-look.x/1000)*MOUSE_SENSITIVITY)
	
	
	move_and_slide()
	var currentWindVol = lerp(
		windMinVol,
		windMaxVol,
		clamp(velocity.length()/10.0,0.0,1.0)
		)
	wind.volume_db = lerp(wind.volume_db,currentWindVol,.1)
	mouseMotion = Vector2()
	if is_on_floor():
		camera_parent.position = lerp(Vector3(0,.5-hbi,0),Vector3(0,.5+hbi,0),sin(Time.get_unix_time_from_system()*hbs))
	if camera_parent.position.y<.46 and !stepSoundFlag:
		audio_stream_player_3d.play_random()
		stepSoundFlag = true
	elif camera_parent.position.y>.465 and stepSoundFlag:
		stepSoundFlag = false
#		print(camera_parent.position.y)
		pass
		
	if camera.rotation_degrees.x < -80:
		camera.rotation_degrees.x = -80
	if camera.rotation_degrees.x > 80:
		camera.rotation_degrees.x = 80


func _input(event):
	if event is InputEventMouseMotion:
		mouseMotion = event.relative
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			if !Input.is_key_pressed(KEY_E):
				rotate(Vector3.UP, ((-mouseMotion.x/100000)*MOUSE_SENSITIVITY) )
				if !VR:
					camera.rotate(Vector3.RIGHT, ((-mouseMotion.y/100000)*MOUSE_SENSITIVITY))
			else:
				hand.rotate(Vector3.UP, ((-mouseMotion.x/100000)*MOUSE_SENSITIVITY) )
				if !Input.is_key_pressed(KEY_SHIFT):
					hand.rotate(Vector3.RIGHT, ((mouseMotion.y/100000)*MOUSE_SENSITIVITY))
			
#	if event is InputEventMouseButton:
#		if event.pressed:
#			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func jump():
	if is_on_floor():
		velocity *= 1.5
		velocity += Vector3(get_floor_normal().x*2,1,get_floor_normal().z*2)*JUMP_VELOCITY
		return true
	return false
