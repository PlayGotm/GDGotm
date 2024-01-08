class_name GotmUnitTest
extends Node


func temp() -> void:
	var config := GotmConfig.new()
	config.project_key = "authenticators/ccG2PZyIak36FjT2COCE"
	Gotm.initialize(config)


func _ready() -> void:
	print("NOTE: If ran in the editor, there will be errors in the Debugger/Error tab. Please ignore.")
	temp()
	test_all()


func test(object: Object) -> void:
	# get unit tests
	var methods = object.get_method_list()
	methods.reverse()
	var unit_tests := PackedStringArray()
	for method in methods:
		if method.name.begins_with("test"):
			unit_tests.append(method.name)
		else: break
	unit_tests.reverse()

	# run unit tests
	var count = 1
	for unit_test in unit_tests:
		await get_tree().process_frame
		@warning_ignore("redundant_await") # actually not redundant
		var test_info = await Callable(object, unit_test).call()
		if test_info is TestInfo && test_info.is_online:
			print("☑\t", count ,"/", unit_tests.size(), "... ", unit_test, " (online)")
		else:
			print("☑\t", count ,"/", unit_tests.size(), "... ", unit_test, " (offline)")
		count += 1


func test_all() -> void:
	print("Running all unit tests...")
	await test_score()
	await test_leaderboard()
	await test_utility()
	print("Unit testing completed.")


func test_leaderboard() -> void:
	print("GotmLeaderboard unit test running...")
	await test(GotmUnitTest_Leaderboard.new())


func test_score() -> void:
	print("GotmScore unit test running...")
	await test(GotmUnitTest_Score.new())


func test_utility() -> void:
	print("_gotm_utility.gd unit test running...")
	await test(GotmUnitTest_Utility.new())


class TestInfo:
	var is_online := false

	func _init(online: bool) -> void:
		is_online = online
