@tool
extends Node

signal client_connected(peer_id: int)
signal client_disconnected(peer_id: int)
signal message_received(peer_id: int, message: String)

const PACKET_SIZE := 1024 * 1024 # 1 MiB chunks

var tcp_server := TCPServer.new()
var pending_peers: Array[PendingPeer]
var peers: Dictionary # dict of peer_ids: WebSocketPeer
var handshake_timeout := 3000
var is_tls := true
var tls_cert: X509Certificate
var tls_key: CryptoKey


func _process(_delta: float) -> void:
	_poll()


func listen(port: int, tls: bool) -> int:
	is_tls = tls
	if tcp_server.is_listening():
		return OK
	return tcp_server.listen(port)


func stop() -> void:
	tcp_server.stop()
	pending_peers.clear()
	peers.clear()


func send_data(peer_id: int, data: PackedByteArray) -> int:
	if !peers.has(peer_id):
		return FAILED
	var peer_socket: WebSocketPeer = peers[peer_id]
	peer_socket.outbound_buffer_size = PACKET_SIZE
	return peer_socket.send(data)


func send_text(peer_id: int, message: String) -> int:
	if !peers.has(peer_id):
		return FAILED
	var peer_socket: WebSocketPeer = peers[peer_id]
	return peer_socket.send_text(message)


func get_message(peer_id: int) -> String:
	if !peers.has(peer_id):
		return ""
	var peer_socket: WebSocketPeer = peers[peer_id]
	if !peer_socket.get_available_packet_count():
		return ""
	var packet = peer_socket.get_packet()
	if !peer_socket.was_string_packet():
		return ""
	return packet.get_string_from_utf8()


func _create_peer() -> WebSocketPeer:
	var new_peer := WebSocketPeer.new()
	new_peer.outbound_buffer_size = PACKET_SIZE
	return WebSocketPeer.new()


func _poll() -> void:
	if !tcp_server.is_listening():
		return

	# add new connections
	while tcp_server.is_connection_available():
		var connection := tcp_server.take_connection()
		if connection == null:
			return
		pending_peers.append(PendingPeer.new(connection))

	# connect peers and check for timeouts
	var to_remove := []
	for peer in pending_peers:
		if _is_connection_pending(peer):
			if peer.connect_time + handshake_timeout < Time.get_ticks_msec():
				to_remove.append(peer) # timed out
			continue # still connecting
		else:
			to_remove.append(peer) # is not pending
	for peer in to_remove:
		pending_peers.erase(peer)
	to_remove.clear()

	# update peers and get messages
	for id in peers:
		var peer: WebSocketPeer = peers[id]
		peer.poll()
		if peer.get_ready_state() != WebSocketPeer.STATE_OPEN:
			client_disconnected.emit(id)
			to_remove.append(id)
			continue
		while peer.get_available_packet_count():
			message_received.emit(id, get_message(id))
	for peer in to_remove:
		peers.erase(peer)


func _is_connection_pending(peer: PendingPeer) -> bool:
	if peer.ws != null:
		peer.ws.poll() # poll websocket client if doing handshake
		var state = peer.ws.get_ready_state()
		if state == WebSocketPeer.STATE_CONNECTING:
			return true # still connecting
		if state == WebSocketPeer.STATE_OPEN:
			var id = randi_range(2, 1 << 30)
			peers[id] = peer.ws
			client_connected.emit(id)
			return false # peer connected
		return false # stopped trying to connect

	if peer.tcp.get_status() != StreamPeerTCP.STATUS_CONNECTED:
		return false # tcp connection disconnected

	# standard (not secure)
	if !is_tls:
		peer.ws = _create_peer()
		if peer.ws.accept_stream(peer.tcp) != OK:
			return false # failed to accept stream
		return true # is now connecting

	# tsl (secure)
	if peer.connection == peer.tcp:
		var tls = StreamPeerTLS.new()
		if !tls_key:
			var crypto = Crypto.new()
			tls_key = crypto.generate_rsa(4096)
			tls_cert = crypto.generate_self_signed_certificate(tls_key, "CN=gdgotmplugin,O=Gotm,C=SE")
		var tls_options := TLSOptions.server(tls_key,tls_cert)
		if tls.accept_stream(peer.tcp, tls_options) != OK:
			return false # failed to accept stream
		peer.connection = tls
	peer.connection.poll()
	var status = peer.connection.get_status()
	if status == StreamPeerTLS.STATUS_CONNECTED:
		peer.ws = _create_peer()
		if peer.ws.accept_stream(peer.connection) != OK:
			return false # failed to accept stream
		return true # is now connecting
	if status != StreamPeerTLS.STATUS_HANDSHAKING:
		return false # failed to handshake
	return true # still pending


class PendingPeer:
	var connect_time: int
	var connection: StreamPeer
	var tcp: StreamPeerTCP
	var ws: WebSocketPeer
	
	func _init(pending_peer_tcp: StreamPeerTCP) -> void:
		tcp = pending_peer_tcp
		connection = pending_peer_tcp
		connect_time = Time.get_ticks_msec()
