extends Area2D

signal collected()

@onready var light: PointLight2D = $PointLight2D

var claimed = false

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player" and not claimed:
		body._change_points(1)
		light.enabled = false
		claimed = true
		emit_signal("collected")
