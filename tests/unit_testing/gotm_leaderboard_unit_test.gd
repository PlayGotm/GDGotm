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
	scores = await leaderboard.get_scores(score2, true)
	assert((scores[0] as GotmScore).id == score2.id)
	assert((scores[1] as GotmScore).id == score3.id)
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
