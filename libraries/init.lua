-- libraries/init.lua
-- Central loader for all third-party libraries
--
-- This file provides a single require point for all external libraries.
-- Usage: local libs = require("libraries.init")
--        local bump = libs.bump
--        local camera = libs.camera

local path = (...):gsub('%.init$', '')

local libraries = {}

-- Load bump.lua - AABB collision detection library (v3.1.7)
-- Repository: https://github.com/kikito/bump.lua
-- License: MIT
libraries.bump = require(path .. '.bump')

-- Load anim8 - Sprite animation library
-- Repository: https://github.com/kikito/anim8
-- License: MIT
libraries.anim8 = require(path .. '.anim8')

-- Load hump.camera - Camera system
-- Repository: https://github.com/vrld/hump
-- License: MIT
libraries.camera = require(path .. '.camera')

-- Load json.lua - JSON encoding/decoding
-- Repository: https://github.com/rxi/json.lua
-- License: MIT
libraries.json = require(path .. '.json')

return libraries
