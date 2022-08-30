class_name _GotmImplUtility
#warnings-disable


static func _fuzzy_compare(a, b, compare_less: bool) -> bool:
	if typeof(a) == typeof(b):
		return a < b if compare_less else a > b
		
	# GDScript doesn't handle comparison of different types very well.
	# Abuse Array's min and max functions instead.
	var m = [a, b].min() if compare_less else [a, b].max()
	if m != null || a == null || b == null:
		return m == a
			
	# Array method failed. Go with strings instead.
	a = String(a)
	b = String(b)
	return a < b if compare_less else a > b


static func is_less(a, b) -> bool:
	return _fuzzy_compare(a, b, true)


static func is_greater(a, b) -> bool:
	return _fuzzy_compare(a, b, false)
