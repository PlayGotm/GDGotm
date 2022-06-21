# MIT License
#
# Copyright (c) 2020-2022 Macaroni Studios AB
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

class_name _Gotm
#warnings-disable

class __GotmGlobalData:
	var config: GotmConfig
	var version: String = "0.0.1"
	var apiOrigin: String = "https://api.gotm.io"
	var classes: Dictionary = {}

const _version = "0.0.1"
const _global = {"value": null}
static func get_global() -> __GotmGlobalData:
	return _global.value

static func create_instance(name: String):
	return get_global().classes[name].new()

static func initialize(config: GotmConfig, classes: Dictionary) -> void:
	_global.value = __GotmGlobalData.new()
	var global := get_global()
	global.config = _GotmUtility.copy(config, GotmConfig.new())
	global.classes = classes
	var directory = Directory.new()
	directory.make_dir_recursive(get_local_path(""))

static func is_live() -> bool:
	return !!get_singleton()

static func is_global_feature(forceLocal: bool = false, forceGlobal: bool = false) -> bool:
	return !forceLocal && (is_live() || forceGlobal) && get_project_key()

static func get_project_key() -> String:
	return get_global().config.project_key

static func get_local_path(path: String = "") -> String:
	return get_path("local/" + path)

static func get_path(path: String = "") -> String:
	return "user://gotm/" + path

static func get_config() -> GotmConfig:
	return get_global().config
	
static func get_singleton():
	if !Engine.has_singleton("Gotm"):
		return
	return Engine.get_singleton("Gotm")


