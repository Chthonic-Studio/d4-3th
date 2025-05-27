## NPC AI: Start in idle, wait 5–10s, then begin action cycle.
## HOW-AND-WHERE-TO-USE:
## - Attach to each CharacterBody2D that represents an NPC.
## - All timers/state local to NPC.
## - No global signals/ticks/time required for behavior cycle.

extends CharacterBody2D # ¡Cambiado de Node2D a CharacterBody2D!

# Enumeraciones para los estados del NPC
enum NPCState { IDLE, MOVING }
enum MovementType { RANDOM_WAYPOINT, PATROL_SEQUENCE } # Nuevo: para elegir el tipo de movimiento

@export var speed: float = 45.0
@export var min_idle_time: float = 2.0
@export var max_idle_time: float = 10.0
@export var movement_type: MovementType = MovementType.RANDOM_WAYPOINT # Define el tipo de movimiento

@onready var idle_timer: Timer = $IdleTimer
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D # Asume que tienes un Sprite2D llamado "Sprite2D"

var current_waypoint_index: int = 0 # Nuevo: para controlar el waypoint actual en una secuencia
@export var waypoints_container: Node2D
var state: NPCState = NPCState.IDLE
var target_position: Vector2
var waypoints: Array # Almacenará los nodos Waypoint

func _ready():
	randomize()
	if waypoints_container == null:
		if get_tree().get_current_scene().has_node("Waypoints"):
			waypoints_container = get_tree().get_current_scene().get_node("Waypoints")
		else:
			printerr("ERROR: NPC '%s' no pudo encontrar el nodo 'Waypoints'. Asegúrate de asignarlo en el editor o de que la ruta sea correcta." % name)
			set_physics_process(false)
			return

	for child in waypoints_container.get_children():
		if child is Marker2D: # Asumiendo que tus waypoints son Marker2D
			waypoints.append(child)

	if waypoints.is_empty():
		printerr("ERROR: No se encontraron waypoints en el contenedor 'Waypoints'.")
		set_physics_process(false)
		return

	# Iniciar el primer temporizador para que empiecen a moverse
	_on_IdleTimer_timeout() # Iniciar el proceso de selección de acción
	print("DEBUG: NPC '%s' cargado con MovementType: %s (Raw value: %d)" % [name, movement_type, movement_type])

func _physics_process(delta: float):
	# SOLO PARA DEPURACIÓN
	# print("NPC '%s' _physics_process. State: %s" % [name, state])

	if state == NPCState.MOVING:
		var direction = (target_position - global_position).normalized()
		velocity = direction * speed
		sprite.play("moving") 
		move_and_slide()
		
		# Voltear sprite según la dirección de movimiento
		# Solo volteamos si hay movimiento horizontal significativo
		if abs(direction.x) > 0.1: # Un pequeño umbral para evitar jitters cuando la dirección es casi vertical
			sprite.flip_h = direction.x < 0

		# Ajusta el umbral de distancia aquí también, si no lo hiciste antes
		if global_position.distance_to(target_position) < 10: # Aumentado a 10
			print("NPC '%s' arrived at waypoint: %s (State: %s). Actual Pos: (%s), Dest Pos: (%s)" % [name, get_current_waypoint_name(), state, global_position, target_position])
			finish_current_action()
	else: # NPCState.IDLE
		# Asegúrate de que el nombre de la animación "idle" sea EXACTO en tu AnimatedSprite2D
		if sprite.animation != "idle":
			sprite.play("idle")

		velocity = Vector2.ZERO

	if velocity.x != 0:
		sprite.flip_h = velocity.x < 0

func _on_IdleTimer_timeout():
	select_next_action()

func select_next_action():
	print("NPC '%s' idle timer timed out. Selecting next action." % name)
	state = NPCState.MOVING # Asume que la siguiente acción siempre es moverse
	print("NPC '%s' selecting action: move" % name)
	
	if movement_type == MovementType.RANDOM_WAYPOINT:
		var next_waypoint = waypoints[randi() % waypoints.size()]
		target_position = next_waypoint.global_position
		print("NPC '%s' starting move from %s to %s. Starting Pos: (%s). **DEBUG** Pos inicial ajustada para movimiento: (%s)" % [name, get_current_waypoint_name(), next_waypoint.name, global_position, global_position])
		start_move(target_position, next_waypoint.name)
	elif movement_type == MovementType.PATROL_SEQUENCE:
		# Mover al siguiente waypoint en secuencia
		current_waypoint_index = (current_waypoint_index + 1) % waypoints.size()
		var next_waypoint = waypoints[current_waypoint_index]
		target_position = next_waypoint.global_position
		print("NPC '%s' starting patrol move to %s. Starting Pos: (%s). **DEBUG** Pos inicial ajustada para movimiento: (%s)" % [name, next_waypoint.name, global_position, global_position])
		start_move(target_position, next_waypoint.name)


func start_move(destination: Vector2, destination_name: String):
	target_position = destination
	state = NPCState.MOVING
	print("NPC '%s' moving to waypoint: %s (Current state: %s). Starting Pos: (%s)" % [name, destination_name, state, global_position])

func finish_current_action():
	print("NPC '%s' finished general move." % name)
	if movement_type == MovementType.RANDOM_WAYPOINT:
		# Si es aleatorio, entra en inactividad
		state = NPCState.IDLE
		velocity = Vector2.ZERO
		move_and_slide()
		var idle_time = randf_range(min_idle_time, max_idle_time)
		print("NPC '%s' finished current action. State: %s." % [name, state])
		print("NPC '%s' entering idle for %.1f seconds." % [name, idle_time])
		idle_timer.start(idle_time)
	elif movement_type == MovementType.PATROL_SEQUENCE:
		# Si es patrulla, selecciona el siguiente waypoint inmediatamente
		print("NPC '%s' finished current action. State: %s." % [name, state])
		_on_IdleTimer_timeout() # Pasa directamente al siguiente waypoint

func get_current_waypoint_name() -> String:
	# Esta función asume que tienes una forma de saber de qué waypoint vienes
	# o simplemente retorna la posición actual si no hay un waypoint previo claro.
	# Para fines de depuración, podríamos retornar una aproximación o un valor por defecto.
	# Por ahora, solo retornaremos un string fijo si no se ha establecido un waypoint de origen.
	if target_position == Vector2.ZERO: # O alguna otra condición para el inicio
		return "Starting Point"
	for wp in waypoints:
		if wp.global_position.distance_to(global_position) < 10: # Si estás cerca de un waypoint
			return wp.name
	return "Unknown Waypoint" # Si no estás cerca de un waypoint conocido
