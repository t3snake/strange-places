extends CharacterBody3D

# references
@onready var spider_model = %SpiderModel
@onready var main_char_model : MainCharacter = %MainCharModel
@onready var anim_player = %SpiderModel/AnimationPlayer

enum SpiderAnimState { IDLE, WALK, HIT, ATTACK, JUMP }

var is_mounted : bool
var animation_state : SpiderAnimState

@export var killzone_y = -10.0

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity") * 3

func _ready() -> void:
	is_mounted = false
	animation_state = SpiderAnimState.IDLE
	main_char_model.visible = false

func _physics_process(delta):
	if global_position.y < killzone_y:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		# TODO game_over()
	# npc movement if not is_mounted
	# character controller if is_mounted

# Supposed to be called by MainCharacter when mount button is pressed
func register_mount():
	is_mounted = true
	main_char_model.visible = true
