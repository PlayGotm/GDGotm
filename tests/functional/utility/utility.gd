static func auth_to_string(auth: GotmAuth) -> String:
	var result := "\nGotmUser:\n"
	result += "[user_id] " + auth.user_id + "\n"
	result += "[is_registered] " + str(auth.is_registered) + "\n"
	return result


static func content_to_string(content: GotmContent) -> String:
	var result := "\nGotmContent:\n"
	result += "[id] %s\n" % content.id
	result += "[user_id] %s\n" % content.user_id
	result += "[created] %s\n" % Time.get_datetime_string_from_unix_time(content.created)
	result += "[is_local] %s\n" % str(content.is_local)
	result += "[is_private] %s\n" % str(content.is_private)
	result += "[key] %s\n" % content.key
	result += "[name] %s\n" % content.name
	result += "[parent_ids] %s\n" % str(content.parent_ids)
	result += "[properties] %s\n" % content.properties
	result += "[size] %d\n" % content.size
	result += "[updated] %s\n" % Time.get_datetime_string_from_unix_time(content.updated)
	return result


static func score_to_string(score: GotmScore) -> String:
	var result := "\nGotmScore:\n"
	result += "[name] " + score.name + "\n"
	result += "[value] " + str(score.value) + "\n"
	result += "[id] " + score.id + "\n"
	result += "[user_id] " + score.user_id + "\n"
	@warning_ignore("integer_division")
	var created := Time.get_datetime_string_from_unix_time(score.created)
	result += "[created] " + created  + "\n"
	result += "[is_local] " + str(score.is_local) + "\n"
	result += "[properties] " + str(score.properties) + "\n"
	return result


static func user_to_string(user: GotmUser) -> String:
	var result := "\nGotmUser:\n"
	result += "[name] " + user.name + "\n"
	result += "[id] " + user.id + "\n"
	return result
