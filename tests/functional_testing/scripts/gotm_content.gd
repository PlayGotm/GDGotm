class_name GotmContentTest
extends Node

var print_console := true


func create(is_local: bool = false) -> void:
	var _data_option: OptionButton = $UI/ParamsScrollContainer/Params/Create/DataOptionButton
	var _data: LineEdit = $UI/ParamsScrollContainer/Params/Create/Data
	var _key: LineEdit = $UI/ParamsScrollContainer/Params/Create/Key
	var _name: LineEdit = $UI/ParamsScrollContainer/Params/Create/Name
	var _prop_name_1: LineEdit = $UI/ParamsScrollContainer/Params/Create/Prop1/PropName1
	var _prop_value_1: LineEdit = $UI/ParamsScrollContainer/Params/Create/Prop1/PropValue1
	var _prop_name_2: LineEdit = $UI/ParamsScrollContainer/Params/Create/Prop2/PropName2
	var _prop_value_2: LineEdit = $UI/ParamsScrollContainer/Params/Create/Prop2/PropValue2
	var _prop_name_3: LineEdit = $UI/ParamsScrollContainer/Params/Create/Prop3/PropName3
	var _prop_value_3: LineEdit = $UI/ParamsScrollContainer/Params/Create/Prop3/PropValue3
	var _parent_ID: LineEdit = $UI/ParamsScrollContainer/Params/Create/ParentID
	var _is_private: CheckButton = $UI/ParamsScrollContainer/Params/Create/Private

	var data
	match _data_option.selected:
		0: data = null
		1: data = _data.text
		2: data = _data.text.to_utf8_buffer()
		3: data = Node.new(); data.name = _data.text if !_data.text.is_empty() else "node"
	var props := {}
	if !_prop_name_1.text.is_empty(): props[_prop_name_1.text] = _prop_value_1.text
	if !_prop_name_2.text.is_empty(): props[_prop_name_2.text] = _prop_value_2.text
	if !_prop_name_3.text.is_empty(): props[_prop_name_3.text] = _prop_value_3.text
	var parents := []
	if !_parent_ID.text.is_empty(): parents.append(_parent_ID.text)
	var is_private := _is_private.button_pressed

	var content: GotmContent
	if is_local:
		content = await GotmContent.create_local(data, _key.text, props, _name.text, parents, is_private)
	else:
		content = await GotmContent.create(data, _key.text, props, _name.text, parents, is_private)
	if !content:
		push_error("Could not create content...")
		return
	if print_console:
		print("GotmContent created...")
		print(GotmContentTest.gotm_content_to_string(content))


func create_local() -> void:
	create(true)


func update(by_key: bool = false) -> void:
	var _id: LineEdit = $UI/ParamsScrollContainer/Params/Update/ID
	var _key: LineEdit = $UI/ParamsScrollContainer/Params/Update/Key
	var _data_option: OptionButton = $UI/ParamsScrollContainer/Params/Update/DataOptionButton
	var _data: LineEdit = $UI/ParamsScrollContainer/Params/Update/Data
	var _name: LineEdit = $UI/ParamsScrollContainer/Params/Update/Name
	var _new_key: LineEdit = $UI/ParamsScrollContainer/Params/Update/NewKey
	var _prop_name_1: LineEdit = $UI/ParamsScrollContainer/Params/Update/Prop1/PropName1
	var _prop_value_1: LineEdit = $UI/ParamsScrollContainer/Params/Update/Prop1/PropValue1
	var _prop_name_2: LineEdit = $UI/ParamsScrollContainer/Params/Update/Prop2/PropName2
	var _prop_value_2: LineEdit = $UI/ParamsScrollContainer/Params/Update/Prop2/PropValue2
	var _prop_name_3: LineEdit = $UI/ParamsScrollContainer/Params/Update/Prop3/PropName3
	var _prop_value_3: LineEdit = $UI/ParamsScrollContainer/Params/Update/Prop3/PropValue3

	@warning_ignore("incompatible_ternary")
	var new_name = _name.text if !_name.text.is_empty() else null
	@warning_ignore("incompatible_ternary")
	var new_key = _new_key.text if !_new_key.text.is_empty() else null
	var data
	match _data_option.selected:
		0: data = null
		1: data = _data.text
		2: data = _data.text.to_utf8_buffer()
		3: data = Node.new(); data.name = _data.text if !_data.text.is_empty() else "node"
	var props = {}
	if !_prop_name_1.text.is_empty(): props[_prop_name_1.text] = _prop_value_1.text
	if !_prop_name_2.text.is_empty(): props[_prop_name_2.text] = _prop_value_2.text
	if !_prop_name_3.text.is_empty(): props[_prop_name_3.text] = _prop_value_3.text
	if props.is_empty(): props = null

	var content: GotmContent
	if by_key:
		content = await GotmContent.update_by_key(_key.text, data, new_key, props, new_name)
	else:
		content = await GotmContent.update(_id.text, data, new_key, props, new_name)
	if !content:
		push_error("Could not update content...")
		return
	if print_console:
		print("GotmContent updated...")
		print(GotmContentTest.gotm_content_to_string(content))


func update_by_key() -> void:
	update(true)


func delete(by_key: bool = false) -> void:
	var _id: LineEdit = $UI/ParamsScrollContainer/Params/Delete/ID
	var _key: LineEdit = $UI/ParamsScrollContainer/Params/Delete/Key

	var result := false
	if by_key:
		result = await GotmContent.delete_by_key(_key.text)
	else:
		result = await GotmContent.delete(_id.text)
	if !result:
		push_error("Could not delete content...")
		return
	if print_console:
		print("GotmContent deleted...")


func delete_by_key() -> void:
	delete(true)


func fetch() -> void:
	var _id: LineEdit = $"UI/ParamsScrollContainer/Params/Fetch&GetByKey/ID"

	var content := await GotmContent.fetch(_id.text)
	if !content:
		push_error("Could not fetch content...")
		return
	if print_console:
		print("GotmContent fetched...")
		print(GotmContentTest.gotm_content_to_string(content))


func get_by_key() -> void:
	var _key: LineEdit = $"UI/ParamsScrollContainer/Params/Fetch&GetByKey/Key"

	var content := await GotmContent.get_by_key(_key.text)
	if !content:
		push_error("Could not get content by key...")
		return
	if print_console:
		print("GotmContent got content by key...")
		print(GotmContentTest.gotm_content_to_string(content))


func get_data(by_key: bool = false) -> void:
	var _id: LineEdit = $UI/ParamsScrollContainer/Params/GetData/ID
	var _key: LineEdit = $UI/ParamsScrollContainer/Params/GetData/Key

	var data: PackedByteArray
	if by_key:
		data = await GotmContent.get_data_by_key(_key.text)
	else:
		data = await GotmContent.get_data(_id.text)
	if data == null:
		push_error("Could not get content data as PackedByteArray...")
		return
	if print_console:
		print("GotmContent Data: ", data)


func get_data_by_key() -> void:
	get_data(true)


func get_node_content(by_key: bool = false) -> void:
	var _id: LineEdit = $UI/ParamsScrollContainer/Params/GetNode/ID
	var _key: LineEdit = $UI/ParamsScrollContainer/Params/GetNode/Key
	
	var node: Node = null
	if by_key:
		node = await GotmContent.get_node_by_key(_key.text)
	else:
		node = await GotmContent.get_node(_id.text)
	if node == null:
		push_error("Could not get content as Node...")
		return
	if print_console:
		print("GotmContent Node Name: ", node.name)


func get_node_content_by_key() -> void:
	get_node_content(true)


func get_variant(by_key: bool = false) -> void:
	var _id: LineEdit = $UI/ParamsScrollContainer/Params/GetVariant/ID
	var _key: LineEdit = $UI/ParamsScrollContainer/Params/GetVariant/Key
	
	var content
	if by_key:
		content = await GotmContent.get_variant_by_key(_key.text)
	else:
		content = await GotmContent.get_variant(_id.text)
	if content == null:
		push_error("Could not get content as Variant...")
		return
	if print_console:
		print("GotmContent variant type %d" % typeof(content))
		print("---------------------------")
		print(var_to_str(content), "\n")


func get_variant_by_key() -> void:
	get_variant(true)


func get_properties(by_key: bool = false) -> void:
	var _id: LineEdit = $UI/ParamsScrollContainer/Params/GetProperties/ID
	var _key: LineEdit = $UI/ParamsScrollContainer/Params/GetProperties/Key
	
	var props: Dictionary
	if by_key:
		props = await GotmContent.get_properties_by_key(_key.text)
	else:
		props = await GotmContent.get_properties(_id.text)
	if print_console:
		print("GotmContent Properties:")
		print("---------------------------")
		print(props)


func get_properties_by_key() -> void:
	get_properties(true)


func list() -> void:
	var _filter_option_1: OptionButton = $UI/ParamsScrollContainer/Params/List/QueryButton1
	var _filter_option_2: OptionButton = $UI/ParamsScrollContainer/Params/List/QueryButton2
	var _filter_option_3: OptionButton = $UI/ParamsScrollContainer/Params/List/QueryButton3
	var _filter_path_1: LineEdit = $UI/ParamsScrollContainer/Params/List/Path1
	var _filter_path_2: LineEdit = $UI/ParamsScrollContainer/Params/List/Path2
	var _filter_path_3: LineEdit = $UI/ParamsScrollContainer/Params/List/Path3
	var _filter_value_1: LineEdit = $UI/ParamsScrollContainer/Params/List/Value1
	var _filter_value_2: LineEdit = $UI/ParamsScrollContainer/Params/List/Value2
	var _filter_value_3: LineEdit = $UI/ParamsScrollContainer/Params/List/Value3
	var _sort_path: LineEdit = $UI/ParamsScrollContainer/Params/List/Sort/Path
	var _ascending_value: CheckButton = $UI/ParamsScrollContainer/Params/List/Sort/Value
	var _after_id: LineEdit = $UI/ParamsScrollContainer/Params/List/AfterID

	var string_representation := "GotmQuery.new()"
	var query := GotmQuery.new()

	match _filter_option_1.selected:
		0: pass
		1:
			string_representation += (".filter(\"%s\", \"%s\")" % [_filter_path_1.text, _filter_value_1.text])
			query = query.filter(_filter_path_1.text, _filter_value_1.text)
		2:
			string_representation += (".filter_min(\"%s\", \"%s\")" % [_filter_path_1.text, _filter_value_1.text])
			query = query.filter_min(_filter_path_1.text, _filter_value_1.text)
		3:
			string_representation += (".filter_max(\"%s\", \"%s\")" % [_filter_path_1.text, _filter_value_1.text])
			query = query.filter_max(_filter_path_1.text, _filter_value_1.text)

	match _filter_option_2.selected:
		0: pass
		1:
			string_representation += (".filter(\"%s\", \"%s\")" % [_filter_path_2.text, _filter_value_2.text])
			query = query.filter(_filter_path_2.text, _filter_value_2.text)
		2:
			string_representation += (".filter_min(\"%s\", \"%s\")" % [_filter_path_2.text, _filter_value_2.text])
			query = query.filter_min(_filter_path_2.text, _filter_value_2.text)
		3:
			string_representation += (".filter_max(\"%s\", \"%s\")" % [_filter_path_2.text, _filter_value_2.text])
			query = query.filter_max(_filter_path_2.text, _filter_value_2.text)


	match _filter_option_3.selected:
		0: pass
		1:
			string_representation += (".filter(\"%s\", \"%s\")" % [_filter_path_3.text, _filter_value_3.text])
			query = query.filter(_filter_path_3.text, _filter_value_3.text)
		2:
			string_representation += (".filter_min(\"%s\", \"%s\")" % [_filter_path_3.text, _filter_value_3.text])
			query = query.filter_min(_filter_path_3.text, _filter_value_3.text)
		3:
			string_representation += (".filter_max(\"%s\", \"%s\")" % [_filter_path_3.text, _filter_value_3.text])
			query = query.filter_max(_filter_path_3.text, _filter_value_3.text)

	if !_sort_path.text.is_empty():
		string_representation += (".sort(\"%s\", %s)" % [_sort_path.text, str(_ascending_value.button_pressed)])
		query.sort(_sort_path.text, _ascending_value.button_pressed)

	var after_id = null
	if !_after_id.text.is_empty():
		after_id = _after_id.text

	if print_console:
		print("GotmContent.list() called...")
		print("Query: ", string_representation)
		print("Filters: ", query.filters)
		print("Sorts: ", query.sorts)

	var result := await GotmContent.list(query, after_id)
	if print_console:
		print("GotmContent ID List: ")
		var result_ids := []
		for content in result:
			result_ids.append(content.id)
		print(result_ids, "\n")


static func gotm_content_to_string(content: GotmContent) -> String:
	var result := "\nGotmContent:\n"
	result += "[id] %s\n" % content.id
	result += "[user_id] %s\n" % content.user_id
	result += "[created] %s\n" % Time.get_datetime_string_from_unix_time(content.created)
	result += "[is_local] %s\n" % str(content.is_local)
	result += "[is_private] %s\n" % str(content.is_private)
	result += "[key] %s\n" % content.key
	result += "[name] %s\n" % content.name
	result += "[parent_ids] %s\n" % str(content.parent_ids)
	result += "[properties] %s\n" % content.properties
	result += "[size] %d\n" % content.size
	result += "[updated] %s\n" % Time.get_datetime_string_from_unix_time(content.updated)
	return result


func _check_menu(_param = null) -> void:
	_disable_menu()
	# Update Button
	if $UI/ParamsScrollContainer/Params/Update/ID.text != "":
		$UI/MenuScrollContainer/Menu/Update.disabled = false
	# Update By Key Button
	if $UI/ParamsScrollContainer/Params/Update/Key.text != "":
		$UI/MenuScrollContainer/Menu/UpdateByKey.disabled = false
	# Delete Button
	if $UI/ParamsScrollContainer/Params/Delete/ID.text != "":
		$UI/MenuScrollContainer/Menu/Delete.disabled = false
	# Delete By Key Button
	if $UI/ParamsScrollContainer/Params/Delete/Key.text != "":
		$UI/MenuScrollContainer/Menu/DeleteByKey.disabled = false
	# Fetch Button
	if $"UI/ParamsScrollContainer/Params/Fetch&GetByKey/ID".text != "":
		$UI/MenuScrollContainer/Menu/Fetch.disabled = false
	# Get By Key Button
	if $"UI/ParamsScrollContainer/Params/Fetch&GetByKey/Key".text != "":
		$UI/MenuScrollContainer/Menu/GetByKey.disabled = false
	# Get Data Button
	if $UI/ParamsScrollContainer/Params/GetData/ID.text != "":
		$UI/MenuScrollContainer/Menu/GetData.disabled = false
	# Get Data By Key Button
	if $UI/ParamsScrollContainer/Params/GetData/Key.text != "":
		$UI/MenuScrollContainer/Menu/GetDataByKey.disabled = false
	# Get Node Button
	if $UI/ParamsScrollContainer/Params/GetNode/ID.text != "":
		$UI/MenuScrollContainer/Menu/GetNode.disabled = false
	# Get Node By Key Button
	if $UI/ParamsScrollContainer/Params/GetNode/Key.text != "":
		$UI/MenuScrollContainer/Menu/GetNodeByKey.disabled = false
	# Get Variant Button
	if $UI/ParamsScrollContainer/Params/GetVariant/ID.text != "":
		$UI/MenuScrollContainer/Menu/GetVariant.disabled = false
	# Get Variant By Key Button
	if $UI/ParamsScrollContainer/Params/GetVariant/Key.text != "":
		$UI/MenuScrollContainer/Menu/GetVariantByKey.disabled = false
	# Get Properties Button
	if $UI/ParamsScrollContainer/Params/GetProperties/ID.text != "":
		$UI/MenuScrollContainer/Menu/GetProperties.disabled = false
	# Get Properties By Key Button
	if $UI/ParamsScrollContainer/Params/GetProperties/Key.text != "":
		$UI/MenuScrollContainer/Menu/GetPropertiesByKey.disabled = false


func _disable_menu() -> void:
	$UI/MenuScrollContainer/Menu/Update.disabled = true
	$UI/MenuScrollContainer/Menu/UpdateByKey.disabled = true
	$UI/MenuScrollContainer/Menu/Delete.disabled = true
	$UI/MenuScrollContainer/Menu/DeleteByKey.disabled = true
	$UI/MenuScrollContainer/Menu/Fetch.disabled = true
	$UI/MenuScrollContainer/Menu/GetByKey.disabled = true
	$UI/MenuScrollContainer/Menu/CreateMark.disabled = true
	$UI/MenuScrollContainer/Menu/CreateLocalMark.disabled = true
	$UI/MenuScrollContainer/Menu/ListMarks.disabled = true
	$UI/MenuScrollContainer/Menu/ListMarksWithType.disabled = true
	$UI/MenuScrollContainer/Menu/GetMarkCount.disabled = true
	$UI/MenuScrollContainer/Menu/GetData.disabled = true
	$UI/MenuScrollContainer/Menu/GetNode.disabled = true
	$UI/MenuScrollContainer/Menu/GetVariant.disabled = true
	$UI/MenuScrollContainer/Menu/GetProperties.disabled = true
	$UI/MenuScrollContainer/Menu/GetDataByKey.disabled = true
	$UI/MenuScrollContainer/Menu/GetNodeByKey.disabled = true
	$UI/MenuScrollContainer/Menu/GetVariantByKey.disabled = true
	$UI/MenuScrollContainer/Menu/GetPropertiesByKey.disabled = true


func _on_console_print_toggled(button_pressed: bool) -> void:
	print_console = button_pressed
