extends CharacterBody3D

class_name Spider

# core references
@onready var spider_model = %SpiderModel
@onready var main_char_model = %MainCharModel
@onready var anim_player : AnimationPlayer = %SpiderModel/AnimationPlayer

# references relevant for mount
@onready var camera_pivot = $CameraPivot
@onready var camera : Camera3D = $CameraPivot/SpringArm3D/Camera3D
@onready var main_char_ref : MainCharacter
@onready var detach_marker : Marker3D = $DetachMarker

@export_group("Mouse")
@export var mouse_sensitivity = 0.0015
@export var rotation_speed = 15.0

enum SpiderAnimState { IDLE, WALK, HIT, ATTACK, JUMP }

var is_mounted : bool
var can_mount : bool

var is_hit : bool
var is_jumping : bool
var is_attacking : bool

var animation_state : SpiderAnimState

@export var killzone_y = -10.0

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity") * 3

func _ready() -> void:
	GlobalState.init_level(2)
	GlobalState.start_timer()

	is_mounted = false
	can_mount = false

	is_hit = false
	is_jumping = false

	animation_state = SpiderAnimState.IDLE
	main_char_model.visible = false
	main_char_ref = null

# Shows and enables process of MainChar and sets spider camera enabled. Disables mounted state.
func detach_player_and_camera():
	camera.enabled = false
	main_char_model.visible = false
	is_mounted = false

	# enable monitoring on dismount
	$InteractArea.monitorable = true
	$InteractArea.monitoring = true

	if main_char_ref != null:
		main_char_ref.process_mode = Node.PROCESS_MODE_INHERIT
		main_char_ref.global_position = detach_marker.global_position
		main_char_ref.reset_physics_interpolation()
		main_char_ref.visible = true
		main_char_ref.camera.enabled = true

# Hides and disables process of MainChar and switches to spider camera. Enables mounted state.
func attach_player_and_camera():
	assert(main_char_ref != null)

	main_char_ref.camera.enabled = false
	main_char_ref.visible = false
	main_char_ref.process_mode = Node.PROCESS_MODE_DISABLED

	camera.enabled = true

	# disable monitoring while mounted, no need for it
	$InteractArea.monitoring = false
	$InteractArea.monitorable = false

	is_mounted = true
	main_char_model.visible = true

func _process(_delta: float) -> void:
	# npc movement if not is_mounted
	if !is_mounted and !is_hit:
		animation_state = SpiderAnimState.IDLE

	sync_animation()

func _physics_process(_delta):
	if global_position.y < killzone_y:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		# TODO game_over()
		return

	if !is_mounted:
		return

	# character controller if is_mounted
	if is_jumping:
		if is_on_floor():
			is_jumping = false
		else:
			animation_state = SpiderAnimState.JUMP
	if !velocity.is_zero_approx():
		animation_state = SpiderAnimState.WALK
	elif velocity.is_zero_approx():
		animation_state = SpiderAnimState.IDLE

	# TODO support spider jump?

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if event.is_action_pressed("click"):
		if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		animation_state = SpiderAnimState.ATTACK
		is_attacking = true

	if event.is_action_pressed("jump"):
		if !is_jumping and is_on_floor():
			is_jumping = true
			# TODO sound

	if event.is_action_pressed("toggle_mount"):
		if !is_mounted and can_mount:
			attach_player_and_camera()
		elif is_mounted:
			detach_player_and_camera()


func _unhandled_input(event: InputEvent) -> void:
	if is_mounted and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		# camera handling on mouse movement
		camera_pivot.rotation.x -= event.relative.y * mouse_sensitivity
		camera_pivot.rotation_degrees.x = clampf(camera_pivot.rotation_degrees.x, -90.0, 30.0)
		camera_pivot.rotation.y -= event.relative.x * mouse_sensitivity

func play_animation(anim_name: String):
	if anim_player.is_playing() and anim_player.current_animation == anim_name:
		return

	anim_player.play(anim_name)

func sync_animation():
	match animation_state:
		SpiderAnimState.IDLE:
			play_animation("HumanArmature|Spider_Idle")
		SpiderAnimState.WALK:
			play_animation("HumanArmature|Spider_Walk")
		SpiderAnimState.HIT:
			play_animation("HumanArmature|Spider_Death")
		SpiderAnimState.ATTACK:
			play_animation("HumanArmature|Spider_Attack")
		SpiderAnimState.JUMP:
			play_animation("HumanArmature|Spider_Jump")

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "HumanArmature|Spider_Death" and is_hit:
		await get_tree().create_timer(1).timeout
		anim_player.play_backwards(anim_name)

# Interact area detects if main char is within range and enables can_mount
func _on_interact_area_body_entered(body: Node3D) -> void:
	if body is MainCharacter:
		can_mount = true
		main_char_ref = body

func _on_interact_area_body_exited(body: Node3D) -> void:
	if body is MainCharacter:
		can_mount = false
		main_char_ref = null # is this needed? can cause bugs?
