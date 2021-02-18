extends RigidBody2D

signal outOfSight
signal inSight
signal connectionChange
signal teleportDone
signal teleportReady

const DebrisLeader = preload("DebrisLeader.gd")

var value : int = INF setget _setValue
var isFirst : bool = true setget _setIsFirst
var leader : PhysicsBody2D = null
var follower : PhysicsBody2D = null
var group : String = ""

var _jumpTo = Vector2.ZERO
var _hasLeftScreen = false
var _pause = false

################################################################################
#	Inherited Methods
################################################################################


func _process(delta: float) -> void:
	pass


func  _integrate_forces (state : Physics2DDirectBodyState ):
	if _jumpTo != Vector2.ZERO:
		print("Teleporting ", self)
		var xform = state.get_transform()
		xform.origin = _jumpTo
		state.set_transform(xform)
		state.linear_velocity = Vector2.ZERO
		_jumpTo = Vector2.ZERO
		emit_signal("teleportReady")
	elif leader != null && is_instance_valid(leader) && !_pause:
		var targetPosition = leader.position + Vector2($CollisionShape2D.shape.radius, 0)
		state.linear_velocity = (targetPosition - position) * ( 555 * state.step)
	if leader is DebrisLeader:
		print(position)
	if abs(linear_velocity.x) > 1000:
		breakpoint


################################################################################
#	Public Methods
################################################################################


func connectTo(p : PhysicsBody2D) -> void:
	if p == follower:
		return
	p.collision_layer = 0x4
	p.leader = self
	p.group = group
	var oldNode = follower
	follower = p
	if oldNode != null:
		p.connectTo(oldNode)


func clearChain() -> void:
	leader = null
	if follower != null:
		yield(follower.clearChain(), "completed")
		follower = null
	queue_free()
	yield(self, "tree_exited")


func hiddenChain() -> void:
	if follower != null:
		yield(follower.hiddenChain(), "completed")
	else:
		yield(self, "outOfSight")


func teleportChain(pos : Vector2) -> void:
	print("Preparing teleport for ", self)
	_pause = true
	if pos.x < 1290:
		breakpoint
	if follower != null:
		follower.teleportChain(pos + Vector2(48, 0))
		yield(follower, "teleportReady")
	_jumpTo = pos
	if leader != null:
		yield(leader, "teleportDone")
		emit_signal("teleportDone")
	print("Teleport Done ", self)
	_pause = false


func teleport(offset : Vector2) -> void:
	_jumpTo = position + offset
	yield(self, "teleportDone")


################################################################################
#	Private Methods
################################################################################


func _setIsFirst(b : bool) -> void:
	isFirst = b
	_setValue(value)


func _setValue(v : int) -> void:
	value = v
	if value != INF:
		$Label.text = ("%" + ("d" if isFirst else "+d"))  % value
	else:
		$Label.text = ""


################################################################################
#	Signal Handling
################################################################################


func _on_VisibilityNotifier2D_screen_entered() -> void:
	emit_signal("inSight")


func _on_VisibilityNotifier2D_screen_exited() -> void:
	if leader == null:
		if follower != null:
			follower.clearChain()
		queue_free()
	else:
		_hasLeftScreen = true
		emit_signal("outOfSight")


func _on_DebrisPiece_body_entered(body: PhysicsBody2D) -> void:
	if body.collision_layer == 0x8:
		var contactVector = body.position - position
		if contactVector.x < 0 && leader != null:
			leader.connectTo(body)
		else:
			connectTo(body)
