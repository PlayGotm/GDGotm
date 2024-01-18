const Utility := preload("res://tests/unit/utility/utility.gd")


func test_connection() -> UnitTestInfo:
	var host := await GotmMultiplayer.create_server()
	var client := await GotmMultiplayer.create_client(await GotmMultiplayer.get_address())
	assert(client != null)

	var message_to_host := "i am client"
	var message_to_client := "i am host"
	host.put_var(message_to_client)
	client.put_var(message_to_host)
	var host_promise := _GotmUtility.ResolvablePromise.new()
	var client_promise := _GotmUtility.ResolvablePromise.new()
	host_promise.set_timeout(10000)
	client_promise.set_timeout(10000)
	var poller := func():
		while !host_promise.is_resolved() || !client_promise.is_resolved():
			host.poll()
			client.poll()
			if host.get_available_packet_count():
				assert(host.get_var() == message_to_host)
				host_promise.resolve()
			if client.get_available_packet_count():
				assert(client.get_var() == message_to_client)
				client_promise.resolve()
			await _GotmUtility.get_tree().process_frame
	poller.call()

	await host_promise.await_result()
	await client_promise.await_result()
	return UnitTestInfo.new(true)
