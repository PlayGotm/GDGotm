class_name _GotmMultiplayer

static var _server_multiplayer_peer: WebRTCMultiplayerPeer
static var _dispose_server_listener



static func get_address() -> String:
	if !_check_project_key():
		return ""
	var instance := (await _GotmAuth.get_auth_async()).instance
	return _GotmUtility.get_address_from_instance(instance)


static func create_client(address: String) -> WebRTCMultiplayerPeer:
	if !_check_project_key():
		return
	var multiplayer := WebRTCMultiplayerPeer.new()
	multiplayer.create_client(_create_peer_id())
	var instance := (await _GotmAuth.get_auth_async()).instance
	var target := _GotmUtility.get_instance_from_address(address)
	var start_signal := format_signal(await _GotmStore.create("handshakeSignals", {"target": target, "type": "start"}))
	if !start_signal:
		return null
	
	var incoming_signal_stream := PromiseStream.new()
	var on_signals := func(signals_list: Dictionary) -> void:
		for sig in format_signals(signals_list):
			if sig.type == GotmHandshakeSignal.Type.SIGNAL:
				incoming_signal_stream.add(sig.payload)				
	var dispose_signal_listener := _GotmUtility.fetch_event_stream(_Gotm.api_listen_origin + "/handshakeSignals?query=byInitiator&initiator=" + instance + "&handshakeId=" + start_signal.handshake_id, on_signals)
	
	var dispatch := func():
		await _perform_handshake(multiplayer, true, start_signal, incoming_signal_stream)
		dispose_signal_listener.call()
	dispatch.call()
	return multiplayer


static func create_server() -> WebRTCMultiplayerPeer:
	if !_check_project_key():
		return
	if _server_multiplayer_peer:
		return _server_multiplayer_peer

	var multiplayer := WebRTCMultiplayerPeer.new()
	multiplayer.create_server()
	_server_multiplayer_peer = multiplayer
	
	var instance := (await _GotmAuth.get_auth_async()).instance
	var incoming_signal_streams = {}
	var on_signals := func(signals_list: Dictionary) -> void:
		for sig in format_signals(signals_list):
			var type = sig.type
			var handshake_id = sig.handshake_id
			var payload = sig.payload
			if type == GotmHandshakeSignal.Type.START:
				if handshake_id in incoming_signal_streams:
					continue
				var incoming_signal_stream := PromiseStream.new()
				incoming_signal_streams[handshake_id] = incoming_signal_stream
				var runner := func():
					await _perform_handshake(multiplayer, false, sig, incoming_signal_stream)
					await _GotmStore.delete("handshakeSignals/" + handshake_id)
					await _GotmUtility.get_tree().create_timer(10).timeout
					incoming_signal_streams.erase(handshake_id)
				runner.call()
			elif type == GotmHandshakeSignal.Type.SIGNAL:
				var incoming_signal_stream: PromiseStream = incoming_signal_streams.get(handshake_id)
				if incoming_signal_stream:
					incoming_signal_stream.add(payload)

	var dispose_signal_listener := _GotmUtility.fetch_event_stream(_Gotm.api_listen_origin + "/handshakeSignals?query=byTarget&target=" + instance, on_signals)
	return multiplayer


static func _perform_handshake(multiplayer: WebRTCMultiplayerPeer, is_initiator: bool, start_signal: GotmHandshakeSignal, incoming_signal_stream: PromiseStream) -> bool:
	var handshake := Handshake.new(multiplayer, is_initiator, JSON.parse_string(start_signal.payload))
	var poll_state := {"is_done": false}
	var poller := func():
		while !poll_state.is_done:
			handshake.poll()
			await _GotmUtility.get_tree().process_frame
	poller.call()
	var errors := await _promise_all([
		func(): return await push_signals(handshake, start_signal),
		func(): return await pull_signals(handshake, incoming_signal_stream),
	])
	poll_state.is_done = true
	for error in errors:
		if error:
			push_error(error)
	if !handshake.has_connected():
		handshake.destroy()
	return handshake.has_connected()

static var _LAST_PEER_ID := 2
static func _create_peer_id() -> int:
	var id := _LAST_PEER_ID
	_LAST_PEER_ID += 1
	return id


class Handshake:
	var _peer: WebRTCPeerConnection
	var _signals := []
	var _is_connected := false
	var _signal_promise: _GotmUtility.ResolvablePromise
	var _connection_promise: _GotmUtility.ResolvablePromise
	var _is_initiator := false
	var _has_handled_first_signal := false
	var _candidates_to_handle := []
	var _handled_signals := []
	var _num_used_signals := 0
	var _multiplayer: WebRTCMultiplayerPeer
	var _id := 0

	func _init(multiplayer: WebRTCMultiplayerPeer, is_initiator: bool, config: Dictionary) -> void:
		_connection_promise = _GotmUtility.ResolvablePromise.new()
		_is_initiator = !!is_initiator
		_peer = WebRTCPeerConnection.new()
		_multiplayer = multiplayer
		_reset_signal_promise()

		_id = 1 if is_initiator else _GotmMultiplayer._create_peer_id()

		var on_signal := func(sig: Dictionary) -> void:
			var signal_string := JSON.stringify(sig)
			_GotmMultiplayer._log_verbose(get_name() + " SIGNAL: " + JSON.stringify(sig))
	
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
			if connected_id != _id:
				return
			_GotmMultiplayer._log_verbose(get_name() + " CONNECT")
			_GotmMultiplayer._log_verbose(get_name() + " used signals: " + str(_num_used_signals))
			
			_is_connected = true
			_signal_promise.resolve(false)
			_connection_promise.resolve(true)
		)
		_peer.initialize(config)
		multiplayer.add_peer(_peer, _id)
		if is_initiator:
			_peer.create_offer()
			
	func destroy() -> void:
		_multiplayer.close()

	func _reset_signal_promise() -> void:
		_signal_promise = _GotmUtility.ResolvablePromise.new()
		_signal_promise.set_timeout(TIMEOUT, false)
	
	
	func wait_for_connection() -> bool: 
		return await _connection_promise.await_result()
	
	
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
			var candidate = sig.candidate
			_peer.add_ice_candidate(candidate.sdpMid, candidate.sdpMLineIndex, candidate.candidate)
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
			_GotmMultiplayer._log_verbose(get_name() + " handling signal: " + JSON.stringify(sig))
			for candidate in _candidates_to_handle:
				if is_connecting():
					_num_used_signals += 1
					_add_signal(candidate)
					_GotmMultiplayer._log_verbose(get_name() + " handling signal: " + JSON.stringify(candidate))
			_candidates_to_handle = []
		elif _has_handled_first_signal:
			_num_used_signals += 1
			_add_signal(sig)
			_GotmMultiplayer._log_verbose(get_name() + " handling signal: " + JSON.stringify(sig))
		else:
			_candidates_to_handle.push_back(sig)

	func poll():
		_peer.poll()
		_multiplayer.poll()

	func wait_for_signal():
		if !is_connecting():
			return false
		
		var result = await _signal_promise.await_result()
		_reset_signal_promise()
		return result

	func is_connecting() -> bool:
		return !has_connected()
		

static func push_signals(handshake: Handshake, start_signal: GotmHandshakeSignal) -> String:
	var num_pushed_signals = 0
	while handshake.is_connecting() && (await handshake.wait_for_signal()):
		_GotmMultiplayer._log_verbose(handshake.get_name() + " UPDATE " + JSON.stringify(handshake.get_signals()))
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
						"handshakeId": handshake_id,
						"target": target if handshake.is_initiator() else owner,
						"payload": sig,
						"type": "signal",
					}
				)
			)
		await _GotmMultiplayer._promise_all(runners)

	if !handshake.has_connected():
		return handshake.get_name() + " is out of signals."
	
	return ""

static func _promise_race(callables: Array):
	if !callables:
		return
	var race_promise := _GotmUtility.ResolvablePromise.new()
	for callable in callables:
		var waiter := func():
			race_promise.resolve(await callable.call())
		waiter.call()
	return await race_promise.await_result()

static func _promise_all(callables: Array) -> Array:
	var results := []
	if !callables:
		return results
		
	var state := {"num_resolved": 0}
	results.resize(callables.size())
	var all_promise := _GotmUtility.ResolvablePromise.new()
	for i in callables.size():
		var runner := func():
			results[i] = await callables[i].call()
			state.num_resolved += 1
			if state.num_resolved >= callables.size():
				all_promise.resolve()
		runner.call()
	await all_promise.await_result()
	return results


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
	var _queue := []
	var _promises := []
  

	func add(value = null) -> void:
		_queue.push_back(value)
		for promise in _promises:
			promise.resolve(true)


	func flush() -> Array:
		var queue := _queue
		_queue = []
		return queue

	# Resolves to false if the timeout expired before new data is available, else resolves to true.
	func wait(timeout = 0) -> bool:
		if _queue:
			return true

		var promise := _GotmUtility.ResolvablePromise.new()
		_promises.push_back(promise)
		
		if timeout > 0:
			promise.set_timeout(timeout, false)
		
		var result = await promise.await_result()
		_promises.erase(promise)
		return result


	
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
	if !ENABLE_VERBOSE_LOGS:
		return
	print(message)

const TIMEOUT = 10000


static func _check_project_key() -> bool:
	if !Gotm.project_key:
		push_error("[GotmMultiplayer] You need a project key to use this API. See docs.")
		return false
	return true
	
