class_name GotmLobbyFetch
#warnings-disable

## Used for fetching non-hidden and non-locked lobbies.
##
## @tutorial: https://gotm.io/docs/lobby


##############################################################
# PROPERTIES
##############################################################
################
# Filter options
################
## If not empty, fetch lobbies whose 'Lobby.name' contains 'name'.
var filter_name: String = ""

## If not empty, fetch lobbies whose filterable custom properties
## matches those in 'filter_properties'.
##
## For example, setting 'filter_properties.difficulty = 2' will
## only fetch lobbies that have been set up with both 'lobby.set_property("difficulty", 2)'
## and 'lobby.set_filterable("difficulty", true)'.
##
## If your lobby has multiple filterable props, you must provide every filterable
## prop in 'filter_properties'. Setting a prop's value to 'null' will match any
## value of that prop.
var filter_properties: Dictionary = {}


################
# Sort options
################
## If not empty, sort by a sortable custom property.
##
## For example, setting 'sort_property = "difficulty"' will 
## only fetch lobbies that have been set up with both 'lobby.set_property("difficulty", some_value)'
## and 'lobby.set_sortable("difficulty", true)'.
##
## If your lobby has a sortable prop, you must always provide a 'sort_property'.
var sort_property: String = ""

## Sort results in ascending order?
var sort_ascending: bool = false

## If not null, fetch lobbies whose sort property's value is equal to or greater than 'sort_min'.
var sort_min = null

## If not null, fetch lobbies whose sort property's value is equal to or lesser than 'sort_max'.
var sort_max = null

## If true, and 'sort_min' is provided, exclude lobbies whose sort property's value is equal to 'sort_min'.
var sort_min_exclusive = false

## If true, and 'sort_max' is provided, exclude lobbies whose sort property's value is equal to 'sort_max'.
var sort_max_exclusive = false



##############################################################
# METHODS
##############################################################
# All these methods asynchronously fetch up to 8 non-hidden
# and non-locked lobbies.
#
# Modifying any filtering or sorting option resets the state of this
# 'GotmLobbyFetch' instance and causes the next fetch call to 
# fetch the first lobbies.
#
# All calls asynchronously return an array of fetched lobbies.
# Use 'yield(fetch.next(), "completed")' to retrieve it.


## Fetch the next lobbies, starting after the last lobby fetched
## in the previous call.
func next(count: int = 8) -> Array:
	return yield(_GotmImpl._fetch_lobbies(self, count, "next"), "completed")


## Fetch the previous lobbies, ending before the first lobby
## that was fetched in the previous call.
func previous(count: int = 8) -> Array:
	return yield(_GotmImpl._fetch_lobbies(self, count, "previous"), "completed")


## Fetch the first lobbies.
func first(count: int = 8) -> Array:
	return yield(_GotmImpl._fetch_lobbies(self, count, "first"), "completed")


## Fetch lobbies at the current position.
## Useful for refreshing lobbies without changing the page.
func current(count: int = 8) -> Array:
	return yield(_GotmImpl._fetch_lobbies(self, count, "current"), "completed")



##############################################################
# PRIVATE
##############################################################
var _impl: Dictionary = {}
