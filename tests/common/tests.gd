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





func stuff():
	Gotm.project_key = "authenticators/ccG2PZyIak36FjT2COCE"
	var host := await GotmMultiplayer.create_server()
	var client := await GotmMultiplayer.create_client(await GotmMultiplayer.get_address())
	if !client:
		print("failed to connect to host")
	host.put_var("i am host")
	client.put_var("i am client")
	while true:
		host.poll()
		client.poll()

		while host.get_available_packet_count():
			print("host got: ", host.get_var())

		while client.get_available_packet_count():
			print("client got: ", client.get_var())
	

		await get_tree().process_frame

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
