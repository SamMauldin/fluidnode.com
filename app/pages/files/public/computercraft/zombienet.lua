-- Zombie net CC API

-- Base64
local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
local function dec(data)
    data = string.gsub(data, '[^'..b..'=]', '')
    return (data:gsub('.', function(x)
        if (x == '=') then return '' end
        local r,f='',(b:find(x)-1)
        for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
        return r;
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if (#x ~= 8) then return '' end
        local c=0
        for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
        return string.char(c)
    end))
end

-- String split
local function split(str, delim, maxNb)
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
    for part, pos in string.gmatch(str, pat) do
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

-- Advanced API
function aObtain(server, key)
	local postdat = ""
	if key then
		postdat = postdat .. "key=" .. textutils.urlEncode(key)
	end
	local res = http.post(server .. "obtain", postdat)
	if res then
		res = split(res.readAll(), ":")
		return res
	else
		error("Unable to connect to server")
	end
end

function aPoll(server, sid)
	local postdat = ""
	postdat = postdat .. "sid=" .. textutils.urlEncode(sid)
	local res = http.post(server .. "poll", postdat)
	if res then
		res = split(res.readAll(), ":")
		return res
	else
		error("Unable to connect to server")
	end
end

function aSend(server, key, msg)
	local postdat = ""
	postdat = postdat .. "key=" .. textutils.urlEncode(key) .. "&"
	postdat = postdat .. "msg=" .. textutils.urlEncode(msg)
	local res = http.post(server .. "send", postdat)
	if res then
		res = split(res.readAll(), ":")
		return res
	else
		error("Unable to connect to server")
	end
end

-- Simple api
local serv = "https://globe-opennet.rhcloud.com/api/zn/"
local key = ""
local sid = ""
local started = false
function start(skey)
	local res = aObtain(serv, skey)
	assert(res[1] == "success", "Unknown response")
	started = true
	key = res[2]
	sid = res[3]
	return true, key, sid
end

function send(msg)
	assert(started, "Start API first")
	local res = aSend(serv, key, msg)
	if res[1] == "success" then
		return true
	elseif res[1] == "fail" then
		if res[2] == "unknown key" then
			start(key)
			return send(msg)
		end
		return false, res[2]
	else
		error("Unknown response")
	end
end

function poll()
	assert(started, "Start API first")
	local res = aPoll(serv, sid)
	if res[1] == "success" then
		return true, dec(res[2])
	elseif res[1] == "fail" then
		if res[2] == "invalid/expired sid" then
			start(key)
			return poll()
		end
		return false, res[2]
	else
		error("Unknown response")
	end
end

function daemon()
	while true do
		local suc, msg = poll()
		if suc then
			os.queueEvent("zn_msg", msg)
		end
	end
end