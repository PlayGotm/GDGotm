extends Node

enum Test { FUNCTIONAL, UNIT }

var force_offline := false
var test: Test


func _enter_tree() -> void:
	get_tree().root.gui_embed_subwindows = true



func switch_test_scenes() -> void:
	match test:
		Test.FUNCTIONAL:
			get_tree().change_scene_to_file("res://tests/functional/score_functional_test.tscn")
		Test.UNIT:
			get_tree().change_scene_to_file("res://tests/unit/utility/unit.tscn")


func _on_gotm_init_pressed() -> void:
	Gotm.project_key = $UI/FunctionalMenu/ProjectKey.text
	Gotm.force_local_contents = force_offline
	Gotm.force_local_marks = force_offline
	Gotm.force_local_scores = force_offline
	if force_offline:
		print("Forcing offline...")
	switch_test_scenes()


func _on_offline_toggled(button_pressed: bool) -> void:
	force_offline = button_pressed


func _on_start_functional_pressed() -> void:
	test = Test.FUNCTIONAL
	$UI/Menu.hide()
	$UI/FunctionalMenu.show()


func _on_start_unit_pressed() -> void:
	test = Test.UNIT
	$UI/Menu.hide()
	$UI/FunctionalMenu.show()


class GotmHandshakeSignal:
	enum Type { START, SIGNAL }
	var id: String
	var type: Type
	var payload: String
	var handshake_id: String

class PromiseStream:
	var derp := 123

func perform_handshake(is_initiator: bool, sig: GotmHandshakeSignal, incoming_signal_stream: PromiseStream) -> String:
	return ""

func format_signals(data: Dictionary) -> Array:
	if data.is_empty():
		return []
		
	var signals := []
	for raw_signal in data.data:
		var sig := format_signal(raw_signal)
		if !sig:
			continue
		signals.push_back(sig)
	return signals

func format_signal(data: Dictionary) -> GotmHandshakeSignal:
	if data.is_empty():
		return

	var sig := GotmHandshakeSignal.new()
	sig.id = data.path
	sig.payload = data.payload
	sig.handshake_id = data.handshakeId
	if data.type == "start":
		sig.type = GotmHandshakeSignal.Type.START
	elif data.type == "signal":
		sig.type = GotmHandshakeSignal.Type.SIGNAL
	else:
		return
	return sig


static var _instance_id: String
static var _instance_promise
static var _instance_changed_callbacks := []
func get_instance() -> String:
	if _instance_id:
		return _instance_id
	if _instance_promise:
		return await _instance_promise
	
	var on_instance: Callable
	on_instance = func(message: Dictionary) -> void:
		if message:
			return
		var new_instance: String = (await _GotmStore.create("instances", {})).path
		var had_id := !!_instance_id
		_GotmUtility.fetch_event_stream(_Gotm.api_listen_origin + "/" + _instance_id, on_instance)
		if had_id:
			for callback in _instance_changed_callbacks:
				callback.call(_instance_id)
	_instance_promise = on_instance.call(null)
	await _instance_promise
	_instance_promise = null
	return _instance_id




func create_host(on_connection: Callable) -> Callable:
	var instance := await get_instance()
	
	var is_disposed := false
	
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
				var peer := await perform_handshake(false, sig, incoming_signal_stream)
				if peer:
					on_connection.call(peer)
			elif type == GotmHandshakeSignal.Type.SIGNAL:
				var incoming_signal_stream: PromiseStream = incoming_signal_streams.get(handshake_id)
				if incoming_signal_stream:
					incoming_signal_stream.add(payload)
	var dispose_signal_listener
	var on_instance_changed := func(new_instance: String):
		if is_disposed:
			return
		if dispose_signal_listener:
			push_error(
				"We have been issued a new virtual IP address because we lost our " +
			 	"connection to the IP service for too long. Peers that were " +
				"connected to us need to connect to our new virtual IP address."
			)
			dispose_signal_listener.call()
		incoming_signal_streams = {}
		dispose_signal_listener = _GotmUtility.fetch_event_stream(_Gotm.api_listen_origin + "/handshakeSignals?query=byTarget&target=" + new_instance, on_signals)
	on_instance_changed.call(instance)
	_instance_changed_callbacks.push_back(on_instance_changed)

	var dispose := func():
		if is_disposed:
			return
		dispose_signal_listener.call()
		_instance_changed_callbacks.erase(on_instance_changed)
		is_disposed = true
	
	return dispose

func connect_to_host(target: String):
	var instance: String = (await _GotmStore.create("instances", {})).path
	var start_signal := format_signal(await _GotmStore.create("handshakeSignals", {"owner": instance, "target": target, "type": "start"}))
	
	var incoming_signal_stream := PromiseStream.new()
	var on_signals := func(signals_list: Dictionary) -> void:
		print("connect_to_host signals: ", signals_list)
		for sig in format_signals(signals_list):
			if sig.type == GotmHandshakeSignal.Type.SIGNAL:
				incoming_signal_stream.add(sig)				
	var dispose_signal_listener := _GotmUtility.fetch_event_stream(_Gotm.api_listen_origin + "/handshakeSignals?query=byInitiator&initiator=" + instance + "&handshakeId=" + start_signal.handshake_id, on_signals)
	var peer := await perform_handshake(true, start_signal, incoming_signal_stream)
	dispose_signal_listener.call()
	return peer


func stuff():
	Gotm.project_key = "authenticators/ccG2PZyIak36FjT2COCE"
	await create_host(func(): pass)


# Create the two peers.
var p1 = WebRTCPeerConnection.new()
var p2 = WebRTCPeerConnection.new()
var ch1 = p1.create_data_channel("chat", {"id": 1, "negotiated": true})
var ch2 = p2.create_data_channel("chat", {"id": 1, "negotiated": true})

func _ready():
	stuff()
	return
#	multiplayer.multiplayer_peer = p1
	print(p1.create_data_channel("chat", {"id": 1, "negotiated": true}))
	# Connect P1 session created to itself to set local description.
	p1.session_description_created.connect(p1.set_local_description)
	# Connect P1 session and ICE created to p2 set remote description and candidates.
	p1.session_description_created.connect(p2.set_remote_description)
	p1.ice_candidate_created.connect(p2.add_ice_candidate)

	# Same for P2.
	p2.session_description_created.connect(p2.set_local_description)
	p2.session_description_created.connect(p1.set_remote_description)
	p2.ice_candidate_created.connect(p1.add_ice_candidate)

	# Let P1 create the offer.
	p1.create_offer()

	# Wait a second and send message from P1.
	while p1.get_connection_state() == WebRTCPeerConnection.STATE_CONNECTING:
		await get_tree().process_frame
	ch1.put_packet("Hi from P1".to_utf8_buffer())
	ch2.put_packet("Hi from P2".to_utf8_buffer())


func _process(delta):
	p1.poll()
	p2.poll()
	if ch1.get_ready_state() == ch1.STATE_OPEN and ch1.get_available_packet_count() > 0:
		print("P1 received: ", ch1.get_packet().get_string_from_utf8())
	if ch2.get_ready_state() == ch2.STATE_OPEN and ch2.get_available_packet_count() > 0:
		print("P2 received: ", ch2.get_packet().get_string_from_utf8())
