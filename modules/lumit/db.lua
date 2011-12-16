local JSON = require ("./json")

local DB = {}
-- TODO: fetch and load this database from a server
local dbfoo = [[
[
  { "name": "json", "type": "git", "url": "git://github.com/radare/luvit-JSON",
    "version": "0.1", "description": "pure lua json library", "author": "pancake" },
  { "name": "sdb", "type": "git", "url": "git://github.com/radare/luvit-sdb",
    "version": "0.1", "description": "sdb bindings", "author": "pancake" },
  { "name": "irc", "type": "git", "url": "git://github.com/radare/luvit-irc",
    "version": "0.1", "description": "irc client library", "author": "pancake" },
  { "name": "crypto", "type": "git", "url": "git://github.com/radare/crypto",
    "version": "0.1", "description": "openssl crypto api", "author": "pancake" }
]
]]
function DB.open ()
	local t = {}
	t = JSON.decode (dbfoo)
	t.find = function (self, x, fn)
		if not x then return end
		for i = 1, #self do
			if self[i].name == x then
				fn (self[i])
				return
			end
		end
		fn (nil)
	end
	t.search = function (self, x, fn)
		for i = 1, #self do
			if not x or self[i].name:find(x) or self[i].description:find(x) then
				fn (self[i])
			end
		end
	end
	return t
end
return DB
