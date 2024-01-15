class_name GotmMultiplayer

var multiplayer_peer: WebRTCMultiplayerPeer
var address: String


static var _server_multiplayer_peer: WebRTCMultiplayerPeer
static var _dispose_server_listener


static func _get_instance_from_address(address: String) -> String:
	return ""

static func create_client(address: String) -> WebRTCMultiplayerPeer:
	var multiplayer := WebRTCMultiplayerPeer.new()
	var instance := (await _GotmAuth.get_auth_async()).instance
	var target := _get_instance_from_address(address)
	var start_signal := format_signal(await _GotmStore.create("handshakeSignals", {"target": target, "type": "start"}))
	
	var incoming_signal_stream := PromiseStream.new()
	var on_signals := func(signals_list: Dictionary) -> void:
		print("connect_to_host signals: ", signals_list)
		for sig in format_signals(signals_list):
			if sig.type == GotmHandshakeSignal.Type.SIGNAL:
				incoming_signal_stream.add(sig)				
	var dispose_signal_listener := _GotmUtility.fetch_event_stream(_Gotm.api_listen_origin + "/handshakeSignals?query=byInitiator&initiator=" + instance + "&handshakeId=" + start_signal.handshake_id, on_signals)
	await _perform_handshake(multiplayer, true, start_signal, incoming_signal_stream)
	dispose_signal_listener.call()

	return multiplayer


static func create_server() -> WebRTCMultiplayerPeer:
	if _server_multiplayer_peer && !_server_multiplayer_peer.get_connection_status() != MultiplayerPeer.ConnectionStatus.CONNECTION_DISCONNECTED:
		return _server_multiplayer_peer

	var multiplayer := WebRTCMultiplayerPeer.new()
	_server_multiplayer_peer = multiplayer
	
	var instance := (await _GotmAuth.get_auth_async()).instance
	var incoming_signal_streams = {}
	var on_signals := func(signals_list: Dictionary) -> void:
		print("create_host signals: ", signals_list)
		for sig in format_signals(signals_list):
			var type = sig.type
			var handshake_id = sig.handshake_id
			var payload = sig.payload
			if type == GotmHandshakeSignal.Type.START:
				if handshake_id in incoming_signal_streams:
					return
				var incoming_signal_stream := PromiseStream.new()
				incoming_signal_streams[handshake_id] = incoming_signal_stream
				var peer := await _perform_handshake(multiplayer, false, sig, incoming_signal_stream)
				incoming_signal_streams.erase(handshake_id)
			elif type == GotmHandshakeSignal.Type.SIGNAL:
				var incoming_signal_stream: PromiseStream = incoming_signal_streams.get(handshake_id)
				if incoming_signal_stream:
					incoming_signal_stream.add(payload)

	var dispose_signal_listener := _GotmUtility.fetch_event_stream(_Gotm.api_listen_origin + "/handshakeSignals?query=byTarget&target=" + instance, on_signals)
	
	var poll_liveness := func():
		while multiplayer.get_connection_status() != MultiplayerPeer.ConnectionStatus.CONNECTION_DISCONNECTED:
			await _GotmUtility.get_tree().process_frame
		if _server_multiplayer_peer == multiplayer:
			_server_multiplayer_peer = null
		dispose_signal_listener.call()

	poll_liveness.call()
	return multiplayer


static func _promise_all(callables: Array):
	var promises := []
	for callable in callables:
		promises.push_back(callable.call())
	
	var results := []
	for promise in promises:
		results.push_back(await promise)
		
	return results
	

static func _perform_handshake(multiplayer: WebRTCMultiplayerPeer, is_initiator: bool, start_signal: GotmHandshakeSignal, incoming_signal_stream: PromiseStream) -> String:
	var handshake := Handshake.new(multiplayer, is_initiator, JSON.parse_string(start_signal.payload))
	await _promise_all([
		func(): return await push_signals(handshake, start_signal),
		func(): return await pull_signals(handshake, incoming_signal_stream),
	])
	return ""


static var _LAST_PEER_ID := 2
static func _create_peer_id() -> int:
	var id := _LAST_PEER_ID
	_LAST_PEER_ID += 1
	return id


class Handshake:
	var _peer: WebRTCPeerConnection
	var _signals := []
	var _is_connected := false
	var _signal_promise: ResolvablePromise
	var _connection_promise: ResolvablePromise
	var _is_initiator := false
	var _has_handled_first_signal := false
	var _candidates_to_handle := []
	var _handled_signals := []
	var _num_used_signals := 0

	func _init(multiplayer: WebRTCMultiplayerPeer, is_initiator: bool, config: Dictionary) -> void:
		_connection_promise = ResolvablePromise.new()
		_is_initiator = !!is_initiator
		_peer = WebRTCPeerConnection.new()
		_reset_signal_promise()

		var id := 1 if is_initiator else GotmMultiplayer._create_peer_id()

		var on_signal := func(sig: Dictionary) -> void:
			var signal_string := JSON.stringify(sig)
			GotmMultiplayer._log_verbose(get_name() + " SIGNAL: " + JSON.stringify(sig))
	
			_signals.push_back(signal_string)
			_handled_signals.push_back(signal_string)
			_signal_promise.resolve(true)

		_peer.session_description_created.connect(func(type: String, sdp: String) -> void:
			_peer.set_local_description(type, sdp)
			on_signal.call({
				"type": type, 
				"sdp": sdp
			})
		)
		_peer.ice_candidate_created.connect(func(sdp_mid: String, sdp_m_line_index: int, candidate: String) -> void:
			on_signal.call({
				"type": "candidate", 
				"candidate": {
					"candidate": candidate,
					"sdpMLineIndex": sdp_m_line_index,
					"sdpMid": sdp_mid
				}
			})
		)
		multiplayer.peer_connected.connect(func(connected_id: int) -> void:
			if connected_id != id:
				return
			GotmMultiplayer._log_verbose(get_name() + " CONNECT")
			GotmMultiplayer._log_verbose(get_name() + " used signals: " + str(_num_used_signals))
			
			_is_connected = true
			_signal_promise.resolve(false)
			_connection_promise.resolve(true)
		)
		_peer.initialize(config)
		multiplayer.add_peer(_peer, id)
		if is_initiator:
			_peer.create_offer()
		

	func _reset_signal_promise() -> void:
		_signal_promise = ResolvablePromise.new()
		_signal_promise.set_timeout(TIMEOUT, false)
	
	
	func wait_for_connection() -> bool: 
		return await _connection_promise.get_awaitable()
	
	
	func get_error() -> String:
		return ""


	func has_connected() -> bool:
		return _is_connected
	
	func get_signals() -> Array:
		return _signals
	
	func get_name() -> String:
		return  "INITIATOR" if _is_initiator else "TARGET"
	
	func is_initiator() -> bool:
		return _is_initiator

	func _add_signal(sig: Dictionary) -> void:
		if sig.type == "answer" || sig.type == "offer":
			_peer.set_remote_description(sig.type, sig.sdp)
		elif sig.type == "candidate":
			_peer.add_ice_candidate(sig.sdpMid, sig.sdpMLineIndex, sig.candidate)
		else:
			push_error("Unknown signal type: " + JSON.stringify(sig))


	func add_signal(signal_string: String) -> void:
		if !is_connecting():
			return
		
		if _handled_signals.has(signal_string):
			return
		
		_handled_signals.push_back(signal_string)
		var sig := JSON.parse_string(signal_string) as Dictionary
		if sig.type == "answer" || sig.type == "offer":
			if _has_handled_first_signal:
				return
			
			_has_handled_first_signal = true
			_num_used_signals += 1
		
			_add_signal(sig)
			GotmMultiplayer._log_verbose(get_name() + " handling signal: " + JSON.stringify(sig))
			for candidate in _candidates_to_handle:
				if is_connecting():
					_num_used_signals += 1
					_add_signal(candidate)
					GotmMultiplayer._log_verbose(get_name() + " handling signal: " + candidate)
			_candidates_to_handle = []
		elif _has_handled_first_signal:
			_num_used_signals += 1
			_add_signal(sig)
			GotmMultiplayer._log_verbose(get_name() + " handling signal: " + JSON.stringify(sig))
		else:
			_candidates_to_handle.push_back(sig)


	func wait_for_signal():
		if is_connecting():
			return false
		
		var result = await _signal_promise
		_reset_signal_promise()
		return result

	func is_connecting() -> bool:
		return !has_connected()
		

static func push_signals(handshake: Handshake, start_signal: GotmHandshakeSignal) -> String:
	var num_pushed_signals = 0
	var update_error
	var catch_create_error := func(e):
		update_error = e

	while handshake.is_connecting() && !update_error && (await handshake.wait_for_signal()):
		GotmMultiplayer._log_verbose(handshake.get_name() + " UPDATE " + JSON.stringify(handshake.get_signals()))
		var handshake_signals := handshake.get_signals()
		var to_push = handshake_signals.slice(num_pushed_signals)
		num_pushed_signals = handshake_signals.size()
		var runners := []
		for sig in to_push:
			runners.push_back(func():
				var owner := start_signal.owner
				var handshake_id := start_signal.handshake_id
				var target := start_signal.target
				await _GotmStore.create(
					"handshakeSignals",
					{
						"handshake_id": handshake_id,
						"owner": owner if handshake.is_initiator() else target,
						"target": target if handshake.is_initiator() else owner,
						"payload": sig,
						"type": "signal",
					}
				)
			)
		await GotmMultiplayer._promise_all(runners)

	if !handshake.has_connected():
		if update_error:
			return update_error
		return handshake.get_name() + " is out of signals."
	
	return ""

static func _promise_race(promises: Array):
	if !promises:
		return
	var race_promise := ResolvablePromise.new()
	for promise in promises:
		var waiter := func():
			var result = promise
			race_promise.resolve(result)
		waiter.call()
	return await race_promise.get_awaitable()

static func pull_signals(handshake: Handshake, signal_stream: PromiseStream):
	while handshake.is_connecting() && (await _promise_race([
			func(): return await signal_stream.wait(TIMEOUT), 
			func(): return await handshake.wait_for_connection()
		])
	):
		for sig in signal_stream.flush():
			if handshake.is_connecting():
				handshake.add_signal(sig)

	if !handshake.has_connected():
		return handshake.get_name() + " didn't get a signal in time."
	return ""
	

class PromiseStream:
	var derp := 123




class ResolvablePromise:
	signal _resolved
	var _awaitable
	var _timeouts := []

	func _init() -> void:
		var runner := func():
			return await _resolved
		_awaitable = runner.call()

	func resolve(value) -> void:
		_timeouts = []
		_resolved.emit(value)
	
	func get_awaitable():
		return _awaitable

	func set_timeout(duration_milliseconds, value = null):
		var handle := {}
		_timeouts.push_back(handle)
		await _GotmUtility.get_tree().create_timer(float(duration_milliseconds) / 1000.0)
		if !(handle in _timeouts):
			return
		resolve(value)

	
class GotmHandshakeSignal:
	enum Type { START, SIGNAL }
	var id: String
	var type: Type
	var payload: String
	var handshake_id: String
	var target: String
	var owner: String




static func format_signals(data: Dictionary) -> Array:
	if data.is_empty():
		return []
		
	var signals := []
	for raw_signal in data.data:
		var sig := format_signal(raw_signal)
		if !sig:
			continue
		signals.push_back(sig)
	return signals

static func format_signal(data: Dictionary) -> GotmHandshakeSignal:
	if data.is_empty():
		return

	var sig := GotmHandshakeSignal.new()
	sig.id = data.path
	sig.payload = data.payload
	sig.handshake_id = data.handshakeId
	sig.target = data.target
	sig.owner = data.owner
	if data.type == "start":
		sig.type = GotmHandshakeSignal.Type.START
	elif data.type == "signal":
		sig.type = GotmHandshakeSignal.Type.SIGNAL
	else:
		return
	return sig


const ENABLE_VERBOSE_LOGS = false
static func _log_verbose(message: String) -> void:
	if ENABLE_VERBOSE_LOGS:
		return
	print(message)

const TIMEOUT = 10000
