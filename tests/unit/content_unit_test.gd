class_name GotmUnitTest_Content

const TestUtility := preload("res://tests/unit/utility/utility.gd")

func test_all() -> GotmUnitTest.TestInfo:
	# Clear existing contents so the test runs the same every time.
	await GotmUnitTest_Content._clear_contents()
	
	# Test serialization for variants
	for value in ["herpderp", {"herp": "derp"}, ["herp", "derp"]]:
		var content = await GotmContent.create(value)
		var loaded_value = await GotmContent.get_variant(content)
		TestUtility.assert_equality(JSON.stringify(value), JSON.stringify(loaded_value))
		await GotmContent.delete(content)
	
	# Test serialization for node
	var control := Control.new()
	control.position.x = 1337
	var node_content = await GotmContent.create(control)
	var loaded_node = await GotmContent.get_node(node_content)
	TestUtility.assert_equality(loaded_node.position.x, 1337)
	TestUtility.assert_equality(loaded_node is Control, true)
	await GotmContent.delete(node_content)
	
	var directory = "my_directory"
	var extension = "txt"
	var basename = "my_basename" + "." + extension
	var key = directory + "/" + basename
	var string_data = "my_data"
	
	# Create scores
	var content: GotmContent = await GotmContent.create(var_to_bytes(string_data), key)

	var fetched_data: PackedByteArray = await GotmContent.get_data(content)
	TestUtility.assert_equality(bytes_to_var(fetched_data), string_data)

	TestUtility.assert_equality(content.size, fetched_data.size())


	# Get by key
	TestUtility.assert_resource_equality(await GotmContent.get_by_key(key), content)

	# Get contents by directory
	var directory_contents: Array = await GotmContent.list(GotmQuery.new().filter("directory", directory))
	TestUtility.assert_equality(directory_contents.size(), 1)
	TestUtility.assert_resource_equality(directory_contents[0], content)

	# Update by key
	var new_string_data: String = "my_new_data"
	var updated_content: GotmContent = await GotmContent.update_by_key(key, var_to_bytes(new_string_data))
	TestUtility.assert_resource_equality(updated_content, content)
	var new_fetched_data: PackedByteArray = await GotmContent.get_data(updated_content)
	TestUtility.assert_equality(bytes_to_var(new_fetched_data), new_string_data)

	# Delete by key
	await GotmContent.delete_by_key(key)
	TestUtility.assert_equality(await GotmContent.get_by_key(key), null)

	# Create local 
	var local_content: GotmContent = await GotmContent.create_local(var_to_bytes(string_data), key)
	TestUtility.assert_resource_equality(await GotmContent.fetch(local_content), local_content)
	TestUtility.assert_resource_equality(await GotmContent.get_by_key(key), local_content)
	await GotmContent.delete(local_content)
	TestUtility.assert_equality(await GotmContent.get_by_key(key), null)
	
	
	# Do complex filtering
	var content1: GotmContent = await GotmContent.create(null, "", {"difficulty": "hard", "level": 1})
	var content2: GotmContent = await GotmContent.create(null, "", {"difficulty": "medium", "level": 2})
	var content3: GotmContent = await GotmContent.create(null, "", {"difficulty": "hard", "level": 3})
	var top_level_hard: Array = await GotmContent.list(GotmQuery.new().filter("properties/difficulty", "hard").sort("properties/level"))
	TestUtility.assert_resource_equality(top_level_hard, [content3, content1])
	
	# Get contents by level range
	var more_than_level_one: Array = await GotmContent.list(GotmQuery.new().filter_min("properties/level", 2).filter_max("properties/level", 3))
	TestUtility.assert_resource_equality(more_than_level_one, [content3, content2])
	
	# Search contents by partial name matching.
	var named_content: GotmContent = await GotmContent.create(null, "", {}, "the best map ever")
	var best_map_search: Array = await GotmContent.list(GotmQuery.new().filter("name_part", "best map"))
	TestUtility.assert_resource_equality(best_map_search, [named_content])
	await GotmContent.delete(named_content)
	
	# Create content only visible to us.
	var private_content: GotmContent = await GotmContent.create(null, "", {}, "", [], true)
	var my_private_contents: Array = await GotmContent.list(GotmQuery.new().filter("is_private", true))
	var non_private_contents: Array = await GotmContent.list()
	TestUtility.assert_resource_equality(my_private_contents, [private_content])
	TestUtility.assert_resource_equality(non_private_contents, [content3, content2, content1])
	
	# Upvote and downvote content.
	var auth: GotmAuth = await GotmAuth.fetch()
	var upvote: GotmMark = await GotmMark.create(content2, GotmMark.Types.UPVOTE)
	var downvote: GotmMark = await GotmMark.create(content1, GotmMark.Types.DOWNVOTE)
	if auth.is_registered:
		var top_upvoted_contents: Array = await GotmContent.list(GotmQuery.new().sort("score"))
		TestUtility.assert_resource_equality(top_upvoted_contents, [content2, content3, content1])
	TestUtility.assert_resource_equality(await GotmMark.list_by_target(content2), [upvote])
	TestUtility.assert_resource_equality(await GotmMark.list_by_target(content1), [downvote])
	
	
	# Upvote/downvote count
	var upvote_count: int = await GotmMark.get_count_with_type(content2, GotmMark.Types.UPVOTE)
	var downvote_count: int = await GotmMark.get_count_with_type(content1, GotmMark.Types.DOWNVOTE)
	TestUtility.assert_equality(upvote_count, 1)
	TestUtility.assert_equality(downvote_count, 1)
	await GotmMark.delete(upvote)
	await GotmMark.delete(downvote)
	TestUtility.assert_equality(await GotmMark.get_count_with_type(content2, GotmMark.Types.UPVOTE), 0)
	TestUtility.assert_equality(await GotmMark.get_count_with_type(content1, GotmMark.Types.DOWNVOTE), 0)
	
	
	# Delete children
	var parent1: GotmContent = await GotmContent.create()
	var parent2: GotmContent = await GotmContent.create()
	
	var child: GotmContent = await GotmContent.create(null, "", {}, "", [parent1, parent2])
	TestUtility.assert_resource_equality(child.parent_ids, [parent1.id, parent2.id])
	
	var children: Array = await GotmContent.list(GotmQuery.new().filter("parent_ids", [parent1]))
	TestUtility.assert_resource_equality(children, [child])
	children = await GotmContent.list(GotmQuery.new().filter("parent_ids", [parent2]))
	TestUtility.assert_resource_equality(children, [child])
	children = await GotmContent.list(GotmQuery.new().filter("parent_ids", [parent1, parent2]))
	TestUtility.assert_resource_equality(children, [child])
	
	var parents: Array = await GotmContent.list(GotmQuery.new().filter("parent_ids", []).sort("created", true))
	TestUtility.assert_resource_equality(parents,  [content1, content2, content3, parent1, parent2])
	
	
	await GotmContent.delete(parent1)
	
	child = await GotmContent.fetch(child)
	TestUtility.assert_resource_equality(child.parent_ids, [parent2.id])
	
	children = await GotmContent.list(GotmQuery.new().filter("parent_ids", [parent1]))
	TestUtility.assert_resource_equality(children, [])
	children = await GotmContent.list(GotmQuery.new().filter("parent_ids", [parent2]))
	TestUtility.assert_resource_equality(children, [child])
	children = await GotmContent.list(GotmQuery.new().filter("parent_ids", [parent1, parent2]))
	TestUtility.assert_resource_equality(children, [])
	
	parents = await GotmContent.list(GotmQuery.new().filter("parent_ids", []).sort("created", true))
	TestUtility.assert_resource_equality(parents,  [content1, content2, content3, parent2])
	
	await GotmContent.delete(parent2)
	
	child = await GotmContent.fetch(child)
	TestUtility.assert_equality(child, null)
	
	children = await GotmContent.list(GotmQuery.new().filter("parent_ids", [parent1]))
	TestUtility.assert_resource_equality(children, [])
	children = await GotmContent.list(GotmQuery.new().filter("parent_ids", [parent2]))
	TestUtility.assert_resource_equality(children, [])
	children = await GotmContent.list(GotmQuery.new().filter("parent_ids", [parent1, parent2]))
	TestUtility.assert_resource_equality(children, [])
	
	parents = await GotmContent.list(GotmQuery.new().filter("parent_ids", []).sort("created", true))
	TestUtility.assert_resource_equality(parents,  [content1, content2, content3])
	
	
	return GotmUnitTest.TestInfo.new(!Gotm.project_key)


static func _clear_contents():
	for content in await GotmContent.list():
		await GotmContent.delete(content)
	for private_content in await GotmContent.list(GotmQuery.new().filter("is_private", true)):
		await GotmContent.delete(private_content)
