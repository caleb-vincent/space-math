extends RigidBody2D

class_name DebrisPiece

signal outOfSight
signal teleportDone
signal teleportReady
signal offScreen
signal impact
signal canceled
signal updated

const _spriteTypes = 2

export var moveSpeed  = Vector2(-200, 10)

var value : int = INF setget _setValue
var symbol : String = "" setget _setSymbol
var isFirst : bool = true setget _setIsFirst
var leader : PhysicsBody2D = null
var follower : PhysicsBody2D = null
var group : String = ""

var _jumpTo = Vector2.ZERO
var _pause = false
var _total = INF

onready var _rng : RandomNumberGenerator = get_parent()._rng

################################################################################
#	Inherited Methods
################################################################################


func  _integrate_forces (state : Physics2DDirectBodyState ):
	if _jumpTo != Vector2.ZERO:
		var xform = state.get_transform()
		xform.origin = _jumpTo
		state.set_transform(xform)
		state.linear_velocity = Vector2.ZERO
		_jumpTo = Vector2.ZERO
		emit_signal("teleportReady")
	elif leader != null && is_instance_valid(leader) && !_pause && !leader._pause:
		var targetPosition = leader.position + Vector2($CollisionShape2D.shape.radius, 0)
		state.linear_velocity = (targetPosition - position) * ( 555 * state.step)
	elif leader == null && follower != null && !_pause:
		state.linear_velocity = moveSpeed


func _process(delta: float) -> void:
	if leader == null && follower != null:
		var total = 0
		var node = self
		while node != null && is_instance_valid(node):
			if node.symbol != "":
				total *= -1
			else:
				total += node.value
			node = node.follower
		$DebugLabel.visible = OS.is_debug_build()
		$DebugLabel.text = str(total)
		if total == 0:
			clearChain()
			emit_signal("canceled", _total)
		elif total != _total:
			emit_signal("updated", total, _total)
			_total = total


func _ready() -> void:
	$Sprite.animation = "default" + str(_rng.randi_range(0, _spriteTypes - 1))

################################################################################
#	Public Methods
################################################################################


func clearChain() -> void:
	leader = null
	if follower != null:
		yield(follower.clearChain(), "completed")
		follower = null
	queue_free()
	yield(self, "tree_exited")


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


func hiddenChain() -> void:
	if follower != null:
		yield(follower.hiddenChain(), "completed")
	elif leader != null:
		yield(self, "outOfSight")

	if leader == null:
		emit_signal("offScreen", self)


func teleportChain(pos : Vector2) -> void:
	_pause = true
	_jumpTo = pos
	yield(self, "teleportReady")
	if follower != null:
		follower.teleportChain(pos + Vector2(48, 0))
	_pause = false


################################################################################
#	Private Methods
################################################################################


func _setIsFirst(b : bool) -> void:
	isFirst = b
	_setValue(value)


func _setSymbol(s : String) -> void:
	symbol = s
	$Label.text = symbol
	value = INF


func _setValue(v : int) -> void:
	value = v
	if value != INF:
		$Label.text = ("%" + ("d" if isFirst else "+d"))  % value
	else:
		$Label.text = ""


################################################################################
#	Signal Handling
################################################################################


func _on_VisibilityNotifier2D_screen_exited() -> void:
	if leader == null && follower == null:
		queue_free()
	elif leader == null:
		hiddenChain()
	else:
		emit_signal("outOfSight")


func _on_DebrisPiece_body_entered(body: PhysicsBody2D) -> void:
	if leader == null && body is StaticBody2D:
		emit_signal("impact", self)
	elif body.collision_layer == 0x8:
		var contactVector = body.position - position
		if contactVector.x < 0 && leader != null:
			leader.connectTo(body)
		else:
			connectTo(body)

