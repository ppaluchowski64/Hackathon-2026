extends Area2D
class_name Collectable

static func instantiate() -> Collectable:
	return preload("res://scenes/collactable.tscn").instantiate() as Collectable

@onready var sprite: Sprite2D = $Sprite2D
@onready var glow_sprite: Sprite2D = $GlowSprite

var anim: float = 0

enum Type {NULL = -1, ROPE, BOMB, SLAP, GOUDA}
var type: Type = randi_range(0, 3) as Type

func _ready() -> void:
	sprite.frame = type

func _physics_process(delta: float) -> void:
	anim += delta
	
	var offset: float = sin(anim * 6) * 4
	sprite.offset.y = offset
	glow_sprite.offset.y = offset
	glow_sprite.scale = Vector2.ONE * ((sin(anim * 12) + 1) / 2 * 0.1 + 0.9)

func _on_body_entered(body: Node2D) -> void:
	if not body is Player:
		return
	
	var player: Player = body
	player.collectable = type
	queue_free()
