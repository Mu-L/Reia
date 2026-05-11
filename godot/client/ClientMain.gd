class_name ClientMain extends Node

## The Root Node for the Client Presentation Layer.
## Responsible for connecting to the server, registering visual Observers,
## and ticking the Client-side prediction ECS.

var ip: String
var port: int
var is_offline: bool
var rust_core: RustCore

func _init(_ip: String, _port: int, _offline: bool = false) -> void:
	ip = _ip
	port = _port
	is_offline = _offline
	name = "ClientMain"

func _ready() -> void:
	# Create GECS World
	var world := World.new()
	world.name = "ClientWorld"
	GameOrchestrator.client_world = world

	# Builds prediction systems and visual observers instantly
	ClientPipeline.build(world)

	if not is_offline:
		print("[CLIENT] Starting Client Initialization...")

		# Start client
		rust_core = RustCore.new()
		add_child(rust_core)
		UIUtils.safe_connect(rust_core.on_network_events, _on_rust_packets, "ClientMain on_network_events")

		# Bind network lifecycle signals
		UIUtils.safe_connect(rust_core.on_client_connected, _on_network_connected, "ClientMain on_client_connected")
		UIUtils.safe_connect(rust_core.on_client_disconnected, _on_network_disconnected, "ClientMain on_client_disconnected")


		rust_core.start_client(ip, port)

		print("[CLIENT] Connecting to server at %s:%d..." % [ip, port])
	else:
		print("[CLIENT] Offline mode enabled. Skipping network initialization.")

		# In offline mode, immediately authenticate
		call_deferred("_send_auth_request")

func _on_network_connected() -> void:
	print("[CLIENT] Connection established! Requesting Authentication...")
	_send_auth_request()

func _on_network_disconnected(reason: String) -> void:
	print("[CLIENT] Disconnected from server: ", reason)

	# Return the user to the Main Menu and alert them
	SceneManager.transition_to_screen(Scenes.Menus.TITLE_SCREEN)
	UIModalManager.show_notification("Connection Lost", reason)

func _send_auth_request() -> void:
	var writer := StreamPeerBuffer.new()
	writer.put_string(UserPreferences.get_username())
	writer.put_string("dummy_token")

	# Target 0 sends it to the Server
	NetworkRouter.client.queue_packet(0, OpCode.ID.AUTH_REQUEST, writer.data_array)
	print("[CLIENT] Sent AuthRequest. Awaiting Server approval...")

func _on_rust_packets(buckets: Dictionary) -> void:
	NetworkRouter.client.incoming_buckets = buckets

func _physics_process(delta: float) -> void:
	# Exact same loop as the server, but Client systems only do
	# prediction, interpolation, and VFX triggering.
	if rust_core: rust_core.poll_network()

	var world := GameOrchestrator.client_world

	if not world:
		return

	world.process(delta, SystemGroups.PRE_PROCESS)

	# Safely flush to the Rust network thread
	NetworkRouter.client.flush_to_rust(rust_core)
	NetworkRouter.client.clear_inbox()
