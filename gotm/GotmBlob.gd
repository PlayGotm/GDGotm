class_name GotmBlob
#warnings-disable

## A GotmBlob is a piece of arbitrary data stored as a PoolByteArray.
## The data can be anything, such as images, scenes or JSON files.

##############################################################
# PROPERTIES
##############################################################

## Unique immutable identifier.
var id: String

## The size of the blob's data in bytes.
var size: int

## Is true if this blob is only stored locally on the user's device.
var is_local: bool

##############################################################
# METHODS
##############################################################

## Get an existing blob.
static func fetch(blob_or_id) -> GotmBlob:
	return yield(_GotmBlob.fetch(blob_or_id), "completed")

## Get the blob's data as a PoolByteArray.
static func get_data(blob_or_id) -> PoolByteArray:
	return yield(_GotmBlob.get_data(blob_or_id), "completed")
