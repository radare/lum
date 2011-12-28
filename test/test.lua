#!/usr/bin/env luvit

local JSON = require ("json")
p(JSON.encode ({"Hello","World"}))

local SDB = require ("sdb")
local db = SDB.open () --nil, false)
db:set ("foo", 33)
db:sync ()
db:close ()
