func test_score_create() -> UnitTestInfo:
	var score := await GotmScore.create("test_create", 1)
	assert(score != null)
	var fetched_score = await GotmScore.fetch(score.id)
	assert(fetched_score != null)
	if fetched_score.is_local:
		return UnitTestInfo.new(false)
	return UnitTestInfo.new(true)


func test_score_create_local() -> UnitTestInfo:
	var score := await GotmScore.create_local("test_create_local", 1)
	assert(score != null)
	var fetched_score = await GotmScore.fetch(score.id)
	assert(fetched_score != null)
	assert(fetched_score.is_local == true)
	return UnitTestInfo.new(false)


func test_score_update() -> UnitTestInfo:
	var score := await GotmScore.create("test_update", 1)
	assert(score != null)
	var updated_score = await GotmScore.update(score.id, 2)
	assert(updated_score != null)
	assert(updated_score.value == 2)
	var fetched_score = await GotmScore.fetch(score.id)
	assert(fetched_score != null)
	assert(fetched_score.value == 2)
	updated_score = await GotmScore.update(score.id, null, {"foo":"bar"})
	assert(updated_score != null)
	assert(updated_score.value == 2)
	assert(updated_score.properties == {"foo":"bar"})
	fetched_score = await GotmScore.fetch(score.id)
	assert(fetched_score != null)
	assert(fetched_score.value == 2)
	assert(fetched_score.properties == {"foo":"bar"})
	if score.is_local:
		return UnitTestInfo.new(false)
	return UnitTestInfo.new(true)


func test_score_delete() -> UnitTestInfo:
	var score := await GotmScore.create("test_delete", 1)
	assert(score != null)
	var fetched_score = await GotmScore.fetch(score.id)
	assert(fetched_score != null)
	var deleted = await GotmScore.delete(score.id)
	assert(deleted == true)
	Engine.print_error_messages = false
	fetched_score = await GotmScore.fetch(score.id)
	Engine.print_error_messages = true
	assert(fetched_score == null)
	if score.is_local:
		return UnitTestInfo.new(false)
	return UnitTestInfo.new(true)


func test_score_fetch() -> UnitTestInfo:
	return await test_score_create()
