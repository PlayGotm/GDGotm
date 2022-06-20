# MIT License
#
# Copyright (c) 2020-2022 Macaroni Studios AB
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

class_name GotmConfig
#warnings-disable

# The project key gives your game access to Gotm's cloud and lets you share data
# between players, for example scores and leaderboards. You can create a key in 
# your game's Gotm dashboard (https://gotm.io/dashboard).
# If you don't specify a project key, the plugin will not use Gotm's cloud and all
# data is only saved locally on the device your game is running on.
#
# For example, if you specify a project key, all scores that you create with
# GotmScore.create will be saved in the cloud and will be visible to other players. 
# If you don't specify a project key, the scores will only be stored in the local
# storage of the device the game is running on, and will not be visible to other
# players.
var project_key: String = ""

# Scores and Leaderboards are currently beta features and are always local when 
# Gotm.is_live is false.
# If true, the features are local even if a project key is provided.
var forceLocalScores: bool = false

# Scores and Leaderboards are currently beta features and are always local when 
# Gotm.is_live is false.
# If true and a project key is provided, the features are made global even if 
# Gotm.is_live is false.
#
# UNSAFE NOTICE: Enabling global mode on beta features when your game is running
# outside of https://gotm.io is not safe and is at your own risk. Your game may 
# break if new backwards-incompatible versions of the beta features are released.
var betaUnsafeForceGlobalScores: bool = false
