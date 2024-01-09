@tool
extends Node

const DEFAULT_PORT := 7210

@onready var build = $"../Build"
@onready var server = $WebSocketServer
var pck_file: FileAccess
var pck_checksum: String


func _ready() -> void:
	server.connect("client_connected", _on_peer_connected)
	server.connect("client_disconnected", _on_peer_disconnected)
	server.connect("message_received", _on_peer_message_received)


func deploy_to_web_player(url: String, port: int = DEFAULT_PORT, tls: bool = false) -> void:
	if !_is_pck_valid():
		stop_server()
		return
	server.listen(port, tls)
	print("[GDGotm] Opening web player...")
	OS.shell_open(url + "?debugHost=localhost:" + str(port) + "&tls=" + str(tls))


func stop_server() -> void:
	pck_file = null
	server.stop()


func get_project_location() -> String:
	return build.get_project_location()


func _on_peer_connected(id: int) -> void:
	pass
#	print("Remote client connected: ", id)


func _on_peer_disconnected(id: int) -> void:
	pass
#	var peer: WebSocketPeer = server.peers[id]
#	print("Remote client disconnected: %d. Code: %d, Reason: %s" % [id, peer.get_close_code(), peer.get_close_reason()])


func _on_peer_message_received(id: int, message: String) -> void:
	if message.contains("get_chunk_number "):
		message = message.trim_prefix("get_chunk_number ")
		if !message.is_valid_int():
			server.send_text(id, "Error: Bad Chunk Number")
			return
		var chunk_number := message.to_int()
		if chunk_number < 0 || chunk_number > _get_pck_chunk_count() - 1:
			server.send_text(id, "Error: Bad Chunk Number")
			return
		server.send_data(id, _get_pck_chunk(chunk_number))
		return

	if message.contains("get_chunk_size "):
		message = message.trim_prefix("get_chunk_size ")
		if !message.is_valid_int():
			server.send_text(id, "Error: Bad Chunk Number")
			return
		var chunk_number := message.to_int()
		if chunk_number < 0 || chunk_number > _get_pck_chunk_count() - 1:
			server.send_text(id, "Error: Bad Chunk Number")
			return
		server.send_text(id, str(_get_pck_chunk(chunk_number).size()))
		return

	match message:
		"get_chunk_count":
			server.send_text(id, str(_get_pck_chunk_count()))
		"get_size":
			server.send_text(id, str(pck_file.get_length()))
		"get_md5":
			server.send_text(id, _get_md5_checksum())
		_:
			server.send_text(id, "Error: Bad Command")


func _is_pck_valid() -> bool:
	if pck_file != null && pck_file.is_open():
		pck_file.close()

	var project_location := get_project_location()
	if !FileAccess.file_exists(project_location):
		push_error("[GDGotm] Cannot deploy. PCK file does not exist at: " + project_location)
		_alert_error()
		return false

	pck_file = FileAccess.open(project_location, FileAccess.READ)
	if pck_file == null:
		push_error("[GDGotm FileAccess Error " + str(FileAccess.get_open_error()) + "] Cannot read file at: "+ project_location)
		_alert_error()
		return false

	if pck_file.get_length() <= 0:
		push_error("[GDGotm] .pck file export is empty at: "+ project_location)
		_alert_error()
		return false

	return true


func _get_pck_chunk(chunk_number: int) -> PackedByteArray:
	pck_file.seek(chunk_number * server.PACKET_SIZE) # place cursor at the beginning of the chunk
	return pck_file.get_buffer(server.PACKET_SIZE)


func _get_md5_checksum() -> String:
	var project_location := get_project_location()
	return FileAccess.get_md5(project_location)


func _get_pck_chunk_count() -> int:
	var packet_size: float = server.PACKET_SIZE
	return int(ceil(pck_file.get_length() / packet_size))


func _alert_error() -> void:
	OS.alert("GDGotm Plugin Deploy Error.\nPlease look at the errors inside Godot's debugger.", "GDGotm Plugin Deploy Error")
