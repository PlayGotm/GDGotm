class_name GotmUnitTest_Leaderboard
extends Node


func test_leaderboard_get_count() -> GotmUnitTest.TestInfo:
	var rng_name: String = str(randi())
	var score1 := await GotmScore.create("test_get_count_" + rng_name, 1, {"foo":"bar"})
	assert(score1 != null)
	var score2 := await GotmScore.create("test_get_count_" + rng_name, 2, {"foo":"bar"})
	assert(score2 != null)
	var score3 := await GotmScore.create("test_get_count_" + rng_name, 3, {"foo":"bar"})
	assert(score3 != null)
	var leaderboard := GotmLeaderboard.new()
	leaderboard.name = "test_get_count_" + rng_name
	leaderboard.is_local = score1.is_local
	assert(await leaderboard.get_count() == 3)
	leaderboard.is_unique = true
	assert(await leaderboard.get_count() == 1)
	leaderboard.is_unique = false
	leaderboard.user_id = score1.user_id
	assert(await leaderboard.get_count() == 3)
	leaderboard.is_local = true
	var count := 0
	if score1.is_local: count += 1
	if score2.is_local: count += 1
	if score3.is_local: count += 1
	assert(await leaderboard.get_count() == count)
	leaderboard.is_local = score1.is_local
	leaderboard.properties = {"foo":"bar"}
	assert(await leaderboard.get_count() == 3)
	leaderboard.properties = {"foo1":"bar1"}
	assert(await leaderboard.get_count() == 0)
	if score1.is_local:
		return GotmUnitTest.TestInfo.new(false)
	return GotmUnitTest.TestInfo.new(true)


func test_leaderboard_get_counts() -> GotmUnitTest.TestInfo:
	var rng_name: String = str(randi())
	var score1 := await GotmScore.create("test_get_counts_" + rng_name, 1)
	assert(score1 != null)
	var score2 := await GotmScore.create("test_get_counts_" + rng_name, 2)
	assert(score2 != null)
	var score3 := await GotmScore.create("test_get_counts_" + rng_name, 3)
	assert(score3 != null)
	var leaderboard := GotmLeaderboard.new()
	leaderboard.name = "test_get_counts_" + rng_name
	leaderboard.is_local = score1.is_local
	assert(await leaderboard.get_counts(0, 4, 4) == [0, 1, 1, 1])
	if score1.is_local:
		return GotmUnitTest.TestInfo.new(false)
	return GotmUnitTest.TestInfo.new(true)


func test_leaderboard_get_rank() -> GotmUnitTest.TestInfo:
	var rng_name: String = str(randi())
	var score1 := await GotmScore.create("test_get_rank_" + rng_name, 1)
	assert(score1 != null)
	var score2 := await GotmScore.create("test_get_rank_" + rng_name, 2)
	assert(score2 != null)
	var score3 := await GotmScore.create("test_get_rank_" + rng_name, 3)
	assert(score3 != null)
	var leaderboard := GotmLeaderboard.new()
	leaderboard.name = "test_get_rank_" + rng_name
	leaderboard.is_local = score1.is_local
	assert(await leaderboard.get_rank(score3) == 1)
	assert(await leaderboard.get_rank(score2) == 2)
	assert(await leaderboard.get_rank(score1) == 3)
	if score1.is_local:
		return GotmUnitTest.TestInfo.new(false)
	return GotmUnitTest.TestInfo.new(true)


func test_leaderboard_get_scores() -> GotmUnitTest.TestInfo:
	var rng_name: String = str(randi())
	var score1 := await GotmScore.create("test_get_scores_" + rng_name, 1)
	assert(score1 != null)
	var score2 := await GotmScore.create("test_get_scores_" + rng_name, 2)
	assert(score2 != null)
	var score3 := await GotmScore.create("test_get_scores_" + rng_name, 3)
	assert(score3 != null)
	var leaderboard := GotmLeaderboard.new()
	leaderboard.name = "test_get_scores_" + rng_name
	leaderboard.is_local = score1.is_local
	var scores := await leaderboard.get_scores()
	assert((scores[0] as GotmScore).id == score3.id)
	assert((scores[1] as GotmScore).id == score2.id)
	assert((scores[2] as GotmScore).id == score1.id)
	scores = await leaderboard.get_scores(null, true)
	assert((scores[0] as GotmScore).id == score1.id)
	assert((scores[1] as GotmScore).id == score2.id)
	assert((scores[2] as GotmScore).id == score3.id)
	scores = await leaderboard.get_scores(score2)
	assert((scores[0] as GotmScore).id == score1.id)
	scores = await leaderboard.get_scores(score2)
	assert((scores[0] as GotmScore).id == score1.id)
	scores = await leaderboard.get_scores(score1)
	assert(scores.is_empty())
	if score1.is_local:
		return GotmUnitTest.TestInfo.new(false)
	return GotmUnitTest.TestInfo.new(true)


func test_leaderboard_get_scores_by_rank() -> GotmUnitTest.TestInfo:
	var rng_name: String = str(randi())
	var score1 := await GotmScore.create("test_get_scores_by_rank_" + rng_name, 1)
	assert(score1 != null)
	var score2 := await GotmScore.create("test_get_scores_by_rank_" + rng_name, 2)
	assert(score2 != null)
	var score3 := await GotmScore.create("test_get_scores_by_rank_" + rng_name, 3)
	assert(score3 != null)
	var leaderboard := GotmLeaderboard.new()
	leaderboard.name = "test_get_scores_by_rank_" + rng_name
	leaderboard.is_local = score1.is_local
	var scores := await leaderboard.get_scores_by_rank()
	assert((scores[0] as GotmScore).id == score3.id)
	assert((scores[1] as GotmScore).id == score2.id)
	assert((scores[2] as GotmScore).id == score1.id)
	scores = await leaderboard.get_scores_by_rank(null, true)
	assert((scores[0] as GotmScore).id == score1.id)
	assert((scores[1] as GotmScore).id == score2.id)
	assert((scores[2] as GotmScore).id == score3.id)
	scores = await leaderboard.get_scores_by_rank(2, true)
	assert((scores[0] as GotmScore).id == score3.id)
	scores = await leaderboard.get_scores_by_rank(2)
	assert((scores[0] as GotmScore).id == score1.id)
	scores = await leaderboard.get_scores_by_rank(1)
	assert((scores[0] as GotmScore).id == score2.id)
	assert((scores[1] as GotmScore).id == score1.id)
	if score1.is_local:
		return GotmUnitTest.TestInfo.new(false)
	return GotmUnitTest.TestInfo.new(true)


func test_leaderboard_get_surrounding_scores() -> GotmUnitTest.TestInfo:
	var rng_name: String = str(randi())
	var score1 := await GotmScore.create("test_get_surrounding_scores_" + rng_name, 1)
	assert(score1 != null)
	var score2 := await GotmScore.create("test_get_surrounding_scores_" + rng_name, 2)
	assert(score2 != null)
	var score3 := await GotmScore.create("test_get_surrounding_scores_" + rng_name, 3)
	assert(score3 != null)
	var leaderboard := GotmLeaderboard.new()
	leaderboard.name = "test_get_surrounding_scores_" + rng_name
	leaderboard.is_local = score1.is_local
	var scores := await leaderboard.get_surrounding_scores(2)
	assert(scores.score.id == score2.id)
	assert((scores.before[0] as GotmScore).id == score3.id)
	assert((scores.after[0] as GotmScore).id == score1.id)
	scores = await leaderboard.get_surrounding_scores(score2)
	assert(scores.score.id == score2.id)
	assert((scores.before[0] as GotmScore).id == score3.id)
	assert((scores.after[0] as GotmScore).id == score1.id)
	if score1.is_local:
		return GotmUnitTest.TestInfo.new(false)
	return GotmUnitTest.TestInfo.new(true)


func test_leaderboard_get_surrounding_scores_by_rank() -> GotmUnitTest.TestInfo:
	var rng_name: String = str(randi())
	var score1 := await GotmScore.create("test_get_surrounding_scores_by_rank_" + rng_name, 1)
	assert(score1 != null)
	var score2 := await GotmScore.create("test_get_surrounding_scores_by_rank_" + rng_name, 2)
	assert(score2 != null)
	var score3 := await GotmScore.create("test_get_surrounding_scores_by_rank_" + rng_name, 3)
	assert(score3 != null)
	var leaderboard := GotmLeaderboard.new()
	leaderboard.name = "test_get_surrounding_scores_by_rank_" + rng_name
	leaderboard.is_local = score1.is_local
	var scores := await leaderboard.get_surrounding_scores_by_rank(2)
	assert(scores.score.id == score2.id)
	assert((scores.before[0] as GotmScore).id == score3.id)
	assert((scores.after[0] as GotmScore).id == score1.id)
	if score1.is_local:
		return GotmUnitTest.TestInfo.new(false)
	return GotmUnitTest.TestInfo.new(true)


const TestUtility := preload("res://tests/unit_testing/test_utility.gd")
func test_all() -> GotmUnitTest.TestInfo:
	# Give our scores a descriptive name.
	# We need this later when fetching scores.
	var score_name := "bananas_collected"

	# Clear existing scores so the test runs the same every time.
	await GotmUnitTest_Leaderboard._clear_scores(score_name)

	# Create scores
	var score1: GotmScore = await GotmScore.create(score_name, 1)
	var score2: GotmScore = await GotmScore.create(score_name, 2)
	var score3: GotmScore = await GotmScore.create(score_name, 3)

	# Create leaderboard query.
	# You don't need to create a leaderboard before creating scores.
	var top_leaderboard = GotmLeaderboard.new()
	# Required. 
	# Only include scores in our "bananas_collected" category.
	top_leaderboard.name = score_name

	# Get top scores. 
	var top_scores = await top_leaderboard.get_scores()
	TestUtility.assert_resource_equality(top_scores, [score3, score2, score1])

	# Get scores above and below score2 in the leaderboard.
	var surrounding_scores = await top_leaderboard.get_surrounding_scores(score2)
	TestUtility.assert_resource_equality(surrounding_scores.before, [score3])
	TestUtility.assert_resource_equality(surrounding_scores.score, score2)
	TestUtility.assert_resource_equality(surrounding_scores.after, [score1])

	# Get scores above and below score2 in the leaderboard with id.
	var surrounding_scores_by_id = await top_leaderboard.get_surrounding_scores(score2.id)
	TestUtility.assert_resource_equality(surrounding_scores_by_id.before, [score3])
	TestUtility.assert_resource_equality(surrounding_scores_by_id.score, score2)
	TestUtility.assert_resource_equality(surrounding_scores_by_id.after, [score1])

	# Get scores above and below a certain value in the leaderboard.
	var surrounding_scores_by_value = await top_leaderboard.get_surrounding_scores(2.5)
	TestUtility.assert_resource_equality(surrounding_scores_by_value.before, [score3])
	TestUtility.assert_resource_equality(surrounding_scores_by_value.score, score2)
	TestUtility.assert_resource_equality(surrounding_scores_by_value.after, [score1])

	# Get scores above and below a certain rank in the leaderboard.
	var surrounding_scores_by_rank = await top_leaderboard.get_surrounding_scores_by_rank(2)
	TestUtility.assert_resource_equality(surrounding_scores_by_rank.before, [score3])
	TestUtility.assert_resource_equality(surrounding_scores_by_rank.score, score2)
	TestUtility.assert_resource_equality(surrounding_scores_by_rank.after, [score1])

	# Get scores below score2
	var scores_after_score = await top_leaderboard.get_scores(score2)
	TestUtility.assert_resource_equality(scores_after_score, [score1])

	# Get scores below score2 with id	
	var scores_after_score_id = await top_leaderboard.get_scores(score2.id)
	TestUtility.assert_resource_equality(scores_after_score_id, [score1])

	# Get scores with lower value than score2
	var scores_after_value = await top_leaderboard.get_scores(score2.value)
	TestUtility.assert_resource_equality(scores_after_value, [score1])

	# Get scores below rank 1
	var scores_after_rank = await top_leaderboard.get_scores_by_rank(1)
	TestUtility.assert_resource_equality(scores_after_rank, [score2, score1])

	# Get number of scores in leaderboard.
	var score_count = await top_leaderboard.get_count()
	TestUtility.assert_equality(score_count, 3)

	# Get number of scores in ranges  [0,1), [1,2), [2,3), and [3,4], where ")" is exlusive.
	# Useful for distribution graphs.
	var score_counts = await top_leaderboard.get_counts(0, 4, 4)
	TestUtility.assert_equality(score_counts, [0, 1, 1, 1])

	# Get rank of score3. Ranks start at 1.
	var rank_from_score_id = await top_leaderboard.get_rank(score3.id)
	TestUtility.assert_equality(rank_from_score_id, 1)

	# Get the rank a score would have if it would have a value of 2.5.
	var rank_from_value = await top_leaderboard.get_rank(2.5)
	TestUtility.assert_equality(rank_from_value, 2)

	# Invert the leaderboard query, so that a lower value means a higher rank.
	top_leaderboard.is_inverted = true
	var inverted_rank = await top_leaderboard.get_rank(score3.id)
	TestUtility.assert_equality(inverted_rank, 3)
	top_leaderboard.is_inverted = false

	# Invert the leaderboard query, so scores with a lower value come first.
	top_leaderboard.is_inverted = true
	var inverted_scores = await top_leaderboard.get_scores()
	TestUtility.assert_resource_equality(inverted_scores, [score1, score2, score3])
	top_leaderboard.is_inverted = false

	# Newer scores are ranked higher than older scores with the same value.
	var score1_copy: GotmScore = await GotmScore.create(score1.name, score1.value)
	var score1_copy_rank_with_newest_first = await top_leaderboard.get_rank(score1_copy)
	TestUtility.assert_equality(score1_copy_rank_with_newest_first, 3)

	# Make older scores rank higher than newer scores with the same value.
	top_leaderboard.is_oldest_first = true
	var score1_copy_rank_with_oldest_first = await top_leaderboard.get_rank(score1_copy)
	TestUtility.assert_equality(score1_copy_rank_with_oldest_first, 4)
	top_leaderboard.is_oldest_first = false
	await GotmScore.delete(score1_copy)

	# Update an existing score's value
	await GotmScore.update(score2, 5)
	top_scores = await top_leaderboard.get_scores()
	TestUtility.assert_resource_equality(top_scores, [score2, score3, score1])

	# Delete a score.
	await GotmScore.delete(score2)
	top_scores = await top_leaderboard.get_scores()
	TestUtility.assert_resource_equality(top_scores, [score3, score1])

	# Get scores by properties
	await GotmScore.update(score1, null, {"difficulty": "hard", "level": 25})
	top_leaderboard.properties = {"difficulty": "hard"}
	TestUtility.assert_resource_equality(await top_leaderboard.get_scores(), [score1])
	top_leaderboard.properties = {}

	# Get last created score per user
	top_leaderboard.is_unique = true
	TestUtility.assert_resource_equality(await top_leaderboard.get_scores(), [score3])
	top_leaderboard.is_unique = false

	# Get scores from last 24 hours
	top_leaderboard.period = GotmPeriod.sliding(GotmPeriod.TimeGranularity.DAY)
	TestUtility.assert_resource_equality(await top_leaderboard.get_scores(), top_scores) ###
	top_leaderboard.period = GotmPeriod.all()

	# Get scores from today
	top_leaderboard.period = GotmPeriod.offset(GotmPeriod.TimeGranularity.DAY, 0)
	TestUtility.assert_resource_equality(await top_leaderboard.get_scores(), top_scores)
	top_leaderboard.period = GotmPeriod.all()

	# Get scores from two days ago
	top_leaderboard.period = GotmPeriod.offset(GotmPeriod.TimeGranularity.DAY, -2)
	TestUtility.assert_resource_equality(await top_leaderboard.get_scores(), [])
	top_leaderboard.period = GotmPeriod.all()

	# Get scores from February 2019
	top_leaderboard.period = GotmPeriod.at(GotmPeriod.TimeGranularity.MONTH, 2019, 2)
	TestUtility.assert_resource_equality(await top_leaderboard.get_scores(), [])
	top_leaderboard.period = GotmPeriod.all()

	# Create local score that is only stored locally on the user's device.
	var local_score = await GotmScore.create_local(score_name, 1)
	top_leaderboard.is_local = true
	if score1.is_local:
		# If score1 is local, then GotmScore is in local mode and all scores will be local.
		TestUtility.assert_resource_equality(await top_leaderboard.get_scores(), [score3, local_score, score1])
	else:
		# If score1 is not local, then GotmScore is not in local mode and only local_score will be local.
		TestUtility.assert_resource_equality(await top_leaderboard.get_scores(), [local_score])		
	top_leaderboard.is_local = false

	# If the score was created with a signed in user on Gotm, get the display name.
	var user: GotmUser = await GotmUser.fetch(score1.user_id)
	if user:
		# User is a registered Gotm user and has a display name.
		# Access it with the user.display_name field.
		pass 
	else:
		# User is not registered and has no display name.
		pass 

	return GotmUnitTest.TestInfo.new(!Gotm.project_key)


static func _clear_scores(score_name: String):
	var existing_leaderboard = GotmLeaderboard.new()
	existing_leaderboard.name = score_name
	var existing_scores = await existing_leaderboard.get_scores()
	for score in existing_scores:
		await GotmScore.delete(score)
	existing_leaderboard.is_local = true
	var local_existing_scores = await existing_leaderboard.get_scores()
	for score in local_existing_scores:
		await GotmScore.delete(score)
