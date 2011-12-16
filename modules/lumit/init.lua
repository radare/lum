-- copyleft -- 2011 -- pancake<nopcode.org> --

local FS = require ("fs")
local DB = require ("./db")
local Stack = require ("./stack")
local System = require ("./system")

local Lumit = {}

function Lumit.update(self)
	-- TODO get database 
end

function Lumit.fetch(self, pkg)
	-- fetch repository
end

local string = require ("string")
function Lumit.search (self, k)
	local db = DB.open ()
	db:search (k, function (x)
		local s = string.format ("%10s    %s   %s",
			x.name, x.version, x.description)
		print (s)
	end)
end

function Lumit.init (self, fn)
	Lumit.CWD = process.cwd ()
	Lumit.CC = process.env["CC"] or "gcc -arch i386"
	Lumit.LUA_DIR = process.env["LUA_DIR"] or ""
	System.cmdstr ("uname -ms", function (err, os)
		if err>0 then
			Lumit.UNAME = "Unknown"
		else
			Lumit.UNAME = os
		end
		if fn then fn () end
	end)
end

function Lumit.clean(self, nextfn)
	System.cmd ("make clean", function (ret)
		if nextfn then nextfn (self) end
	end)
end

function Lumit.build_dep(self, pkg, nextfn)
	local wrkdir = self.CWD.."/_build"
	local db = DB.open ()
	db:find (pkg, function (x)
		if not x then 
			p ("ERROR", "Cannot find pkg "..pkg.." in database")
			-- process.exit (1)
			return
		end
		p ("pkg "..x.name .." found")
		if x.type == "git" then
			local cmd = "mkdir -p "..wrkdir.." ; git clone "..x.url.." "..wrkdir.."/"..x.name
			p(cmd)
			System.cmd (cmd, function (cmd, err)
				cmd =   "cd "..wrkdir.."/"..x.name.." ; "..
					"lum && lum install "..self.CWD
				p (cmd)
				System.cmd (cmd, function (cmd, err)
					p ("exit with "..err)
				end)
			end)
		elseif x.type == "dist" then
			-- distribution tarball
			p ("ERROR", "Unimplemented package type")
		else
			p ("ERROR", "Unknown package type")
		end
		if nextfn then nextfn () end
	end)
end

function Lumit.build(self, nextfn)
	local path = self.LUA_DIR
	if path == "" then path = "/usr/include" end
	if FS.exists_sync ("/usr/include/lua.h") then
		path = "/usr/include" end
	if FS.exists_sync ("/opt/local/include/lua.h") then
		path = "/opt/local/include" end
	if FS.exists_sync ("/usr/local/include/lua.h") then
		path = "/usr/local/include" end
	if not FS.exists_sync (path.."/lua.h") then
		path = path.."/deps/luajit/src"
		if not FS.exists_sync (path.."/lua.h") then
			print ("ERROR: Cannot find lua.h in LUA_DIR ("..self.LUA_DIR..")")
			process.exit (1)
		end
	end
	-- C preprocessor flags
	local cflags = "-I"..path
	-- linker flags
	local ldflags = ""
	if Lumit.UNAME == "Darwin i386" then
		ldflags = "-bundle -undefined dynamic_lookup"
	else
		ldflags = "-shared -fPIC"
	end

	local cmd = 
		" CC='"..self.CC.."'"..
		" CFLAGS='"..cflags.."'"..
		" LDFLAGS='"..ldflags.."'"..
		" LUA_DIR='"..path.."' make"
	p(cmd)
	System.cmd (cmd, function (cmd, err)
		print ("exit with "..err)
		if nextfn then nextfn (self) end
	end)
end

function Lumit.deps(self, nextfn)
	local ok, pkg = pcall (require, process.cwd ()..'/package')
	if ok then
		if #pkg.dependencies == 0 then
			p ("This package has zero dependencies")
		else
			for i = 1, #pkg.dependencies do
				p ("---> ",pkg.dependencies[i])
				self:build_dep (pkg.dependencies[i])
			end
		end
		if nextfn then nextfn (false) end
	else
		p ("ERROR", pkg)
		if nextfn then nextfn (true) end
	end
end

function Lumit.uninstall(self, pkg, nextfn)
	if not pkg then
		p ("Missing argument")
		return
	end
	local cmd = "rm -rf modules/"..pkg
	p ("RUNCMD", cmd)
	System.cmd (cmd, function (err)
		if nextfn then nextfn (err) end
	end)
end

function Lumit.install(self, path, nextfn)
	if not path then
		p ("Missing argument")
		return
	end
	local pkg = self:info (nil, function (pkg)
		local pkgname = pkg['name']
		local cmd =
			"ls modules/"..pkgname.."/ ; "..
			"mkdir -p '"..path.."/modules/"..pkgname.."' && "..
			"cp -f package.lua '"..path.."/modules/"..pkgname.."' && "..
			"cp -f modules/"..pkgname.."/* '"..path.."/modules/"..pkgname.."'"
		-- TODO: copy binaries ?
		p (cmd)
		System.cmd (cmd, function (err)
			p ("Done with exit ".. err)
			if nextfn then nextfn (err) end
		end)
	end)
end

function Lumit.cmd(x)
	if Lumit.cmd[x] then
		return Lumit.cmd[x](a)
	else
		print "Invalid command"
		process.exit (1)
	end
end

function Lumit.info(self, pkg, nextfn)
	local ok, deps = pcall (require, process.cwd ()..'/package')
	if ok then 
		if nextfn then nextfn (deps) end
	else
		p ("ERROR", deps)
		if nextfn then nextfn (nil) end
		process.exit (1)
	end
end

function Lumit.list(self)
	-- TODO: show package.lua info
	System.cmd ("ls modules/")
end

return Lumit
