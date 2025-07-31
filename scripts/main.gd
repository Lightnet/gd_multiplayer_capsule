extends Node3D

@onready var gui_lobby: Control = $CanvasLayer/gui_lobby
@onready var gui_network: Control = $CanvasLayer/gui_network
@onready var label_network_type: Label = $CanvasLayer/Label_NetworkType
@onready var line_edit_player: LineEdit = $CanvasLayer/gui_network/LineEdit_Player
@onready var label_player: Label = $CanvasLayer/Label_Player
@onready var gui_game: Control = $CanvasLayer/gui_game

@onready var spawn_point: Node3D = $SpawnPoint
@onready var start: Button = $CanvasLayer/gui_lobby/Start


var peer = ENetMultiplayerPeer.new()
@export var player_scene:PackedScene
var network_type:String = "None"

# This will contain player info for every player,
# with the keys being each player's unique IDs.
var players = {}

# This is the local player info. This should be modified locally
# before the connection is made. It will be passed to every other peer.
# For example, the value of "name" can be set to something the player
# entered in a UI scene.
var player_info = {"name": "Name"}

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	line_edit_player.text = Global.generate_random_name()

func _on_host_pressed() -> void:
	player_info["name"] = line_edit_player.text
	label_player.text = line_edit_player.text
	peer.create_server(1027)
	multiplayer.multiplayer_peer = peer
	#multiplayer.peer_connected.connect(add_player)
	#add_player()
	gui_network.hide()
	gui_lobby.show()
	network_type = "SERVER"
	label_network_type.text = network_type

func _on_join_pressed() -> void:
	player_info["name"] = line_edit_player.text
	label_player.text = line_edit_player.text
	peer.create_client("127.0.0.1",1027)
	multiplayer.multiplayer_peer = peer
	gui_network.hide()
	gui_lobby.show()
	start.disabled = true #disable button for client
	
	network_type = "CLIENT"
	label_network_type.text = network_type
	#pass

func _start_game():
	if multiplayer.is_server():
		print("init game")
		hide_gui_lobby.rpc()
		add_player()
		
		for peer in multiplayer.get_peers():
			add_player(peer)
			pass

@rpc("call_local")
func hide_gui_lobby():
	gui_lobby.hide()
	gui_game.show()

@rpc("any_peer", "reliable")
func _register_player(new_player_info):
	var new_player_id = multiplayer.get_remote_sender_id()
	players[new_player_id] = new_player_info
	#player_connected.emit(new_player_id, new_player_info)

# When a peer connects, send them my player info.
# This allows transfer of all desired data for each player, not only the unique ID.
func _on_player_connected(id):
	_register_player.rpc_id(id, player_info)
	
func _on_player_disconnected(id):
	players.erase(id)
	del_player(id)
	#player_disconnected.emit(id)

func add_player(pid:int = 1)->void:
	var player = player_scene.instantiate()
	player.name = str(pid)
	call_deferred("add_child", player)
	await get_tree().create_timer(0.1).timeout #need to wait to sync else error !get_tree()
	set_player_position.rpc(pid, spawn_point.global_position)
	#pass

@rpc("call_local")
func set_player_position(pid:int, pos:Vector3):
	var player = get_node(str(pid))
	player.set_global_position(pos)
	pass

func exit_game(id):
	multiplayer.peer_disconnected.connect(del_player)
	del_player(id)
	
func del_player(id):
	rpc("_del_player",id)
	
@rpc("any_peer","call_local")
func _del_player(id):
	var player  = get_node_or_null(str(id))
	print("del player", player)
	if player:
		player.queue_free()
	#pass

func _on_start_pressed() -> void:
	_start_game()
	
	pass

# test close for del player event
func _on_quit_pressed() -> void:
	multiplayer.multiplayer_peer.close()
	get_tree().quit()
	pass
