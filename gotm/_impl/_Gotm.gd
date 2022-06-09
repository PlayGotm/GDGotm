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

const _version = "0.0.1"
const _global = {"value": null}
static func get_global() -> __GotmGlobalData:
	return _global.value

static func initialize(config: GotmConfig) -> void:
	_global.value = __GotmGlobalData.new()
	var global := get_global()
	global.config = _GotmUtility.copy(config, GotmConfig.new())
	var gotm = get_singleton()
	if gotm:
		gotm.initialize(global)

static func is_live() -> bool:
	return get_singleton()

static func get_config() -> GotmConfig:
	return _GotmUtility.copy(get_global().config, GotmConfig.new())
	
static func get_singleton():
	return Engine.get_singleton("Gotm")