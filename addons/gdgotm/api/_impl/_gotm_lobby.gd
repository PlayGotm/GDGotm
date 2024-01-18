class_name _GotmLobby


static func create(name: String, properties: Dictionary) -> GotmLobby:
	if !_check_project_key():
		return
	properties = _GotmUtility.clean_for_json(properties)
	var auth := await _GotmAuth.get_auth_async()
	await _initialize_instance()
	var lobby: Dictionary = await _GotmStore.create("lobbies", {"name": name, "props": properties, "target": auth.project, "author": auth.instance})
	_clear_cache()
	return _format(lobby, GotmLobby.new())


static func delete(lobby_or_id) -> bool:
	if !_check_project_key():
		return false
	if !(lobby_or_id is GotmLobby || lobby_or_id is String):
		push_error("[GotmLobby] Expected a GotmLobby or GotmLobby.id string.")
		return false

	var id := _coerce_id(lobby_or_id)
	var result := await _GotmStore.delete(id)
	_clear_cache()
	return result


static func fetch(lobby_or_id) -> GotmLobby:
	if !_check_project_key():
		return
	if !(lobby_or_id is GotmLobby || lobby_or_id is String):
		push_error("[GotmLobby] Expected a GotmLobby or GotmLobby.id string.")
		return null

	var id := _coerce_id(lobby_or_id)
	var lobby: Dictionary = await _GotmStore.fetch(id)
	if !lobby:
		push_error("[GotmLobby] Cannot fetch lobby with id: ", id)
		return null
	return _format(lobby, GotmLobby.new())


static func list(name = null, properties = null, sort: GotmQuery.Filter = null, ascending: bool = false, after_lobby_or_id = null) -> Array:
	if !_check_project_key():
		return []
	var project := (await _GotmAuth.get_auth_async()).project
	if !project:
		return []
	var params := _GotmUtility.delete_empty({
		"target": project, 
		"props": properties,
		"name": name, 
		"descending": !ascending
	})
	if sort && sort.property_path:
		params.sort = sort.property_path
		if params.sort.begins_with("properties/"):
			params.sort = "props/" + params.sort.substr("params.sort".length())
		if sort.max_value != null:
			params.max = sort.max_value
		if sort.min_value != null:
			params.min = sort.min_value
		if sort.is_max_exclusive:
			params.maxExclusive = true
		if sort.is_min_exclusive:
			params.minExclusive = true

	if !params.get("sort"):
		params.sort = "created"

	var after_id := ""
	if after_lobby_or_id is GotmLobby || after_lobby_or_id is String:
		after_id = _coerce_id(after_lobby_or_id)
	if after_id:
		params.after = await _encode_cursor(params.sort, after_id)

	var data_list := await _GotmStore.list("lobbies", "byProps", params)
	if data_list.is_empty():
		return []

	var lobbies = []
	for data in data_list:
		lobbies.append(await _format(data, GotmLobby.new()))
	return lobbies


static func update(lobby_or_id, name = null, properties = null) -> GotmLobby:
	if !_check_project_key():
		return
	if !(lobby_or_id is GotmLobby || lobby_or_id is String):
		push_error("[GotmLobby] Expected a GotmLobby or GotmLobby.id string.")
		return null

	var id := _coerce_id(lobby_or_id)
	if id.is_empty():
		return null
	properties = _GotmUtility.clean_for_json(properties)
	var body = _GotmUtility.delete_null({
		"props": properties,
		"name": name,
	})
	
	var lobby: Dictionary = await _GotmStore.update(id, body)
	_clear_cache()
	return await _format(lobby, GotmLobby.new())
	


static func _format(data: Dictionary, lobby: GotmLobby) -> GotmLobby:
	if data.is_empty() || !lobby:
		return null

	lobby.id = data.path
	lobby.name = data.name
	lobby.address = _GotmUtility.get_address_from_instance(data.author)
	lobby.properties = data.props if data.get("props") else {}
	lobby.created = data.created
	return lobby


static func _clear_cache() -> void:
	_GotmStore.clear_cache("lobbies")


static func _coerce_id(resource_or_id) -> String:
	var id = _GotmUtility.coerce_resource_id(resource_or_id, "lobbies")
	if !(id is String):
		return ""
	return id


static func _coerce_ids(lobbies_or_ids: Array) -> Array:
	if lobbies_or_ids.is_empty():
		return []
	var ids := []
	for lobby_or_id in lobbies_or_ids:
		var id := _coerce_id(lobby_or_id)
		if !id.is_empty():
			ids.append(id)
	return ids


static var _has_initialized_instance := false
static func _initialize_instance() -> void:
	if !Gotm.project_key || _has_initialized_instance:
		return
	_has_initialized_instance = true

	var state = {"on_instance": null}
	state.on_instance = func(message: Dictionary) -> void:
		if message:
			return
		var auth := await _GotmAuth.get_auth_async()
		await _GotmStore.create("instances", {})
		_GotmUtility.fetch_event_stream(_Gotm.api_listen_origin + "/" + auth.instance, state.on_instance)
	await state.on_instance.call({})


static func _check_project_key() -> bool:
	if !Gotm.project_key:
		push_error("[GotmLobby] You need a project key to use this API. See docs.")
		return false
	return true
	

static func _get_instance_properties(instance) -> Array:
	if !instance:
		return []
	var properties := []
	for property in instance.get_property_list():
		properties.push_back(property.name)
	return properties

static func _encode_cursor(sort: String, id: String) -> String:
	var lobby := await fetch(id)
	if !lobby:
		return ""
	var value

	if sort in _get_instance_properties(lobby):
		value = lobby.get(sort)
	elif sort.begins_with("props/"):
		var parts := sort.split("/").slice(1)
		value = lobby.properties
		for part in parts:
			if !value.has(part):
				return ""
			value = value.get(part)
	else:
		return ""

	return _GotmUtility.encode_cursor([value, id.replace("/", "-") + "~"])
	
