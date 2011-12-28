-- copyleft -- 2011 -- pancake<nopcode.org> --

local System = require ("./system")
local Stack = require ("./stack")
local DB = require ("./db")
local FS = require ("fs")

local Lumit = {}

function Lumit.update(self)
	-- TODO get database 
end

function Lumit.fetch(self, pkg)
	-- fetch repository
end

local string = require ("string")
function Lumit.search (self, k)
	DB.open (function (db)
		db:search (k, function (u,x)
			local s = string.format ("%-10s %-6s %-10s %s",
				x.name, x.version, u, x.description)
			print (s)
		end)
	end)
end

function Lumit.init (self, fn)
	Lumit.CWD = process.cwd ()
	Lumit.REPOS = process.env["REPOS"] or nil
	Lumit.HOME = process.env["HOME"] or "/tmp"
	Lumit.MAKE = process.env["MAKE"] or "make"
	Lumit.USER = process.env["MAKE"] or "anonymous"
	Lumit.CC = process.env["CC"] or "gcc -arch i386"
	Lumit.LUVIT_DIR = process.env["LUVIT_DIR"] or ""
	Lumit.LUA_DIR = process.env["LUA_DIR"]
	if not Lumit.LUA_DIR and Lumit.LUVIT_DIR then
		Lumit.LUA_DIR = Lumit.LUVIT_DIR.."/deps/luajit/src"
	end
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
	if FS.exists_sync ("Makefile") then
		System.cmd (Lumit.MAKE.." clean", function (ret)
			if nextfn then nextfn (self) end
		end)
	end
end

function Lumit.build_dep(self, pkg, nextfn)
	local wrkdir = self.CWD.."/_build"
	local at = pkg:find ('@')
	local repo = nil
	if at then
		repo = pkg:sub (at+1)
		pkg = pkg:sub (0, at-1)
	end
	p ("PKG", pkg)
	p ("REPO", repo)
	if FS.exists_sync ("./modules/"..pkg) then
		-- p ("module "..pkg.." already installed")
		return
	end
	DB.open (function (db)
	db:find (pkg, repo, function (u, x)
		if not x then 
			p ("ERROR", "Cannot find pkg "..pkg.." in database")
			-- process.exit (1)
			return
		end
		local wrkname = wrkdir.."/"..x.name
		-- print ("==> "..u.." : "..x.name)
		if FS.exists_sync (wrkname) then
			-- p ("Already installed: "..pkg)
			cmd =   "cd "..wrkdir.."/"..x.name.." ; "..
				"lum && lum deploy '"..self.CWD.."'"
			p (cmd)
			System.cmd (cmd, function (cmd, err)
				if err>0 then
					p ("ERROR", cmd)
				else
					p ("module "..pkg.." installed")
				end
			end)
			return
		else
			if x.type == "git" then
				local cmd = "mkdir -p "..wrkdir.." ; git clone "..x.url.." "..wrkdir.."/"..x.name
				p(cmd)
				System.cmd (cmd, function (cmd, err)
					if (err>0) then
						p ("Cannot clone '"..x.name.."' from "..x.url)
						process.exit (1)
					end
					cmd =   "cd "..wrkdir.."/"..x.name.." ; "..
						"lum && lum deploy "..self.CWD
					p (cmd)
					System.cmd (cmd, function (cmd, err)
						if err>0 then
							p ("exit with "..err) 
							process.exit (err)
						else p ("module "..pkg.." installed") end
					end)
				end)
			elseif x.type == "dist" then
				-- distribution tarball
				p ("ERROR", "Unimplemented package type")
			else
				p ("ERROR", "Unknown package type '"..x.type.."'")
			end
		end
		if nextfn then nextfn () end
	end)
	end)
end

function Lumit.build(self, nextfn)
	local path = self.LUVIT_DIR or self.LUA_DIR or ""
	if not FS.exists_sync (path.."/lua.h") then
		path = path.."/deps/luajit/src"
		if not FS.exists_sync (path.."/lua.h") then
			p ("ERROR", "Cannot find lua.h in LUVIT_DIR ("..self.LUVIT_DIR..")")
			p ("INFO", "Fill your ~/.lum/config with KEY=VALUE lines")
			process.exit (1)
		end
	end
	-- C preprocessor flags
--	path = "/usr/"
	System.cmdstr ("luvit-config --cflags", function(x,y)
		
	local cflags = "-I"..path
	if not err then
		cflags = y
	end

	-- linker flags
	local ldflags = ""
	if Lumit.UNAME == "Darwin i386" then
		ldflags = "-dynamiclib -undefined dynamic_lookup"
		--ldflags = "-dynamiclib" -- -undefined dynamic_lookup"
--		ldflags = ldflags.." "..Lumit.LUVIT_DIR.."/deps/luajit/src/libluajit.a"
		-- ldflags = "-dynamic -fPIC"
	else
		-- ldflags = "-dynamiclib -undefined dynamic_lookup"
		ldflags = "-shared -fPIC"
	end

	if FS.exists_sync ("Makefile") then
		local cmd = 
			" CC='"..self.CC.."'"..
			" CFLAGS='"..cflags.."'"..
			" LDFLAGS='"..ldflags.."'"..
			" LUA_DIR='"..path.."' "..Lumit.MAKE
		-- p(cmd)
		System.cmd (cmd, function (cmd, err)
			if err>0 then
				print ("exit with "..err)
				process.exit (err)
			end
			if nextfn then nextfn (self) end
		end)
	else
		if nextfn then nextfn (self) end
	end
	end)
end

function Lumit.deps(self, nextfn)
	local ok, pkg = pcall (require, process.cwd ()..'/package')
	if ok and #pkg.dependencies>0 then
		for i = 1, #pkg.dependencies do
			-- p ("---> ",pkg.dependencies[i])
			self:build_dep (pkg.dependencies[i])
		end
	end
	if nextfn then nextfn (not ok) end
end

function Lumit.uninstall(self, pkg, nextfn)
	if not pkg then
		print ("Usage: lum uninstall [pkg]")
		process.exit (1)
	end
	local cmd = "rm -rf modules/"..pkg
	p ("RUNCMD", cmd)
	System.cmd (cmd, function (err)
		if nextfn then nextfn (err) end
	end)
end

function Lumit.install(self, pkg, nextfn)
	if not pkg then
		print ("Usage: lum install [pkg]")
		process.exit (1)
	else
		self:build_dep (pkg, nextfn)
	end
end

function Lumit.deploy(self, path, nextfn)
	if not path then
		print ("Usage: lum deploy [path]")
		process.exit (1)
	end
	self:info (nil, function (pkg)
		if not pkg then
			p("oops")
			process.exit (1)
		end
		local pkgname = pkg['name']
		local cmd =
			-- "ls modules/"..pkgname.."/ ; "..
			"mkdir -p '"..path.."/modules/"..pkgname.."'\n"..
			"cp -f package.lua '"..path.."/modules/"..pkgname.."'\n"..
			"cp -f modules/"..pkgname.."/* '"..path.."/modules/"..pkgname.."'"
		-- TODO: copy binaries using luvit-fsutils
		-- p ("--->"..cmd)
		print (cmd)
		System.cmd (cmd, function (cmd, err)
			if err>0 then
				p ("ERROR", "Installation failed for module "..pkgname)
				-- TODO:  remove 
				System.cmd ("rm -rf '"..path.."/modules/"..pkgname.."'", function (x)
					process.exit (1)
				end)
			end
			if nextfn then nextfn (err) end
		end)
	end)
end

function Lumit.cmd(x)
	if Lumit.cmd[x] then
		return Lumit.cmd[x](a)
	end
	print ("Invalid command '"..x.."'")
	process.exit (1)
end

function Lumit.info(self, pkg, nextfn)
	local ok, deps 
	if pkg then
		ok, deps = pcall (require, pkg) 
	else
		ok, deps = pcall (require, process.cwd ()..'/package')
	end
	if ok then 
		if nextfn then nextfn (deps) end
	else
		-- p ("ERROR", deps)
		if nextfn then nextfn (nil) end
		-- process.exit (1)
	end
end

function Lumit.list(self)
	-- TODO: show package.lua info
	System.cmd ("ls modules/")
end

function Lumit.json(self, pkg, fn)
	if not pkg then
		pkg = require (pkg)
	else
		pkg = require (self.CWD.."/package.lua")
	end
	local j = {}
	j.name = pkg.name
	j.version = pkg.version
	j.description = pkg.description
		j.url = "jiji"
	getsource (function (err, t, u)
		j['type'] = t
		j.url = u
		print (JSON.encode (j))
	end)
end

function Lumit.update(self, fn)
	if not Lumit.REPOS then
		p ("ERROR", "undefined REPOS")
		process.exit (1)
	end
	local dir = Lumit.HOME.."/.lum/db"
	print ("Updating ~/.lum/db ...")
	System.cmd (
		"mkdir -p "..dir.." && cd '"..dir.."' && rm -f * && "..
		"for a in "..Lumit.REPOS.." ; do "..
		"wget --no-check-certificate -c -q --progress=bar:force $a"..
		" ; done",
		function (cmd, ret) 
			if ret>0 then
				print (cmd:replace(";","\n"))
			else
				print ("Done")
			end
			if fn then fn() end
		end)
end

function Lumit.push(self, fn)
	p ("TODO", "push")
end

return Lumit
