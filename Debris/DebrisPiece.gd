extends RigidBody2D

class_name DebrisPiece

signal teleportDone
signal teleportReady
signal offScreen
signal impact
signal canceled
signal updated
signal newLeader
signal selected

const _particlesTime = 0.25
const _spriteTypes = 6
const _fireSpeed = 2000

onready var moveSpeed  = Vector2(-200 * _difficultySpeedFactor(), 10)

var isProjectile = false setget _setIsProjectile
var value : int = INF setget _setValue
var symbol : String = "" setget _setSymbol
var isFirst : bool = true setget _setIsFirst
var leader : PhysicsBody2D = null
var follower : PhysicsBody2D = null
var group : String = ""


enum _State {
	Invalid,
	Neutral,
	Balistic,
	Following,
	Leading,
	Tracking
}

var _state = _State.Invalid
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
	elif _state == _State.Following && is_instance_valid(leader) && !_pause && !leader._pause:
		var targetPosition = leader.position + Vector2($CollisionShape2D.shape.radius, 0)
		state.linear_velocity = (targetPosition - position) * ( 555 * state.step)
	elif _state == _State.Leading && !_pause:
		state.linear_velocity = moveSpeed
	elif _state == _State.Tracking:
		var targetPosition = leader.position + (leader.linear_velocity / 4)
		state.linear_velocity = (targetPosition - position).normalized() * ( _fireSpeed)


func _process(delta: float) -> void:
	if _state == _State.Leading:
		var total = 0
		var node = self
		while node != null && is_instance_valid(node):
			if node.symbol != "":
				total *= -1
			else:
				total += node.value
			node = node.follower
		#$DebugLabel.visible = OS.is_debug_build()
		$DebugLabel.text = str(total)
		if total == 0:
			clearChain(true)
			emit_signal("canceled", _total)
		elif total != _total:
			emit_signal("updated", total, _total)
			_total = total


func _ready() -> void:
	$Sprite.animation = "default" + str(_rng.randi_range(0, _spriteTypes - 1))
	$ProjectileParticles.emitting = false
	$ProjectileParticles.visible = false
	$RemovalTimer.wait_time = _particlesTime
	$DestructionParticles.lifetime = _particlesTime
	$BalancingParticles.lifetime = _particlesTime
	_setState(_State.Neutral)


################################################################################
#	Public Methods
################################################################################


func clearChain(success : bool) -> void:
	$Sprite.visible = false
	$ProjectileParticles.visible = false
	$Label.visible = false
	$DebugLabel.visible = false
	if success:
		$BalancingParticles.emitting = true
	else:
		$DestructionParticles.emitting = true
	if follower != null:
		follower.clearChain(success)
		follower = null
	$RemovalTimer.start()
	yield($RemovalTimer, "timeout")

	queue_free()
	yield(self, "tree_exited")


func connectTo(p : DebrisPiece) -> void:
	if p == follower:
		return
	if p._state == _State.Leading:
		p.emit_signal("newLeader", self, p)
	p._setState(_State.Following)
	p._setIsFirst(symbol != "")
	_setIsFirst(leader == null || leader.symbol != "")
	p.leader = self
	var oldNode = follower
	follower = p
	if oldNode != null:
		p.connectTo(oldNode)
	if _state == _State.Balistic || _state == _State.Tracking || leader == null :
		_setState(_State.Leading)


func hiddenChain() -> void:
	if follower != null:
		yield(follower.hiddenChain(), "completed")
		emit_signal("offScreen", self)
	else:
		yield(self, "offScreen")


func fire(dir : Vector2) -> void:
	if _state == _State.Neutral:
		_setState(_State.Balistic)
		linear_velocity = dir.normalized() *  _fireSpeed
	else:
		breakpoint


func track(node : DebrisPiece) -> void:
	if _state == _State.Neutral || _state == _State.Balistic:
		_setState(_State.Tracking)
		leader = node
	else:
		breakpoint


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


func _difficultySpeedFactor() -> float:
	if Options.selectedDifficulty == Options.Difficulty.EASY:
		return 0.75
	elif Options.selectedDifficulty == Options.Difficulty.HARD:
		return 1.25
	else:
		return 1.0


func _setIsFirst(b : bool) -> void:
	isFirst = b
	if symbol == "":
		_setValue(value)


func _setIsProjectile(b : bool) -> void:
	isProjectile = b
	$ProjectileParticles.visible = isProjectile
	$ProjectileParticles.emitting = isProjectile
	if isProjectile:
		$Sprite.animation = "projectile"


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


func _setState(state) -> void:
	if _state == state:
		return
	match state:
		_State.Balistic:
			$ProjectileParticles.color = Color.yellow
			collision_layer = DebrisData.CollisionLayer.PROJECTILE
			collision_mask = DebrisData.CollisionMask.PROJECTILE
		_State.Following:
			collision_layer = DebrisData.CollisionLayer.FOLLOWER
			collision_mask = DebrisData.CollisionMask.FOLLOWER
		_State.Leading:
			if _state == _State.Balistic || _state == _State.Tracking:
				linear_velocity = Vector2.ZERO
			collision_layer = DebrisData.CollisionLayer.LEADER
			collision_mask = DebrisData.CollisionMask.LEADER
		_State.Neutral:
			collision_layer = DebrisData.CollisionLayer.NEUTRAL
			collision_mask = DebrisData.CollisionMask.NEUTRAL
		_State.Tracking:
			$ProjectileParticles.color = Color.green
			collision_layer = DebrisData.CollisionLayer.PROJECTILE
			collision_mask = DebrisData.CollisionMask.PROJECTILE
	print(str(self) + " from " + str(_state) + " to " + str(state))
	_state = state

################################################################################
#	Signal Handling
################################################################################


func _on_VisibilityNotifier2D_screen_exited() -> void:
	if _state == _State.Balistic || _state == _State.Tracking:
		queue_free()
	elif _state == _State.Leading:
		hiddenChain()
	else:
		emit_signal("offScreen")


func _on_DebrisPiece_body_entered(body: PhysicsBody2D) -> void:
	if body is StaticBody2D:
		emit_signal("impact", self)
	elif (_state== _State.Leading || _state == _State.Following) && (body._state == _State.Balistic || body._state == _State.Tracking):
		body.linear_velocity = Vector2.ZERO
		body.group = group
		var contactVector = body.position - position
		if contactVector.x < 0:
			if leader != null:
				leader.connectTo(body)
			else:
				body.connectTo(self)
		else:
			connectTo(body)


func _on_RemovalTimer_timeout() -> void:
	pass


func _on_DebrisPiece_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event.is_action_released("game_click"):
		emit_signal("selected", self)
