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

class_name _GotmBlob
#warnings-disable


static func get_implementation():
	var config := _Gotm.get_config()
	if !_Gotm.is_global_feature():
		return _GotmBlobLocal
	return _GotmStore


static func fetch_data(content_or_id):
	var id = _GotmUtility.coerce_resource_id(content_or_id)
	var local_data = _GotmBlobLocal.fetch_data_sync(id)
	if local_data:
		yield(_GotmUtility.get_tree(), "idle_frame")
		return local_data
	
	if !_Gotm.is_global_feature():
		return 
	
	var blob = yield(_GotmStore.fetch(id), "completed")
	if !blob:
		return
	
	var result = yield(_GotmUtility.fetch_data(blob.downloadUrl), "completed")
	if !result:
		return
	return result.data