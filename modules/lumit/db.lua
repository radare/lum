local JSON = require ("json")
local FS = require ("fs")

-- helper
local io = require ("io")

function slurp(x)
	local fh = io.open (x, "r")
	if not fh then return nil end
	local c = ""
	while true do
		line = fh.read (fh)
		if not line then break end
		c = c..line.."\n"
	end
	return c
end

-- db package --
local DB = {}

-- TODO: fetch and load this database from a server
-- database from pancake
local dbinternal = [[
[
  { "name": "json", "type": "git", "url": "git://github.com/radare/luvit-JSON",
    "version": "0.1", "description": "pure lua json library", "author": "pancake" },
  { "name": "sdb", "type": "git", "url": "git://github.com/radare/luvit-sdb",
    "version": "0.1", "description": "sdb bindings", "author": "pancake" },
  { "name": "irc", "type": "git", "url": "git://github.com/radare/luvit-irc",
    "version": "0.1", "description": "irc client library", "author": "pancake" },
  { "name": "crypto", "type": "git", "url": "git://github.com/radare/crypto",
    "version": "0.1", "description": "openssl crypto api", "author": "pancake" },
  { "name": "template", "type": "git", "url": "git://github.com/radare/luvit-template",
    "version": "0.1", "description": "template module", "author": "pancake" },
  { "name": "kernel", "type": "git", "url": "git://github.com/luvit/kernel.git",
    "version": "0.0.1", "description": "A simple async template language similar to dustjs and mustache (ported from c9/kernel)", "author": "creationx" },
  { "name": "curl", "type": "git", "url": "git://github.com/luvit/curl.git",
    "version": "0.0.1", "description": "HTTP request for Luvit", "author": "dvv" } 
]
]]

function DB.update ()
	-- update database from remote server --
	-- TODO. copy from init.lua
end


function DB.open (fn)
	local t = {}
	t.db = {}
	t.db["internal"] = dbinternal

	for k,v in pairs (t.db) do
		local j = JSON.parse (t.db[k], {use_null=true})
		t.db[k] = j
	end

	local lumdir = process.env["HOME"] .. "/.lum/db"
	FS.readdir (lumdir, function (err, files)
		if err then
			p ("ERROR", "readdir ~/.lum/db is empty")
			print ("  REPOS=http://lolcathost.org/lum/pancake lum -S")
		else
			local ctr = #files
			for i=1, #files do
				if not (files[i]:sub(1,1) == ".") then
					local j = slurp (lumdir.."/"..files[i])
					local a, b = pcall (JSON.parse, j)
					if a then
						t.db[files[i]] = b --JSON.decode (j)
					else
						p (lumdir.."/"..files[i], b)
					end
				end
			end
		end
		t.find = function (self, x, r, fn)
			if not x then return end
			for k,v in pairs (t.db) do
				for K,V in pairs (t.db[k]) do
					if (not r or r == k) and self.db[k][K].name == x then
						fn (K, self.db[k][K])
						return
					end
				end
			end
			fn (nil)
		end

		t.search = function (self, x, fn)
			for k,v in pairs (t.db) do
				for K,V in pairs (t.db[k]) do
					local n = self.db[k][K].name
					local d = self.db[k][K].description
					if not x or n:find(x) or d:find(x) then
						fn (k, self.db[k][K])
					end
				end
			end
		end
		fn (t)
	end)
end
return DB
