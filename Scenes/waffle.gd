extends Control

signal became_cold

enum CookState { 
	UNCOOKED, 
	COOKED, 
	BURNT 
}
enum TempState { 
	HOT, 
	COLD 
}

#all this is used in plate
var quarters_count: int = 1
var is_plated: bool = false
var cut_locked: bool = false
var current_plate = null

#this is the variable you will have to pass from grill, 1, 2, 3, 4 depending on what quarter you have filled.
@export var sections: Array[int] = [1]

#initializing 
@export var cook_state: CookState = CookState.UNCOOKED
@export var temp_state: TempState = TempState.HOT

@export var cold_time_total: float = 20.0
var cold_time_left: float = 20.0
var cold_counting: bool = false

#all the textures
@export var q1_uncooked: Texture2D
@export var q2_uncooked: Texture2D
@export var q3_uncooked: Texture2D
@export var q4_uncooked: Texture2D
@export var half_uncooked: Texture2D
@export var threeq_uncooked: Texture2D
@export var full_uncooked: Texture2D

@export var q1_hot: Texture2D
@export var q2_hot: Texture2D
@export var q3_hot: Texture2D
@export var q4_hot: Texture2D
@export var half_hot: Texture2D
@export var threeq_hot: Texture2D
@export var full_hot: Texture2D

@export var q1_cold: Texture2D
@export var q2_cold: Texture2D
@export var q3_cold: Texture2D
@export var q4_cold: Texture2D
@export var half_cold: Texture2D
@export var threeq_cold: Texture2D
@export var full_cold: Texture2D

@export var q1_burnt: Texture2D
@export var q2_burnt: Texture2D
@export var q3_burnt: Texture2D
@export var q4_burnt: Texture2D
@export var half_burnt: Texture2D
@export var threeq_burnt: Texture2D
@export var full_burnt: Texture2D

@onready var sprite: TextureRect = $Sprite
@onready var cold_bar: TextureProgressBar = $ColdBar

#constructor
func _ready() -> void:
	cook_state = CookState.UNCOOKED
	temp_state = TempState.HOT
	cold_counting = false
	cold_time_left = cold_time_total
	
	_normalize_sections()
	_recompute_quarters_count()
	_apply_sprite()
	_update_coldbar()


#this is checking every frame whether cold timer is started or not. if you have started it, then this will update progress bar
func _process(delta: float) -> void:
	if not cold_counting:
		return

	if cook_state != CookState.COOKED:
		return

	if temp_state == TempState.COLD:
		return

	cold_time_left -= delta
	if cold_time_left <= 0.0:
		cold_time_left = 0.0
		temp_state = TempState.COLD
		_apply_sprite()
		emit_signal("became_cold")

	_update_coldbar()
	

#used in build/cook all these:
func configure(p_sections: Array[int]) -> void:
	#grill uses this to spawn waffle, specific size of waffle, and specific orientation of it (i will explain it irl better...)
	sections = p_sections.duplicate()
	_normalize_sections()
	_recompute_quarters_count()
	_apply_sprite()
	
func set_cook_state(state: CookState) -> void:
	cook_state = state
	_apply_sprite()
	
func set_temp_state(state: TempState) -> void:
	temp_state = state
	_apply_sprite()
	
func start_cold_timer() -> void:
	#you call this to start cold bar
	cold_time_left = cold_time_total
	temp_state = TempState.HOT
	cold_counting = true
	_apply_sprite()
	_update_coldbar()
	
func stop_cold_timer() -> void:
	cold_counting = false
	_update_coldbar()
	
#plate ghost preview uses this
func get_plate_sprite() -> Texture2D:
	return sprite.texture
	

#internal helpers
func _normalize_sections() -> void:
	#keeps only values 1-4, remove duplicates, and sorts
	var seen := {}
	var cleaned: Array[int] = []
	for s in sections:
		var v := int(s)
		if v < 1 or v > 4:
			continue
		if seen.has(v):
			continue
		seen[v] = true
		cleaned.append(v)
	cleaned.sort()
	if cleaned.size() == 0:
		cleaned = [1] #fallback
	sections = cleaned
	

func _recompute_quarters_count() -> void:
	quarters_count = sections.size()


func _apply_sprite() -> void:
	var t: Texture2D = null

	if cook_state == CookState.UNCOOKED:
		t = _pick_sprite_uncooked()
	elif cook_state == CookState.BURNT:
		t = _pick_sprite_burnt()
	else:
		# COOKED
		if temp_state == TempState.HOT:
			t = _pick_sprite_hot()
		else:
			t = _pick_sprite_cold()

	sprite.texture = t


func _pick_sprite_uncooked() -> Texture2D:
	return _pick_by_size_and_section(
		q1_uncooked, q2_uncooked, q3_uncooked, q4_uncooked,
		half_uncooked, threeq_uncooked, full_uncooked
	)



func _pick_sprite_hot() -> Texture2D:
	return _pick_by_size_and_section(
		q1_hot, q2_hot, q3_hot, q4_hot,
		half_hot, threeq_hot, full_hot
	)


func _pick_sprite_cold() -> Texture2D:
	return _pick_by_size_and_section(
		q1_cold, q2_cold, q3_cold, q4_cold,
		half_cold, threeq_cold, full_cold
	)


func _pick_sprite_burnt() -> Texture2D:
	return _pick_by_size_and_section(
		q1_burnt, q2_burnt, q3_burnt, q4_burnt,
		half_burnt, threeq_burnt, full_burnt
	)


func _pick_by_size_and_section(q1: Texture2D, q2: Texture2D, q3: Texture2D, q4: Texture2D,
	half_t: Texture2D, threeq_t: Texture2D, full_t: Texture2D) -> Texture2D:

	match quarters_count:
		1:
			#for single quarter, we respect which grill slot (1-4)
			var sec := sections[0]
			match sec:
				1: return q1
				2: return q2
				3: return q3
				4: return q4
			return q1
		2:
			#halves always display as {1,2} because they will just be in plate so only one orientation needed
			return half_t
		3:
			#same logic as half
			return threeq_t
		4:
			#same logic as half
			return full_t
	return null



func _update_coldbar() -> void:
	if cold_bar == null:
		return
	if not cold_counting:
		cold_bar.value = 1
		return
	if cold_time_total <= 0.0:
		cold_bar.value = 0
		return
	cold_bar.value = cold_time_left/cold_time_total
