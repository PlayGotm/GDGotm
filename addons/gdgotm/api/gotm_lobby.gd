class_name GotmLobby

## GotmLobby lets you share a host's address in a public list, so that
## peers can discover multiplayer game sessions they can join.
##
## @tutorial: https://gotm.io/docs/lobby

##############################################################
# PROPERTIES
##############################################################

## Unique immutable identifier.
var id: String

## Optional name searchable with partial search.
var name: String

## Virtual IP address of the lobby's host.
## Is used to connect to the host via GotmMultiplayer.create_client.
var address: String

## Optional metadata to attach to the lobby, 
## for example {level: "desert1", "player_count": 3}.
## When listing lobbies with GotmLobby.list, you can optionally 
## filter and sort with these properties. 
var properties: Dictionary

## UNIX epoch time (in milliseconds). Use OS.get_datetime_from_unix_time(lobby.created / 1000) to convert to date.
var created: int

##############################################################
# METHODS
##############################################################

## Create a lobby.
## See PROPERTIES above for descriptions of the arguments.
static func create(name: String, properties: Dictionary = {})  -> GotmLobby:
	return await _GotmLobby.create(name, properties)


## Delete existing lobby.
static func delete(lobby_or_id) -> bool:
	return await _GotmLobby.delete(lobby_or_id)


## Get existing lobby.
static func fetch(lobby_or_id) -> GotmLobby:
	return await _GotmLobby.fetch(lobby_or_id)


## List lobbies using optional filtering and sorting.
## For example, calling [code]await GotmLobby.list("wonka", {"level": "desert"}, null)[/code]
## would fetch the first 20 lobbies whose names contain "wonka" and whose properties
## has a "level" field that equals "desert".
##
## By default lobbies are sorted by their created time in descending order, i.e. newest lobbies first.
## You can customize the sorting by providing the sort parameter.
## To get the newest 20 lobbies you can do the following:
## [codeblock]
## var sort := GotmQuery.Filter.new()
## sort.property_path = "created"
## var lobbies := GotmLobby.list(null, null, sort)
## [/codeblock]
## To get the next 20 lobbies, provide the last lobby of your previous result.
## [codeblock]
## var next_lobbies := GotmLobby.list(null, null, sort, lobbies.back())
## [/codeblock]
## Supported values for sort.property_path are:
## * created: The lobby's created field. Does not support GotmQuery.filter.
## * properties/*: Any value within the lobby's properties field. For example, if a lobby's "properties" 
## field equals {"level": {"difficulty": "hard"}}, then a keyword of "properties/level/difficulty" refers to 
## the nested "difficulty" field. Lobbies that lack the keyword are excluded from the fetched results.
## The sort.value property is ignored.
static func list(name = null, properties = null, sort: GotmQuery.Filter = null, ascending: bool = false, after_lobby_or_id = null) -> Array:
	return await _GotmLobby.list(name, properties, sort, ascending, after_lobby_or_id)


## Update existing lobby.
## Null is ignored.
static func update(lobby_or_id, new_name = null, new_properties = null) -> GotmLobby:
	return await _GotmLobby.update(lobby_or_id, new_name, new_properties)


##############################################################
# PRIVATE
##############################################################

const _CLASS_NAME := "GotmLobby"
