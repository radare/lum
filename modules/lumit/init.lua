-- copyleft -- 2011-2012 -- pancake<nopcode.org> --

local System = require ("./system")
local Stack = require ("./stack")
local DB = require ("./db")
local FS = require ("fs")
local UV = require('uv')
local Math = require ("math")
local OS = require ("os")

local Lumit = {}
Lumit.WRKDIR = "_lumwrk"

local string = require ("string")

function Lumit.upgrade (self, k)
	if not k then
		FS.readdir (process.cwd().."/modules", function (err, files)
			if err then process.exit (1) end
			for i=1,#files do
				self:upgrade (files[i])
			end
		end)
	else
		Lumit:uninstall (k, function ()
			Lumit:clean(k, function ()
				Lumit:install(k)
			end)
		end)
	end
end

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
	if Lumit.is_init then return end
	Lumit.is_init = true
	Lumit.UPDATE = false
	Lumit.ROOT = process.cwd ()
	Lumit.REPOS = process.env["REPOS"] or nil
	Lumit.HOME = process.env["HOME"] or "/tmp"
	Lumit.MAKE = process.env["MAKE"] or "make"
	Lumit.USER = process.env["USER"] or "anonymous"
	Lumit.PUSH = process.env["PUSH"] or "scp $0 user@host.org"
	Lumit.LUVIT_DIR = process.env["LUVIT_DIR"] or ""
	Lumit.LUA_DIR = process.env["LUA_DIR"]
	Lumit.rmfiles = nil
	process:on ("SIGINT", function (x)
		p ("^C Interrupted", Lumit.rmfiles)
		if Lumit.rmfiles then
			local cmd = "rm -rf "..Lumit.rmfiles
			p (cmd)
			System.cmd (cmd, function (x) -- XXX: dangerous
				process.exit (1)
			end)
			process:on ("SIGINT", nil)
		else
			process.exit (1)
		end
	end)
	System.cmdstr ("luvit-config --cflags|cut -d ' ' -f 1| cut -c 3-", function (err, x)
		Lumit.LUVIT_DIR = x
		Lumit.LUA_DIR = x.."/luajit"
		--if not Lumit.LUA_DIR and Lumit.LUVIT_DIR then
		--	Lumit.LUA_DIR = Lumit.LUVIT_DIR.."/deps/luajit/src"
		--end
		System.cmdstr ("uname -ms", function (err, os)
			if err>0 then
				Lumit.UNAME = "Unknown"
			else
				Lumit.UNAME = os
			end
			local HOST_CC = "gcc"
			--if Lumit.UNAME == "Darwin i386" then
			--	HOST_CC = "gcc -arch i386"
			--end
			Lumit.CC = process.env["CC"] or HOST_CC
			if fn then fn () end
		end)
	end)
end

function Lumit.clean(self, pkg, nextfn)
	if pkg then
		-- XXX. must cd + lum imho
		if FS.exists_sync (Lumit.WRKDIR..pkg.."/Makefile") then
			System.cmd ("cd "..Lumit.WRKDIR.."/"..pkg.." ; "..Lumit.MAKE.." clean", function (ret)
				if nextfn then nextfn (self) end
			end)
		else
			if nextfn then nextfn (self) end
		end
	else
		if FS.exists_sync ("Makefile") then
			System.cmd (Lumit.MAKE.." clean", function (ret)
				if nextfn then nextfn (self) end
			end)
		else
			if nextfn then nextfn (self) end
		end
	end
end

function Lumit.build_implicit_module(self, pkg, url, nextfn)
	-- TODO: add support for tar.{gz,xz,bz2}
	p ("TODO: implicit dep installer", pkg, url)
	local wdpkg = Lumit.WRKDIR.."/"..pkg
	local c = "mkdir -p "..wdpkg
	System.cmd (c, function (out, err)
		local c = "echo 'nothing to download'"
		if url then
			c = "wget -c --progress=bar:force -O "..wdpkg..".zip --no-check-certificate '"..url.."'"
		end
		System.cmd (c, function (out, err)
			-- if err then process.exit (1) end
			local zipfile = Lumit.ROOT.."/"..pkg..".zip"
			if pkg:sub (1,1) == '/' then
				zipfile = pkg..".zip"
			end
			c = "mkdir -p "..wdpkg.." ; cd "..wdpkg.." && unzip -o "..zipfile
			System.cmd (c, function (out, err)
				if not err == 0 then p ("error: "..c) end
				c = "cd "..wdpkg.. "/* && pwd  ; lum -D "..Lumit.ROOT
				System.cmd (c, function (out, err)
					if nextfn then nextfn () end
				end)
			end)
		end)
	end)
end

function Lumit.build_module(self, pkg, nextfn)
	local wrkdir = self.ROOT.."/"..Lumit.WRKDIR
	local at = pkg:find ('@')
	local repo = nil
	if at then
		repo = pkg:sub (at+1)
		pkg = pkg:sub (0, at-1)
	end
	if FS.exists_sync ("./modules/"..pkg) then
		-- p ("module "..pkg.." already installed")
		return
	end
	p ("=> Installing dependency "..pkg)
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
			local cmd = ""
			if Lumit.UPDATE then
				if x.type == "git" then
					p ("=> Updating from git...")
					cmd = "git pull ; "
				elseif x.type == "hg" then
					p ("=> Updating from hg...")
					cmd = "hg pull -u ; "
				end
			end
			--Lumit.rmfiles = self.ROOT
			-- p ("Already installed: "..pkg)
			cmd = "cd "..wrkdir.."/"..x.name.." ; "..
				cmd.."lum && lum deploy '"..self.ROOT.."'"
	--		p (cmd)
			--Lumit.rmfiles = self.ROOT.."/modules/"..x.name
			System.cmd (cmd, function (cmd, err)
				if err>0 then
					p ("ERROR", cmd)
					if Lumit.rmfiles then
						System.cmd ("rm -rf "..Lumit.rmfiles)
					end
				else
					p ("module "..pkg.." installed")
				end
				Lumit.rmfiles = nil
			end)
			return
		else
			if x.type == "git" then
				local cmd = "mkdir -p "..wrkdir.." ; git clone "..x.url.." "..wrkdir.."/"..x.name
				p(cmd)
				Lumit.rmfiles = wrkdir.."/"..x.name.." "..self.ROOT.."/modules/"..x.name
				System.cmd (cmd, function (cmd, err)
					if (err>0) then
						p ("Cannot clone '"..x.name.."' from "..x.url)
						process.exit (1)
					end
					cmd =   "cd "..wrkdir.."/"..x.name.." ; "..
						"lum && lum deploy "..self.ROOT
					p (cmd)
					System.cmd (cmd, function (cmd, err)
						if err>0 then
							p ("exit with "..err) 
							process.exit (err)
						else p ("module "..pkg.." installed") end
						Lumit.rmfiles = nil
					end)
				end)
			elseif x.type == "dist" then
				local pkg = p.name
				-- distribution tarball
				local implicit = pkg:find ('.zip')
				if implicit then -- implicit package file
					self:build_implicit_module (pkg:sub (0, implicit-1), nil, nextfn)
					return
				else
					p ("ERROR", "Unimplemented package type")
				end
			else
				p ("ERROR", "Unknown package type '"..x.type.."'")
			end
		end
		if nextfn then nextfn () end
	end)
	end)
end

function Lumit.dist(self, nextfn)
	local p = require (self.ROOT.."/package.lua")
	-- if -d .git
	local d = p.name.."-"..p.version
	Lumit.rmfiles = d..".zip "..d
	local cmd = "rm -f "..d..".zip ; git clone . "..d.." ; "..
		"[ -d modules ] && cp -rf modules "..d.."/ ; "..
		"rm -rf "..d.."/.git* ; zip -mr "..d..".zip "..d
	System.cmd (cmd, function (x) 
		Lumit.rmfiles = nil
		if nextfn then nextfn () end
	end)
end

function Lumit.build(self, nextfn)
	local path = self.LUA_DIR or self.LUVIT_DIR.."/luajit" or ""
	if not FS.existsSync (path.."/lua.h") then
		p ("Cannot found in "..path)
		--path = path.."/deps/luajit/src"
		if not FS.exists_sync (path.."/lua.h") then
	--		p ("ERROR", "Cannot find lua.h in LUVIT_DIR ("..self.LUVIT_DIR..")")
			p ("INFO", "Fill your ~/.lum/config with KEY=VALUE lines")
	--		process.exit (1)
		end
	end
	-- C preprocessor flags
--	path = "/usr/"
	System.cmdstr ("luvit-config --cflags", function (err, y)
		local cflags = "-I"..path
		if not err then
			cflags = y
		end

		-- linker flags
		local ldflags = ""
		if Lumit.UNAME == "" then
			p("XXX", "UNAME is null, and this will fail")
			return
		end
		if Lumit.UNAME == "Darwin i386" then
			ldflags = "-dynamiclib -undefined dynamic_lookup"
			-- ldflags = "-dynamic -fPIC"
		else
			ldflags = "-shared -fPIC"
		end

		--p("ldflags", ldflags)
		if FS.existsSync ("Makefile") then
			local cmd = 
				" CC='"..self.CC.."'"..
				" CFLAGS='-w "..cflags.."'"..
				" LDFLAGS='"..ldflags.."'"..
				" LUA_DIR='"..path.."' "..Lumit.MAKE
			p(cmd)
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
	-- name=url -- implicit source
	if pkg.dependencies then
		for k, v in pairs (pkg.dependencies) do
			if not (type (k) == "number") then
				if not FS.exists_sync ("./modules/"..k) then
					self:build_implicit_module (k, v)
				end
			end
		end
		-- name -- database repo
		if ok and #pkg.dependencies>0 then
			for i = 1, #pkg.dependencies do
				p ("---> ",pkg.dependencies[i])
				self:build_module (pkg.dependencies[i])
			end
		end
	end
	if nextfn then nextfn (not ok) end
end

function Lumit.uninstall(self, pkg, nextfn)
	if not pkg then
		print ("Usage: lum uninstall [pkg]")
		process.exit (1)
	end
	
	local f = "modules/"..pkg
	if FS.exists_sync (f) then
		local cmd = "rm -rf "..f
		System.cmd (cmd, function (err)
			if nextfn then nextfn (err) end
		end)
	else
		p ("ERROR", "Module "..pkg.." is not installed")
		if nextfn then nextfn (err) end
	end
end

function Lumit.install(self, pkg, nextfn)
	if not pkg then
		print ("Usage: lum install [pkg]")
		process.exit (1)
	else
		local implicit = pkg:find ('.zip')
		if implicit then -- implicit package file
			self:build_implicit_module (pkg:sub (0, implicit-1), nil, nextfn)
		else
			self:build_module (pkg, nextfn)
		end
	end
end

function Lumit.deploy(self, path, nextfn)
	if not path then
		print ("Usage: lum deploy [path]")
		process.exit (1)
	end
	self:info (nil, function (pkg)
		if not pkg then
			p ("oops", "no package found")
			process.exit (1)
		end
		local pkgname = pkg['name']
		if FS.exists_sync (path.."/package.lua") then
			local pk = require (path.."/package.lua")
			if (pk.name == pkgname) then
				p("ERROR", "Cannot deploy on itself")
				process.exit (1)
			end
		end
		local cmd = ""
		if pkg['main'] then
			cmd =
				-- "ls modules/"..pkgname.."/ ; "..
				"mkdir -p '"..path.."/modules/"..pkgname.."'\n"..
				"cp -f package.lua '"..path.."/modules/"..pkgname.."'\n"..
				"cp -f '"..pkg['main'].."' '"..path.."/modules/"..pkgname.."/init.lua'"
		else
			cmd =
				-- "ls modules/"..pkgname.."/ ; "..
				"mkdir -p '"..path.."/modules/"..pkgname.."' ; \n"..
				"cp -f package.lua '"..path.."/modules/"..pkgname.."' ; \n"..
				"if [ -f init.lua ]; then\n"..
				"  cp -f init.lua '"..path.."/modules/"..pkgname.."' ; "..
				"else\n"..
				"  cp -f modules/"..pkgname.."/* '"..path.."/modules/"..pkgname.."' ; "..
				"fi\n"
		end
		-- TODO: copy binaries using luvit-fsutils
		-- p ("cmd", cmd)
		Lumit.rmfiles = path.."/modules/"..pkgname
		System.cmd (cmd, function (cmd, err)
			if err>0 then
				p ("ERROR", "Installation failed for module "..pkgname)
				-- TODO:  remove
				System.cmd ("rm -rf '"..Lumit.rmfiles.."'", function (x)
					process.exit (1)
				end)
			end
			Lumit.rmfiles = nil
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
		--if not (pkg:sub(1,1) == "/") then
		--	pkg = process.cwd ().."/modules/"..pkg.."/package"
		--end
		ok, deps = pcall (require, pkg) 
	else
		ok, deps = pcall (require, process.cwd ()..'/package')
	end
	if ok then 
		if nextfn then nextfn (deps) end
	else
		p ("ERROR", deps)
		if nextfn then nextfn (nil) end
		-- process.exit (1)
	end
end

function Lumit.list(self)
	-- TODO: show package.lua info
	-- TODO: rewrite in pure lua
	if FS.exists_sync ("modules") then
		System.cmd ("ls modules/*/package.lua 2> /dev/null | cut -d / -f 2")
	end
end

-- XXX: dupped in lum?
function Lumit.json(self, pkg, fn)
	if not pkg then
		pkg = require (pkg)
	else
		pkg = require (self.ROOT.."/package.lua")
	end
	local j = {}
	j.name = pkg.name
	j.main = pkg.main
	j.version = pkg.version
	j.description = pkg.description
	j.url = "url"
	getsource (function (err, t, u)
		j['type'] = t
		j.url = u
		print (JSON.stringify (j))
	end)
end

function Lumit.sync(self, fn)
	if not Lumit.REPOS then
		p ("ERROR", "undefined REPOS")
		process.exit (1)
	end
	local dir = Lumit.HOME.."/.lum/db"
	print ("Updating ~/.lum/db ...")
	local a = "mkdir -p "..dir.." && cd '"..dir.."' && rm -f * && "..
		"for a in "..Lumit.REPOS.." ; do "..
		"wget --no-check-certificate -c -nv $a"..
		" ; done"
	System.cmd (a,
		function (cmd, ret) 
			if ret>0 then
				print (cmd:replace (";","\n"))
			else
				print ("Done")
			end
			if fn then fn() end
		end)
end

function Lumit.push(self, fn)
	local argv2 = process.argv[2] or ""
	Math.randomseed (OS.time ())
	local d = "/tmp/_lumwrk."..Math.floor (Math.random()*1000000)
	-- TODO: this is not yet implemented in luvit!
	UV.activate_signal_handler (2, function (x)
		p("OWN YEAH")
	end)
	local f = d.."/"..self.USER
	Lumit.rmfiles = d
	UV.fs_stat (argv2, function (e, x)
		local cmd = "mkdir -p "..d.." ; "
		if argv2 == "" or x.is_directory then
			cmd = cmd..
				"lum -j "..argv2.." | tee "..f.." ; "..
				Lumit.PUSH:gsub ("$0", f)
		else
			cmd = cmd..
				"cat "..argv2.." | tee "..f.." ; "..
				Lumit.PUSH:gsub ("$0", f)
		end
		p ("PUSH", cmd)
		System.cmd (cmd, function(x)
			System.cmd ("rm -f "..f, function(x)
					Lumit.rmfiles = nil
				end)
			end)
	end)
end

return Lumit
