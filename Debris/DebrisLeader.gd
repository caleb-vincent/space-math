extends RigidBody2D


signal offScreen
signal impact
signal teleportReady
signal teleportDone

export var moveSpeed : float = 100
export var group : String = ""

var _follower : PhysicsBody2D
var _jumpTo = Vector2.ZERO
var _pause = false


func connectTo(p : PhysicsBody2D) -> void:
	var oldNode = _follower
	if p != oldNode:
		p.group = group
		p.collision_layer = 0x4
		p.leader = self
		_follower = p
		p.custom_integrator = true
		if oldNode != null:
			p.connectTo(oldNode)


func clearChain() -> void:
	_follower.clearChain()
	_follower = null
	queue_free()


func hiddenChain() -> void:
	if _follower != null:
		yield(_follower.hiddenChain(), "completed")
	emit_signal("offScreen", self)


func teleportChain(pos : Vector2) -> void:
	print("Preparing to teleport ", self)
	_pause = true
	if _follower != null:
		_follower.teleportChain(pos + Vector2(48, 0))
		yield(_follower, "teleportReady")
	_prepareTeleport(pos)
	yield(self, "teleportReady")
	emit_signal("teleportDone")
	print("Teleport Done ", self)
	_pause = false


func teleport(newPos : Vector2) -> void:
	get_tree().call_group(group, "teleport", newPos - position)


################################################################################
#	Inherited Methods
################################################################################


func _ready() ->void:
	linear_velocity = Vector2(-200, 20)
	group = "group_" + name


func  _integrate_forces (state : Physics2DDirectBodyState ):
	if _jumpTo != Vector2.ZERO:
		print("Teleporting ", self)
		var xform = state.get_transform()
		xform.origin = _jumpTo
		state.set_transform(xform)
		state.linear_velocity = Vector2.ZERO
		_jumpTo = Vector2.ZERO
		emit_signal("teleportReady")
	elif !_pause:
		state.linear_velocity = Vector2(-200, 20)


################################################################################
#	Singal Methods
################################################################################


func _prepareTeleport(pos : Vector2):
	_jumpTo = pos


################################################################################
#	Signal Methods
################################################################################


func _on_VisibilityNotifier2D_screen_exited() -> void:
	hiddenChain()


func _on_DebrisLeader_body_entered(body: PhysicsBody2D) -> void:
	if body is StaticBody2D:
		emit_signal("impact", self)
