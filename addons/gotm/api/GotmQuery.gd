class_name GotmQuery


## A GotmQuery is used for complex filtering and sorting when fetching 
## Gotm resources, such as GotmContent.

## The current state of filters for this query. Is an array of Filter objects.
var filters: Array = []
## The current state of sorts for this query. Is an array of Sort objects.
var sorts: Array = []


## Make a deep copy of this GotmQuery instance.
func copy() -> GotmQuery:
	return _GotmQuery.copy(self)


## Create a query directly from filters and sorts.
## Filters is an array of Filter objects.
## Sorts is an array of Sort objects.
##
## For example, doing [code]GotmQuery.create([{"property_path": "name", value: "my_name"}, [{"property_path": "created"}])[/code]
## would fetch only things whose name equals [code]"my_name"[/code] sorted by creation date in descending order (newest first).
## It is the same as doing [code]GotmQuery.new().filter("name", "my_name").sort("created")[/code].
static func create(filters: Array = [], sorts: Array = []) -> GotmQuery:
	return _GotmQuery.create(filters, sorts)


## Fetch only things where the property_path's property equals the specified value.
func filter(property_path: String, value) -> GotmQuery:
	return _GotmQuery.filter(self, property_path, value)


## Fetch only things where the property_path's property is less than or equal to
## the specified value.
## If is_exclusive is true, fetch only things where the property_path's property is 
## less than the specified value.
func filter_max(property_path: String, value, is_exclusive: bool = false) -> GotmQuery:
	return _GotmQuery.filter_max(self, property_path, value, is_exclusive)


## Fetch only things where the property_path's property is greater than or equal to
## the specified value.
## If is_exclusive is true, fetch only things where the property_path's property is 
## greater than the specified value.
func filter_min(property_path: String, value, is_exclusive: bool = false) -> GotmQuery:
	return _GotmQuery.filter_min(self, property_path, value, is_exclusive)


## Sort results by the value of the property_path's property in descending order (highest value first).
## If ascending is true, sort in ascending order (lowest value first).
func sort(property_path: String, ascending: bool = false) -> GotmQuery:
	return _GotmQuery.sort(self, property_path, ascending)


## Represents a filter created by a call to GotmQuery.filter, GotmQuery.filter_min or GotmQuery.filter_max.
class Filter:  # TODO This is not implemented, either implement properly, or delete?
## The path of the property to apply the filter to.
	var property_path: String
## Value which the property must be equal to.
	var value = null
## Value which the property must be greater than or equal to.
	var min_value = null
## Value which the property must be lesser than or equal to.
	var max_value = null
## If true, the property's value  must be greater than min_value.
	var is_min_exclusive: bool = false
## If true, the proeprty's value must be lesser than max_value.
	var is_max_exclusive: bool = false

## Represents a sort created by a call to GotmQuery.sort.
class Sort: # TODO This is not implemented, either implement properly, or delete?
## The path of the property to sort by.
	var property_path: String
## If true, sort in ascending order so that the lowest value comes first.
	var ascending: bool = false


##############################################################
# PRIVATE
##############################################################

const _CLASS_NAME := "GotmQuery"
