class_name GotmPromise

var _result = null
var _coroutine = null

func _init(coroutine):
	_run(coroutine)
	
func _run(coroutine):
	if coroutine is GDScriptFunctionState:
		_coroutine = coroutine
		_result = yield(coroutine, "completed")
		_coroutine = null
	else:
		_result = coroutine
	
func get_result():
	if _coroutine:
		return yield(_coroutine, "completed")
	else:
		yield(Engine.get_main_loop().create_timer(0), "timeout")
		return _result
