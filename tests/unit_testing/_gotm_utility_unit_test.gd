class_name GotmUnitTest_Utility
extends Node

var test_script := preload("res://unit_testing/_gotm_utility_unit_test_1.gd")


func test_copy() -> void:
	var arr1 := [1, 2, 3]
	var arr2 := [4, 5, 6]
	_GotmUtility.copy(arr2, arr1)
	assert(arr1 == arr2)

	var dict1 := {"a": 1, "b": 2, "c": 3}
	var dict2 := {"a": 4, "b": 5, "c": 6}
	_GotmUtility.copy(dict2, dict1)
	assert(dict1 == dict2)

	var node1: Node = test_script.new()
	var node2: Node = test_script.new()
	node2.test1 = 123; node2.test2 = 456; node2.test3 = 789
	_GotmUtility.copy(node2, node1)
	assert(node1.test1 == node2.test1 && node1.test2 == node2.test2 && node1.test3 == node2.test3)


func test_delete_empty() -> void:
	var dict := {0: "a", 1: null, 2: "b", 3: "", 4: "c"}
	_GotmUtility.delete_empty(dict)
	assert(dict == {0: "a", 2: "b", 4: "c"})


func test_delete_null() -> void:
	var dict := {0: "a", 1: null, 2: "b", 3: null, 4: "c"}
	_GotmUtility.delete_null(dict)
	assert(dict == {0: "a", 2: "b", 4: "c"})


func test_get_keys() -> void:
	var result: Array
	result = _GotmUtility._get_keys(["abc", 1, 3.14, true])
	assert(result == [0, 1, 2, 3])
	result = _GotmUtility._get_keys([])
	assert(result == [])

	result = _GotmUtility._get_keys({"abc": 0, 123: 0, true: 0})
	assert(result == ["abc", 123, true])

	result = _GotmUtility._get_keys(test_script.new())
	assert(result == ["test1", "test2", "test3"])
