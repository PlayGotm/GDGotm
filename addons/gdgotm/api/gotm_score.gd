class_name GotmScore


## A score entry used for leaderboards.
##
## To fetch ranks and scores, see the GotmLeaderboard class.
##
## [br][br] [b][u]Creating a GotmScore[/u][/b]
## [br] When creating scores, you need to provide two things to the [method create] function:
## [br] 1. A score [member name] which describes what the score represents, for example "bananas_collected" or "time_elapsed".
## [br] 2. A score [member value] which describes how much the score is worth compared to other scores with the same name.
## [br] Optionally, you can also pass [member properties] that can be used as filters when fetching with a [GotmLeaderboard]
## [codeblock]
## var score_name := "bananas_collected"
## var score1: GotmScore = await GotmScore.create(score_name, 1)
## var score2 := await GotmScore.create("bananas_collected", 2)
## var score3 := await GotmScore.create("time_elapsed", 220.5, {level: "desert1", difficulty: "hard"})
## [/codeblock]
## [br] If you want to create local device scores, use [method create_local] instead.
##
## [br][br] [b][u]Updating a GotmScore[/u][/b]
## [br] To update a score, you can either use a [GotmScore] or a [member GotmScore.id].
## [br] You can update either value, properties, or both.
## [codeblock]
## # intial score of 5 in hard difficulty
## var score := await GotmScore.create("bananas_collected", 5, {difficulty: "hard"})
## # update score to 20 with a GotmScore parameter
## score = await GotmScore.update(score, 20)
## # update difficulty to normal with a GotmScore.id parameter
## score = await GotmScore.update(score.id, null, {difficulty: "normal"}) # score is still 20
## # update both score and difficulty
## score = await GotmScore.update(score, 100, {difficulty: "easy"})
## [/codeblock]
##
## [br][br] [b][u]Deleting a GotmScore[/u][/b]
## [br] To delete a score, you can either use a [GotmScore] or a [member GotmScore.id].
## [codeblock]
## var score1 := await GotmScore.create("time_elapsed", 45.67)
## var score2 := await GotmScore.create("time_elapsed", 30.25)
## await GotmScore.delete(score1) # deletes score1
## await GotmScore.delete(score2.id) # deltes score2
## [/codeblock]
##
## @tutorial(Leaderboard Tutorial): https://gotm.io/docs/leaderboard
##
##


##############################################################
# PROPERTIES
##############################################################

## Unique immutable identifier.
var id: String

## Unique identifier of the user who owns the score.
## Is automatically set to the current user's id when creating the score.
## If the score is created while the game runs outside gotm.io, this user will 
## always be an unregistered user with no display name.
## If the score is created while the game is running on Gotm with a signed in
## user, you can get their display name via GotmUser.fetch.
var user_id: String

## A name that describes what this score represents and puts it in a category.
## For example, "bananas_collected".
var name: String

## A numeric representation of the score.
var value: float

## Optional metadata to attach to the score entry, 
## for example {level: "desert1", difficulty: "hard"}.
## When fetching ranks and scores with GotmLeaderboard, you can optionally 
## filter with these properties. 
var properties: Dictionary

## Is true if this score was created with GotmScore.create_local and is only stored locally on the user's device.
## Is useful for scores that do not need to be accessible to other devices, such as scores in an offline game.
var is_local: bool

## UNIX epoch time (in milliseconds). Use Time.get_datetime_string_from_unix_time(score.created) to convert to date.
var created: int

##############################################################
# METHODS
##############################################################

## Create a score entry for the current user.
## Scores can be fetched via a GotmLeaderboard instance.
## See PROPERTIES above for descriptions of the arguments.
static func create(name: String, value: float, properties: Dictionary = {}) -> GotmScore:
	return await _GotmScore.create(name, value, properties, false)

## Create a score that is only stored locally on the user's device. Local scores are not accessible to any other player or device.
static func create_local(name: String, value: float, properties: Dictionary = {}) -> GotmScore:
	return await _GotmScore.create(name, value, properties, true)

## Update an existing score. Note: Only the score owner can update the score.
## Null is ignored.
static func update(score_or_id, value = null, properties = null) -> GotmScore:
	return await _GotmScore.update(score_or_id, value, properties)

## Delete an existing  score. Note: Only the score owner can delete the score.
static func delete(score_or_id) -> bool:
	return await _GotmScore.delete(score_or_id)

## Get an existing score.
static func fetch(score_or_id) -> GotmScore:
	return await _GotmScore.fetch(score_or_id)


##############################################################
# PRIVATE
##############################################################

const _CLASS_NAME := "GotmScore"
