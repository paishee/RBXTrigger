--[[

  taken from Quenty's Nevermore Engine bc I couldn't figure out how to make it myself :sadspong:

  https://github.com/Quenty/NevermoreEngine/blob/6ca66a994dba630ad9ac0e2208ac3b8b6630b053/Modules/Events/Signal.lua

]]

local Signal = {}
Signal.__index = Signal
Signal.ClassName = "Signal"


function Signal.new()
	local self = setmetatable({}, Signal)
	self._bindableEvent = Instance.new("BindableEvent")
	self._argData = {}
	self._argCount = 0 -- Prevent edge case of :Fire("A", nil) --> "A" instead of "A", nil
	return self
end


function Signal:Fire(...)
	self._argData = {...}
	self._argCount = select("#", ...)
	self._bindableEvent:Fire()
end


function Signal:Connect(handler)
	if not (type(handler) == "function") then error(("connect(%s)"):format(typeof(handler)), 2) end
	return self._bindableEvent.Event:Connect(function()
		handler(unpack(self._argData, 1, self._argCount))
	end)
end


function Signal:Wait()
	self._bindableEvent.Event:Wait()
	assert(self._argData, "Missing arg data, likely due to :TweenSize/Position corrupting threadrefs.")
	return unpack(self._argData, 1, self._argCount)
end


function Signal:Destroy()
	if self._bindableEvent then self._bindableEvent:Destroy(); self._bindableEvent = nil end
	self._argData = nil
	self._argCount = nil
end


return Signal
