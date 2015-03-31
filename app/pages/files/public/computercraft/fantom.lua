function clear()
	term.setTextColor(colors.white)
	term.setBackgroundColor(colors.black)
	term.clear()
	term.setCursorPos(1, 1)
end

function cprint(msg, y)
    local w, h = term.getSize()
    local x = term.getCursorPos()
    x = math.max(math.floor((w / 2) - (#msg / 2)), 0)
    term.setCursorPos(x, y)
    print(msg)
end

function busyScreen(msg)
	clear()
	cprint(msg, 7)
end

function periodicLoop(func, time)
	return function()
		local time = time or 10
		while true do
			sleep(time)
			if func then func() end
		end
	end
end

busyLoop = periodicLoop()

local oldPull = os.pullEvent

function lock()
	os.pullEvent = os.pullEventRaw
end

function unlock()
	os.pullEvent = oldPull
end

function mandate(var, msg)
	if not var then
		error(msg, 0)
	end
end

function split(str, delim, maxNb)
    -- Eliminate bad cases...
    if string.find(str, delim) == nil then
        return { str }
    end
    if maxNb == nil or maxNb < 1 then
        maxNb = 0    -- No limit
    end
    local result = {}
    local pat = "(.-)" .. delim .. "()"
    local nb = 0
    local lastPos
    for part, pos in string.gfind(str, pat) do
        nb = nb + 1
        result[nb] = part
        lastPos = pos
        if nb == maxNb then break end
    end
    -- Handle the last field
    if nb ~= maxNb then
        result[nb + 1] = string.sub(str, lastPos)
    end
    return result
end