class_name Gotm

## This is the entrypoint to GDGotm.
##
## Add this script as a global autoload. Make sure the global autoload is named 
## "Gotm". It must be named "Gotm" for it to work.
##
## @tutorial: https://gotm.io/docs/gdgotm

# TODO: We might not need this class anymore? Looks like almost all functionality has been move elsewhere.


##############################################################
# METHODS
##############################################################

## Initialize GDGotm with the provided configuration.
## See GotmConfig for more details.
static func initialize(config: GotmConfig = GotmConfig.new()) -> void: # TODO: Maybe move this to GotmConfig?
	_Gotm.initialize(config)


static func get_config() -> GotmConfig:
	return _GotmUtility.copy(_Gotm.get_config(), GotmConfig.new()) # TODO: Maybe move this to GotmConfig?


##############################################################
# PRIVATE
##############################################################

const _CLASS_NAME := "Gotm"
