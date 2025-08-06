extends Node3D

@onready var gui_lobby: Control = $CanvasLayer/gui_lobby
@onready var gui_network: Control = $CanvasLayer/gui_network
@onready var label_network_type: Label = $CanvasLayer/VBoxContainer/HBoxContainer/Label_NetworkType
@onready var line_edit_player: LineEdit = $CanvasLayer/gui_network/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/LineEdit_Player
@onready var label_player: Label = $CanvasLayer/VBoxContainer/HBoxContainer2/Label_Player
@onready var gui_game: Control = $CanvasLayer/gui_game
@onready var spawn_point: Node3D = $SpawnPoint
@onready var start: Button = $CanvasLayer/gui_lobby/Start
@onready var label_counts: Label = $CanvasLayer/VBoxContainer/HBoxContainer3/Label_Counts

@onready var line_edit_address: LineEdit = $CanvasLayer/gui_network/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/LineEdit_Address
@onready var line_edit_port: LineEdit = $CanvasLayer/gui_network/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer2/LineEdit_Port

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
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	multiplayer.connection_failed.connect(_on_connected_fail)
	line_edit_player.text = Global.generate_random_name()

# note this has delay or say try to connect to server
func _on_connected_fail():
	print("connect fail")
	multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null
	gui_network.show()
	gui_lobby.hide()
	#pass

func _on_host_pressed() -> void:
	player_info["name"] = line_edit_player.text
	label_player.text = line_edit_player.text
	var port:int = line_edit_port.text.to_int()
	if port:
		peer.create_server(port)
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
	var port:int = line_edit_port.text.to_int()
	var address:String = line_edit_address.text
		
	peer.create_client(address, port)
	#multiplayer.multiplayer_peer = peer
	multiplayer.set_multiplayer_peer(peer)
	
	gui_network.hide()
	gui_lobby.show()
	start.disabled = true #disable button for client
	
	network_type = "CLIENT"
	label_network_type.text = network_type
	#pass

func _start_game()->void:
	if multiplayer.is_server():
		print("init game")
		hide_gui_lobby.rpc()
		add_player()
		
		for peer_id in multiplayer.get_peers():
			add_player(peer_id)
			pass

@rpc("call_local")
func hide_gui_lobby()->void:
	gui_lobby.hide()
	gui_game.show()

@rpc("any_peer", "reliable")
func _register_player(new_player_info)->void:
	var new_player_id = multiplayer.get_remote_sender_id()
	players[new_player_id] = new_player_info
	#player_connected.emit(new_player_id, new_player_info)

# When a peer connects, send them my player info.
# This allows transfer of all desired data for each player, not only the unique ID.
func _on_player_connected(id)->void:
	_register_player.rpc_id(id, player_info)
	label_counts.text = str(len(multiplayer.get_peers()))
	
func _on_player_disconnected(id)->void:
	players.erase(id)
	del_player(id)
	label_counts.text = str(len(multiplayer.get_peers()))
	#player_disconnected.emit(id)

func _on_server_disconnected()->void:
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
	gui_game.hide()
	gui_network.show()
	#pass

func add_player(pid:int = 1)->void:
	var player = player_scene.instantiate()
	player.name = str(pid)
	call_deferred("add_child", player)
	await get_tree().create_timer(0.1).timeout #need to wait to sync else error !get_tree()
	set_player_position.rpc(pid, spawn_point.global_position)
	#pass

@rpc("call_local")
func set_player_position(pid:int, pos:Vector3)->void:
	var player = get_node(str(pid))
	player.set_global_position(pos)
	pass

func exit_game(id)->void:
	multiplayer.peer_disconnected.connect(del_player)
	del_player(id)
	
# delete player from event disconnect
func del_player(id)->void:
	rpc("_del_player",id)

# sync to remove player id
@rpc("any_peer","call_local")
func _del_player(id) -> void:
	var player  = get_node_or_null(str(id))
	print("del player", player)
	if player:
		player.queue_free()
	#pass

func _on_start_pressed() -> void:
	_start_game()
	#pass

# test close for del player event
func _on_quit_pressed() -> void:
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
	get_tree().quit()
	#pass
