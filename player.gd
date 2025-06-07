
extends CharacterBody2D
class_name PlayerClass

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attackBtn: Button = $"../UI/GridContainer/Attack"
@onready var heavyAttackBtn: Button = $"../UI/GridContainer/HeavyAttack"
@onready var ui: Control = $"../UI"

@onready var health_bar: ProgressBar = $healthBar

@export var attackPOS := Vector2(23.0, 105.0)
@export var enemyPOS := Vector2()

@export var health := 100
@export var numberOfActions := 2
var attack_animations := {
	"attack_01": { "damage": 10, "hits": 1 },
	"attack_02": { "damage": 15, "hits": 2 },  # Two hits!
	"attack_03": { "damage": 25, "hits": 1 }
}

var actionsUsed := 0
var selected_enemy: EnemyClass = null

func _ready() -> void:
	Global.isPlayerAttack = true
	if not EnemySelectionManager.enemy_selected_global.is_connected(_on_enemy_selected):
		EnemySelectionManager.enemy_selected_global.connect(_on_enemy_selected)
	if not EnemySelectionManager.player_turn_started.is_connected(_on_player_turn_started):
		EnemySelectionManager.player_turn_started.connect(_on_player_turn_started)
	if not EnemySelectionManager.enemy_turn_started.is_connected(_on_enemy_turn_started):
		EnemySelectionManager.enemy_turn_started.connect(_on_enemy_turn_started)

	_spawn()
	_on_player_turn_started()
	await sprite.animation_finished
	sprite.play("Idle")

#region Signal Handling

func _on_enemy_selected(enemy: EnemyClass) -> void:
	selected_enemy = enemy  # Save for later use
	
	if selected_enemy != null:
		enemyPOS = selected_enemy.global_position
		enemyPOS.x -= 30.0
		handle_UI(false, 0.0)  # Enable UI because enemy is selected
	else:
		enemyPOS = Vector2.ZERO
		handle_UI(true, 0.0)  # Disable UI because no enemy is selected

func _on_player_turn_started() -> void:
	actionsUsed = 0
	if selected_enemy != null:
		handle_UI(false, 0.5)  # Enable UI for player turn if enemy selected
	else:
		handle_UI(true, 0.0)   # Disable UI if no enemy selected

func _process(delta: float) -> void:
	health_bar.value = health

func _on_enemy_turn_started() -> void:
	handle_UI(true, 0.0)  # Disable UI for enemy turn

#endregion

func _on_attack_pressed() -> void:
	handle_UI(true, 0.0)
	if enemyPOS == Vector2.ZERO:
		return

	# Move to enemy
	sprite.play("Walk")
	sprite.flip_h = false
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(self, "global_position", enemyPOS, 0.7)
	await tween.finished

	# Randomly pick an attack
	var keys = attack_animations.keys()
	var chosen_attack = keys[randi() % keys.size()]
	var attack_data = attack_animations[chosen_attack]
	var damage_per_hit = attack_data.damage
	var hits = attack_data.hits

	sprite.play(chosen_attack)
	await sprite.animation_finished

	# Deal hits (can be 1 or more)
	if selected_enemy and selected_enemy.is_inside_tree():
		for i in range(hits):
			selected_enemy.take_damage(damage_per_hit)
			await get_tree().create_timer(0.2).timeout  # short pause between hits

	# Return to idle position
	sprite.flip_h = true
	sprite.play("Walk")
	var tween_back = create_tween()
	tween_back.set_trans(Tween.TRANS_SINE)
	tween_back.set_ease(Tween.EASE_IN)
	tween_back.tween_property(self, "global_position", attackPOS, 0.7)
	await tween_back.finished

	sprite.flip_h = false
	sprite.play("Idle")

	# End turn handling
	actionsUsed += 1
	if actionsUsed >= numberOfActions:
		Global.isPlayerAttack = false
		EnemySelectionManager.start_enemy_turn()
		handle_UI(true, 0.0)
	else:
		handle_UI(false, 0.0)



func _spawn() -> void:
	handle_UI(false, 0.0)
	sprite.play("Walk")
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(self, "global_position", attackPOS, 0.7)

func handle_UI(off: bool, delay_sec : float) -> void:
	await get_tree().create_timer(delay_sec).timeout
	_toggle_ui_recursive(ui, off)

func _toggle_ui_recursive(node: Node, off: bool) -> void:
	for child in node.get_children():
		if child is Button:
			child.disabled = off
		_toggle_ui_recursive(child, off)

func take_damage(amount: int) -> void:
	sprite.play("Hurt")
	health -= amount
	
	if health <= 0:
		await sprite.animation_finished
		die()
	await sprite.animation_finished
	sprite.play("Idle")

func die():
	sprite.play("Death")
	await sprite.animation_finished
	queue_free()
