class_name ServerMain extends Node

## The Root Node for the Dedicated Server.
## Responsible for Database connections, Network Listening, and ticking the
## Authoritative ECS Simulation.

var port: int
var is_offline: bool

var rust_core: RustCore

func _init(_port: int, _offline: bool = false) -> void:
	port = _port
	is_offline = _offline
	name = "ServerMain"

func _ready() -> void:
	# Create GECS World
	var world := World.new()
	world.name = "ServerWorld"
	GameOrchestrator.server_world = world

	# Builds the entire deterministic architecture instantly
	ServerPipeline.build(world)

	if not is_offline:
		print("[SERVER] Starting Server Initialization...")

		# Start server
		rust_core = RustCore.new()
		add_child(rust_core)
		UIUtils.safe_connect(rust_core.on_network_events, _on_rust_packets, "ServerMain on_network_events")
		rust_core.start_backend(port)

		print("[SERVER] Listening for clients on port %d" % port)
	else:
		print("[SERVER] Offline mode enabled. Skipping network initialization.")

	# Spawn the Training Dummy for the Demo
	UIUtils.safe_connect(get_tree().create_timer(1.0).timeout, _spawn_test_dummy, "ServerMain _spawn_test_dummy")

func _spawn_test_dummy() -> void:
	var dummy := Entity.new()
	var net_id := -1 # Negative IDs usually denote NPCs/Monsters

	dummy.add_component(C_NetworkId.new(net_id))
	dummy.add_component(C_Transform.new(Transform3D(Basis(), Vector3(0, 1, -5))))
	dummy.add_component(C_Health.new(100, 100))
	dummy.add_component(C_MonsterTag.new())
	dummy.add_component(C_Username.new("Training Dummy"))

	# Add a physical body so it can be hit by raycasts
	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	col.shape = shape
	body.add_child(col)

	# Set to Layer 13 (Enemy Hurtbox)
	body.collision_layer = 0
	body.set_collision_layer_value(13, true)
	dummy.add_child(body)

	GameOrchestrator.server_world.add_entity(dummy)

	# Force broadcast it so clients see it immediately
	var writer := StreamPeerBuffer.new()
	writer.put_64(net_id)
	writer.put_string("PLAYER") # Send as player so the client uses the Capsule Mesh
	writer.put_string("Training Dummy")
	writer.put_float(0.0)
	writer.put_float(1.0)
	writer.put_float(-5.0)

	var all_clients := PackedInt64Array([0])
	NetworkRouter.server.queue_broadcast(all_clients, OpCode.ID.ENTITY_SPAWN, writer.data_array)
	print("[SERVER] Spawned Test Dummy.")

func _on_rust_packets(buckets: Dictionary) -> void:
	NetworkRouter.server.incoming_buckets = buckets

## TICKING THE SERVER
## TODO: Implement proper ticking
func _physics_process(delta: float) -> void:
	# DRAIN THE FLUME CHANNEL
	# This pulls thousands of network events processed by Tokio
	# and safely fires the connected signals on the main thread.
	if rust_core:
		rust_core.poll_network()

	var world := GameOrchestrator.server_world

	if not world:
		return

	# Strict, Explicit Server Pipeline (No looping overhead, profilable)
	world.process(delta, SystemGroups.PRE_PROCESS)
	world.process(delta, SystemGroups.PHYSICS)
	world.process(delta, SystemGroups.VALIDATION)
	world.process(delta, SystemGroups.EXECUTION)
	world.process(delta, SystemGroups.COMBAT)
	world.process(delta, SystemGroups.AI)

	# Late Phase (Respawning)
	world.process(delta, SystemGroups.SPAWNING)

	# Post Process (Network Broadcasting, VFX triggering)
	world.process(delta, SystemGroups.POST_PROCESS)

	# Safely flush to the Rust network thread
	NetworkRouter.server.flush_to_rust(rust_core)
	NetworkRouter.server.clear_inbox()
