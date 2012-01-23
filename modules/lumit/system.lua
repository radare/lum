local System = {}

function System.cmd(line, fn)
	local child = require ('process').spawn('/bin/sh', {'-c', line}, {})
	child.stdout:on ('data', function (data)
	  print (data:sub(1,#data-1))
	end)
	child.stderr:on ('data', function (data)
	  print (data:sub(1,#data-1))
	end)
	child:on ('exit', function (exit_status, term_signal)
	  if fn then fn (line, exit_status) end
	end)
	-- child.stdin:write(makefile)
	-- child.stdin:close()
end

function System.cmdstr(line, fn)
	local str = ""
	local child = require('process').spawn('/bin/sh', {'-c', line}, {})
	child.stdout:on('data', function(data)
		str = str..data
	end)
	child.stderr:on('data', function(data)
	  print(data)
	end)
	child:on('exit', function (exit_status, term_signal)
		if fn then fn (exit_status, str:sub(1,#str-1)) end
	end)
	--child.stdin:write(makefile)
	--child.stdin:close()
end

function System.cmdseq(seq, resfn)
	local s = Stack.new (seq)
	s:reverse() -- weird double copy
	local fn = function (cmd, err)
		if err then
			print ("Command fail: "..cmd)
			resfn (err)
		end
		local cmd = s:pop ()
		if cmd then
			System.cmd (cmd, fn) 
		else
			resfn (0)
		end
	end
	System.cmd (s:pop (), fn)
end

return System
