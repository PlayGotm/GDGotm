class_name _GotmQuery


static func copy(query: GotmQuery) -> GotmQuery:
	return create(query.filters.duplicate(true), query.sorts.duplicate(true))


static func create(filters: Array = [], sorts: Array = []) -> GotmQuery:
	var query = GotmQuery.new()
	query.filters = filters
	query.sorts = sorts
	return query


static func filter(query: GotmQuery, property_path: String, value) -> GotmQuery:
	query.filters.append({"property_path": property_path, "value": value})
	return query


static func filter_max(query: GotmQuery, property_path: String, value, is_exclusive: bool = false) -> GotmQuery:
	query.filters.append({"property_path": property_path, "max_value": value, "is_max_exclusive": is_exclusive})
	return query


static func filter_min(query: GotmQuery, property_path: String, value, is_exclusive: bool = false) -> GotmQuery:
	query.filters.append({"property_path": property_path, "min_value": value, "is_min_exclusive": is_exclusive})
	return query


static func _format_filter(_filter: Dictionary) -> Dictionary:
	if _filter.get("property_path").is_empty():
		return {}
	var formatted = {}
	formatted.prop = _filter.property_path
	if _filter.has("value"):
		formatted.value = _filter.value
		return formatted
	if _filter.has("min_value"):
		formatted.min = _filter.min_value
		if _filter.get("is_min_exclusive"):
			formatted.minExclusive = true
	if _filter.has("max_value"):
		formatted.max = _filter.max_value
		if _filter.get("is_max_exclusive"):
			formatted.maxExclusive = true
	if formatted.size() <= 1:
		return {}
	return formatted


static func _format_sort(_sort: Dictionary) -> Dictionary:
	if _sort.get("property_path").is_empty():
		return {}
	var formatted = {}
	formatted.prop = _sort.property_path
	if _sort.get("descending"):
		formatted.descending = true
	return formatted


static func get_formatted(query: GotmQuery) -> GotmQuery:
	query = copy(query)
	var filters: Array = []
	var sorts: Array = []
	for _filter in query.filters:
		_filter = _format_filter(_filter)
		if _filter:
			filters.append(_filter)
	for _sort in query.sorts:
		_sort = _format_sort(_sort)
		if _sort:
			sorts.append(_sort)
	if sorts.is_empty():
		var range_sort := ""
		for _filter in filters:
			if _filter.has("min") || _filter.has("max"):
				range_sort = _filter.prop
		if range_sort:
			sorts.append({"prop": range_sort, "descending": true})
	query.filters = filters
	query.sorts = sorts
	return query


static func sort(query: GotmQuery, property_path: String, ascending: bool = false) -> GotmQuery:
	query.sorts.append({"property_path": property_path, "descending": !ascending})
	return query
