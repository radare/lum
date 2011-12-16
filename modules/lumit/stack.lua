-- Stack (for Lua 5.1)

local table = require ("table")

local Stack = {}

function Stack.new(t)
	local Stack = {
		push = function(self, ...)
			for _, v in ipairs{...} do
				self[#self+1] = v
			end
		end,
		pop = function(self, num)
			local num = num or 1
			if num > #self then
				return nil
			end
			local ret = {}
			for i = num, 1, -1 do
				ret[#ret+1] = table.remove(self)
			end
			return unpack(ret)
		end,
		reverse = function(self)
			for i = 1, #self/2 do
				self[i], self[1+#self-i] =
				self[1+#self-i], self[i]
			end
		end
		}
	return setmetatable(t or {}, {__index = Stack})
end

return Stack
