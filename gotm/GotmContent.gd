class_name GotmContent
#warnings-disable


## BETA FEATURE
##
## A GotmContent is a piece of data that is used to affect your game's
## content dynamically, such as player-generated content, game saves,
## downloadable packs/mods or remote configuration.
##
## @tutorial: https://gotm.io/docs/content

##############################################################
# PROPERTIES
##############################################################

## Unique immutable identifier.
var id: String

## Unique identifier of the user who owns the content.
## Is automatically set to the current user's id when creating the content.
## If the content is created while the game runs outside gotm.io, this user will 
## always be an unregistered user with no display name.
## If the content is created while the game is running on Gotm with a signed in
## user, you can get their display name via GotmUser.fetch.
var user_id: String

## Optional unique key.
var key: String = ""

## Optional name searchable with partial search.
var name: String = ""

## Unique identifier of this content's data. Use GotmBlob.get_data(content.blob_id) to get the data as a PoolByteArray.
var blob_id: String = ""

## Optional metadata to attach to the content, 
## for example {level: "desert1", difficulty: "hard"}.
## When listing contents GotmContent.list, you can optionally 
## filter and sort with these properties. 
var properties: Dictionary = {}

## Optionally make this content a child to other contents.
## If all parents are deleted, this content is deleted too.
var parent_ids: Array = []

## Optionally make this content inaccessible to other users. Private content can only be fetched by the user
## who created it via GotmContent.list. Is useful for personal data such as game saves.
var is_private: bool = false

## Is true if this content was created with GotmContent.create_local and is only stored locally on the user's device.
## Is useful for data that does not need to be accessible to other devices, such as game saves for offline games.
var is_local: bool

## UNIX epoch time (in milliseconds). Use OS.get_datetime_from_unix_time(content.created / 1000) to convert to date.
var updated: int

## UNIX epoch time (in milliseconds). Use OS.get_datetime_from_unix_time(content.created / 1000) to convert to date.
var created: int


##############################################################
# METHODS
##############################################################

## Create content for the current user.
## See PROPERTIES above for descriptions of the arguments.
static func create(data = null, key: String = "", properties: Dictionary = {}, name: String = "", parent_ids: Array = [], is_private: bool = false)  -> GotmContent:
	return yield(_GotmContent.create(data, properties, key, name, parent_ids, is_private), "completed")

## Create content that is only stored locally on the user's device. Local content is not accessible to any other player or device.
static func create_local(data = null, key: String = "", properties: Dictionary = {}, name: String = "", parent_ids: Array = [], is_private: bool = false)  -> GotmContent:
	return yield(_GotmContent.create(data, properties, key, name, parent_ids, is_private, true), "completed")

## Update existing content.
## Null is ignored.
static func update(content_or_id, data = null, key = null, properties = null, name = null, parent_ids = null) -> GotmContent:
	return yield(_GotmContent.update(content_or_id, data, properties, key, name), "completed")

## Delete existing content.
static func delete(content_or_id) -> void:
	return yield(_GotmContent.delete(content_or_id), "completed")

## Get existing content.
static func fetch(content_or_id) -> GotmContent:
	return yield(_GotmContent.fetch(content_or_id), "completed")

## Get existing content by key.
static func get_by_key(key: String) -> GotmContent:
	return yield(_GotmContent.get_by_key(key), "completed")

## Update existing content by key.
static func update_by_key(key: String, data = null, new_key = null, properties = null, name = null) -> GotmContent:
	return yield(_GotmContent.update_by_key(key, data, properties, new_key, name), "completed")

## Delete existing content by key.
static func delete_by_key(key: String) -> void:
	return yield(_GotmContent.delete_by_key(key), "completed")

## Get existing content's data as bytes.
static func get_data(content_or_id) -> PoolByteArray:
	return yield(_GotmContent.fetch(content_or_id, "data"), "completed")

## Get existing content's data as an instanced Node.
static func get_node(content_or_id) -> Node:
	return yield(_GotmContent.fetch(content_or_id, "node"), "completed")

## Get existing content's data as a Variant.
static func get_variant(content_or_id):
	return yield(_GotmContent.fetch(content_or_id, "variant"), "completed")

## Get existing content's properties.
static func get_properties(content_or_id):
	return yield(_GotmContent.fetch(content_or_id, "properties"), "completed")


## Get existing content's data as bytes by key.
static func get_data_by_key(key: String) -> PoolByteArray:
	return yield(_GotmContent.get_by_key(key, "data"), "completed")

## Get existing content's data as an instanced Node by key.
static func get_node_by_key(key: String) -> Node:
	return yield(_GotmContent.get_by_key(key, "node"), "completed")

## Get existing content's data as a Variant by key.
static func get_variant_by_key(key: String):
	return yield(_GotmContent.get_by_key(key, "variant"), "completed")

## Get existing content's properties bytes by key.
static func get_properties_by_key(key: String) -> Dictionary:
	return yield(_GotmContent.get_by_key(key, "properties"), "completed")

## Use complex filtering with a GotmQuery instance.
## For example, calling yield(GotmContent.list(GotmQuery.new().filter("properties/difficulty", "hard").sort("created")), "completed")
## would fetch the latest created contents whose "properties" field contains {"difficulty": "hard"}.
##
## @param query List contents according to the filters and sorts of the GotmQuery instance.
## @param after_content_or_id List contents that come after a previously listed content.
## 
## The following keywords can be used to filter or sort contents:
## * properties/*: Any value within the content's properties field. For example, if a content's "properties" 
## field equals {"level": {"difficulty": "hard"}}, then a keyword of "properties/level/difficulty" refers to 
## the nested "difficulty" field. Contents that lack the keyword are excluded from the fetched results.
## * key: The content's key field.
## * name: The content's name field.
## * user_id: The content's user_id field.
## * blob_id: The content's blob_id field.
## * is_private: The content's is_private field. If filtering on a true value, a user_id filter on the current
## user's id is implicitly added. For example, doing GotmQuery.new().filter("is_private", true) would result
## in GotmQuery.new().filter("is_private", true).filter("user_id", Gotm.user.id). This is because a user
## is not permitted to view another user's private contents.
## * is_local: The content's is_local field.
## * parent_ids: Array of ids of contents that are parents to the content. All contents that has all of the 
## provided ids as parents are included in the list. For example, filtering with a parent_ids value of [a, b]
## would include all content that have a and b as parents, such as [a, b, c] and [a, b], but not [a], [b] or [a, c].
## * directory: The "directory" of the content's key field. For example,
## if a content's key is "a/b/c", then its directory is "a/b".
## * extension: The "extension" of the content's key field. For example,
## if a content's key is "a/b/c.txt", then its extension is "txt".
## * name_part: Used for partial name search. For example, doing
## GotmQuery.new().filter("name_part", "garlic") would match all contents
## whose names contain "garlic". Does not support GotmQuery.filter_min, GotmQuery.filter_max or GotmQuery.sort.
## * score: The number of upvotes minus the number of downvotes a content has gotten. Does not support GotmQuery.filter.
## * updated: The content's updated field. Does not support GotmQuery.filter.
## * created: The content's created field. Does not support GotmQuery.filter.
## * size: The size of the data stored by the content. Does not support GotmQuery.filter.
##
## There is no limit to how many times you use GotmQuery.filter in a single query. However, some limitations apply to GotmQuery.filter_min, 
## GotmQuery.filter_max and GotmQuery.sort, which you can read about below.
##
## Limitations:
## * The following keywords do not support GotmQuery.filter_min, GotmQuery.filter_max or GotmQuery.sort: name_part
## * The following keywords do not support GotmQuery.filter: score, updated, created, size
## * Contents can only be sorted by one keyword. For example, doing GotmQuery.new().sort("name").sort("key") would
## sort the contents by key only, because it appeared last.
## * GotmQuery.filter_min and GotmQuery.filter_max can only be used on the same keyword as GotmQuery.sort. For example,
## doing GotmQuery.new().filter_min("key", "a").filter_min("created", 0).sort("created") would result in 
## GotmQuery.new().filter_min("created", 0).sort("created").
static func list(query = GotmQuery.new(), after_content_or_id = null) -> Array:
	return yield(_GotmContent.list(query, after_content_or_id), "completed")
