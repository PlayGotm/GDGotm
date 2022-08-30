class_name _GotmQuery
#warnings-disable

static func filter(query, property_path: String, value):
	query.filters.append({"property_path": property_path, "value": value})
	return query
	
static func filter_min(query, property_path: String, value, is_exclusive: bool = false):
	query.filters.append({"property_path": property_path, "min_value": value, "is_min_exclusive": is_exclusive})
	return query

static func filter_max(query, property_path: String, value, is_exclusive: bool = false):
	query.filters.append({"property_path": property_path, "max_value": value, "is_max_exclusive": is_exclusive})
	return query

static func sort(query, property_path: String, ascending: bool = false):
	query.sorts.append({"property_path": property_path, "descending": !ascending})
	return query

static func copy(query):
	return create(query.filters.duplicate(true), query.sorts.duplicate(true))


static func _format_sort(sort):
	if !sort.get("property_path"):
		return
	var formatted = {}
	formatted.prop = sort.property_path
	if sort.get("descending"):
		formatted.descending = true
	return formatted

static func _format_filter(filter):
	if !filter.get("property_path"):
		return
		
	var formatted = {}
	formatted.prop = filter.property_path
	if filter.has("value"):
		formatted.value = filter.value
		return formatted
		
	if filter.has("min_value"):
		formatted.min = filter.min_value
		if filter.get("is_min_exclusive"):
			formatted.minExclusive = true
	if filter.has("max_value"):
		formatted.max = filter.max_value
		if filter.get("is_max_exclusive"):
			formatted.maxExclusive = true
	if formatted.size() <= 1:
		return
	return formatted

static func get_formatted(query):
	query = copy(query)
	var filters: Array = []
	var sorts: Array = []
	var duplicate_filters: Array = []
	var duplicate_sorts: Array = []
	for filter in query.filters:
		filter = _format_filter(filter)
		if filter:
			filters.append(filter)
	for sort in query.sorts:
		sort = _format_sort(sort)
		if sort:
			sorts.append(sort)
	if !sorts:
		var range_sort := ""
		for filter in filters:
			if filter.has("min") || filter.has("max"):
				range_sort = filter.prop
		if range_sort:
			sorts.append({"prop": range_sort, "descending": true})
	
	query.filters = filters
	query.sorts = sorts
	return query

static func create(filters: Array = [], sorts: Array = []):
	var query = _Gotm.create_instance("GotmQuery")
	query.filters = filters
	query.sorts = sorts
	return query

