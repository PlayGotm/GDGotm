![PlayGotM](https://avatars1.githubusercontent.com/u/60827502?s=200&v=4)

# Official GDScript API for games on gotm.io

This plugin serves as a polyfill when developing against the API locally. The API is currently in its infancy and only exposes basic user information.

The 'real' API calls are only available when running the game live on gotm.io.

## Installation

You can install the plugin from the AssetLib in the Godot Editor. You can also install it by downloading its zip directly [here](https://github.com/PlayGotM/GDGotm/archive/master.zip) and extracting its content into your project's directory.

Add Gotm.gd to your autoloads at "Project Settings -> AutoLoad". Make sure the global autoload is named "Gotm". It must be named "Gotm" for it to work.
