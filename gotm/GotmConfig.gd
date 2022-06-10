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

# The project key gives your game access to Gotm's APIs and is bound to your game.
# You can create one in your game's Gotm dashboard (https://gotm.io/dashboard).
# If you don't specify a project key, the plugin will emulate Gotm's APIs locally.
#
# For example, if you specify a project key, all scores that you create with
# GotmScore.create will be saved persistently in the cloud. If you don't specify
# a project key, the scores will just be stored in your computer's local memory
# and will be wiped when you close the game.
var projectKey: String = ""

# The Scores API is a beta feature and is always emulated when Gotm.is_live is false.
# If true, the API is emulated even when a project key is provided Gotm.is_live is true.
var emulateScoresApi: bool = false
