const Utility := preload("res://tests/unit/utility/utility.gd")

#
#func test_lobby_create() -> UnitTestInfo:
#	var lobby := await GotmLobby.create("test_create", {"a": 1})
#	assert(lobby != null)
#	assert(lobby.name == "test_create")
#	assert(lobby.properties.a == 1)
#	assert(lobby.address == await GotmMultiplayer.get_address())
#	var fetched_with_id := await GotmLobby.fetch(lobby.id)
#	assert(fetched_with_id != null)
#	assert(fetched_with_id.id == lobby.id)
#	var fetched_with_lobby := await GotmLobby.fetch(lobby)
#	assert(fetched_with_lobby != null)
#	assert(fetched_with_lobby.id == lobby.id)
#
#	await GotmLobby.delete(lobby)
#	return UnitTestInfo.new(true)
#
#
#func test_lobby_update() -> UnitTestInfo:
#	var lobby := await GotmLobby.create("test_update", {"a": 2})
#	assert(lobby != null)
#
#	var updated_lobby = await GotmLobby.update(lobby.id,"test_update2", {"a": 3, "b": "a"})
#	assert(updated_lobby != null)
#	assert(updated_lobby.name == "test_update2")
#	assert(updated_lobby.properties.a == 3)
#	assert(updated_lobby.properties.b == "a")
#	var fetched_lobby = await GotmLobby.fetch(lobby.id)
#	assert(fetched_lobby != null)
#	assert(updated_lobby.name == "test_update2")
#	assert(updated_lobby.properties.a == 3)
#	assert(updated_lobby.properties.b == "a")
#
#	updated_lobby = await GotmLobby.update(lobby, null, {"foo":"bar"})
#	assert(updated_lobby != null)
#	assert(updated_lobby.name == "test_update2")
#	assert(updated_lobby.properties.foo == "bar")
#	fetched_lobby = await GotmLobby.fetch(lobby.id)
#	assert(fetched_lobby != null)
#	assert(updated_lobby.name == "test_update2")
#	assert(updated_lobby.properties.foo == "bar")
#
#	updated_lobby = await GotmLobby.update(lobby, "test_update3", null)
#	assert(updated_lobby != null)
#	assert(updated_lobby.name == "test_update3")
#	assert(updated_lobby.properties.foo == "bar")
#	fetched_lobby = await GotmLobby.fetch(lobby.id)
#	assert(fetched_lobby != null)
#	assert(updated_lobby.name == "test_update3")
#	assert(updated_lobby.properties.foo == "bar")
#	await GotmLobby.delete(lobby)
#	return UnitTestInfo.new(true)
#
#
#func test_lobby_delete() -> UnitTestInfo:
#	var lobby := await GotmLobby.create("test_delete")
#	assert(lobby != null)
#	var fetched_lobby = await GotmLobby.fetch(lobby.id)
#	assert(fetched_lobby != null)
#	var deleted = await GotmLobby.delete(lobby.id)
#	assert(deleted == true)
#	Engine.print_error_messages = false
#	fetched_lobby = await GotmLobby.fetch(lobby.id)
#	Engine.print_error_messages = true
#	assert(fetched_lobby == null)
#	return UnitTestInfo.new(true)


func test_lobby_list() -> UnitTestInfo:
	var lobby1 := await GotmLobby.create("test_list1", {"a": 3})
	var lobby2 := await GotmLobby.create("test_list2", {"a": 2})

	var created := GotmQuery.Filter.new()
	created.property_path = "created"
	Utility.assert_resource_equality(await GotmLobby.list(null, null, created), [lobby2, lobby1])
	Utility.assert_resource_equality(await GotmLobby.list(null, null, created, false, lobby2), [lobby1])
	Utility.assert_resource_equality(await GotmLobby.list(null, null, created, false, lobby1), [])
	Utility.assert_resource_equality(await GotmLobby.list(null, null, created, true, lobby1), [lobby2])
	Utility.assert_resource_equality(await GotmLobby.list(null, null, created, true, lobby2), [])
	Utility.assert_resource_equality(await GotmLobby.list("test_list1"), [lobby1])
	Utility.assert_resource_equality(await GotmLobby.list("list", null, created), [lobby2, lobby1])
	Utility.assert_resource_equality(await GotmLobby.list("list"), [lobby2, lobby1])
	Utility.assert_resource_equality(await GotmLobby.list("LIST", null, created), [lobby2, lobby1])
	Utility.assert_resource_equality(await GotmLobby.list("test_list2"), [lobby2])

	var property := GotmQuery.Filter.new()
	property.property_path = "properties/a"
	Utility.assert_resource_equality(await GotmLobby.list(null, null, property), [lobby1, lobby2])
	Utility.assert_resource_equality(await GotmLobby.list(null, null, property, false, lobby1), [lobby2])
	property.min_value = 3
	Utility.assert_resource_equality(await GotmLobby.list(null, null, property), [lobby1])
	property.is_min_exclusive = true
	Utility.assert_resource_equality(await GotmLobby.list(null, null, property), [])

	Utility.assert_resource_equality(await GotmLobby.list(null, {"a": 1}), [])
	Utility.assert_resource_equality(await GotmLobby.list(null, {"a": 2}), [lobby2])
	Utility.assert_resource_equality(await GotmLobby.list(null, {"a": 3}), [lobby1])


	await GotmLobby.delete(lobby1)
	await GotmLobby.delete(lobby2)
	return UnitTestInfo.new(true)
