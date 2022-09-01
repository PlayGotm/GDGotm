class_name GotmFile
#warnings-disable

## A simple in-memory file descriptor used by 'Gotm.pick_files' and 
## 'Gotm.files_dropped'.



##############################################################
# PROPERTIES
##############################################################
## File name.
var name: String

## File data.
var data: PoolByteArray

## Last time the file was modified in unix time (seconds since epoch).
var modified_time: int



##############################################################
# METHODS
##############################################################
## Save the file to the browser's download folder.
func download() -> void:
	pass
