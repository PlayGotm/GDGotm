class_name GotmLeaderboard
#warnings-disable

## BETA FEATURE
##
## Used for fetching ranks and scores.
## You do not need to create a leaderboard before creating scores.
##
## @tutorial: https://gotm.io/docs/leaderboard


##############################################################
# PROPERTIES
##############################################################

## Required. Filters by score name.
## For example, a name of "bananas_collected" will only fetch scores with the 
## same name.
var name: String = ""

## Optionally filter by score properties.
## For example, {level: "desert1"} will only fetch scores that has the same 
## value for that level, such as {level: "desert1", difficulty: "hard"} and
## {level: "desert1"}, but not {level: "snow1", difficulty: "hard"} or
## {difficulty: "hard"}.
var properties: Dictionary = {}

## Optionally filter by unique scores per user.
## If a user has multiple score entries, only the last created one will be 
## fetched. For example if a user created scores of 5 and then 2, the fetched 
## scores will only be 2.
var is_unique: bool = false

## Optionally invert the rank order.
## If true, a lower score value means a higher rank.
## If false, a higher score value means a higher rank.
var is_inverted: bool = false

## Optionally rank older scores higher than newer scores with the same value.
## If true, an older score will have a higher rank than newer scores with the same value.
## If false, an older score will have a lower rank than newer scores with the same value.
var is_oldest_first: bool = false

## Optionally filter by when scores were created.
## For example, GotmPeriod.sliding(GotmPeriod.TimeGranularity.WEEK) will only
## fetch scores created the last 7 days.
var period: GotmPeriod = GotmPeriod.all()

## Optionally filter by user.
## When set, only the scores that belong to that user will be fetched.
var user_id: String = ""

## Optionally only fetch local scores.
## If true, only fetch scores created with GotmScore.create_local and which are
## only stored locally on the user's device.
var is_local: bool = false


##############################################################
# METHODS
##############################################################

## Get the rank among all scores that match the filters of this leaderboard.
## Ranks start at 1.
## For example, if Score1 has value 5 and Score2 has value 6, then Score1 
## would have rank 2 and Score2 would have rank 1.
##
## @param score_or_score_id_or_value 
## If a GotmScore instance, get the rank of that score.
## If a score id (string), get the rank of the score with that id. 
## If a value (int or float), get the rank a score would have if it would have that value.
func get_rank(score_or_score_id_or_value) -> int:
	return yield(_GotmScore.get_rank(self, score_or_score_id_or_value), "completed")

## Fetch up to 20 scores that match the filters of this leaderboard sorted
## by their values in descending order (highest value first).
##
## @param after_score_or_score_id_or_value 
## If provided, fetch the scores that come after. 
## If a GotmStore instance, fetch the scores that come after that score.
## If a score id (string), fetch the scores that come after the score with that id.
## If a value (int or float), fetch the scores whose values come after that value.
##
## @param ascending
## If true, sort in ascending order (lowest value first).
func get_scores(after_score_or_score_id_or_value = null, ascending: bool = false) -> Array:
	return yield(_GotmScore.list(self, after_score_or_score_id_or_value, ascending), "completed")

## Same as "get_scores" above, but if "after_score_or_score_id_or_rank" is a a rank (int or float), fetch
## the scores after that rank.
func get_scores_by_rank(after_score_or_score_id_or_rank = null, ascending: bool = false) -> Array:
	return yield(_GotmScore.list_by_rank(self, after_score_or_score_id_or_rank, ascending), "completed")

## Fetch up to 20 scores before and up to 20 scores after a particular place in the leaderboard.
##
## @param score_or_score_id_or_value
## If a GotmStore instance, fetch the scores surrounding that score.
## If a score id (string), fetch the scores surrounding the score with that id.
## If a value (int or float), fetch the scores surrounding the score with that value
## or the closest score with lower value.
func get_surrounding_scores(score_or_score_id_or_value) -> SurroundingScores:
	return yield(_GotmLeaderboard.get_surrounding_scores(self, score_or_score_id_or_value), "completed")

## Same as "get_surrounding_scores" above, but if "score_or_score_id_or_rank" is a rank (int or float), fetch
## scores surrounding the score with that rank.
func get_surrounding_scores_by_rank(score_or_score_id_or_rank, ascending: bool = false) -> SurroundingScores:
	return yield(_GotmLeaderboard.get_surrounding_scores_by_rank(self, score_or_score_id_or_rank), "completed")

## Get the number of scores that match this leaderboard.
func get_count() -> int:
	return yield(get_counts(null, null, 1), "completed")[0]

## Get the number of scores that match this leaderboard within the provided value range.
## Useful for distribution graphs.
## For example, if there are scores with values 1, 2 and 3, then calling
## GotmLeaderboard.get_score_counts(1, 3, 4) will return an array of  1, 0, 1 and 1, 
## because there is 1 score in the range [1, 1.5), 0 in  [1.5, 2), 1 in [2, 2.5) 
## and 1 in [2.5, 3], where ")" is exclusive.
## Calling GotmLeaderboard.get_score_counts(1, 3, 1) would return an array with only a 3, 
## because there are 3 scores in the range [1, 3].
##
## @param minimum_value
## Count the number of scores with values that are equal to or greater than a minimum value.
##
## @param maximum_value
## Count the number of scores with values that are equal to or less than a minimum value.
##
## @param segment_count
## The number of segments, where each segment is the number of scores within that segment's
## value range. All segments have equally sized value ranges except the last segment which
## has an inclusive maximum value, whereas non-last segments have exclusive maximum values.
## For an example, see the function description above.
func get_counts(minimum_value = null, maximum_value = null, segment_count: int = 20) -> Array:
	return yield(_GotmScore.get_counts(self, minimum_value, maximum_value, segment_count), "completed")

##############################################################
# DATA STRUCTURES
##############################################################

## Rreturned by the "get_surrounding_scores" and "get_surrounding_scores_by_rank" functions.
class SurroundingScores:
	# Scores above "score" in descending order. The last element is the score above "score".
	var before: Array
	# The middle score
	var score: GotmScore
	# Scores below "score" in descending order. The first element is the score below "score".
	var after: Array
