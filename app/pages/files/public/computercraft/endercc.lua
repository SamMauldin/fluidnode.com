-- JSON
local controls = {["\n"]="\\n", ["\r"]="\\r", ["\t"]="\\t", ["\b"]="\\b", ["\f"]="\\f", ["\""]="\\\"", ["\\"]="\\\\"}

local whites = {['\n']=true; ['r']=true; ['\t']=true; [' ']=true; [',']=true; [':']=true}
function removeWhite(str)
	while whites[str:sub(1, 1)] do
		str = str:sub(2)
	end
	return str
end

function parseBoolean(str)
	if str:sub(1, 4) == "true" then
		return true, removeWhite(str:sub(5))
	else
		return false, removeWhite(str:sub(6))
	end
end

function parseNull(str)
	return nil, removeWhite(str:sub(5))
end

local numChars = {['e']=true; ['E']=true; ['+']=true; ['-']=true; ['.']=true}
function parseNumber(str)
	local i = 1
	while numChars[str:sub(i, i)] or tonumber(str:sub(i, i)) do
		i = i + 1
	end
	local val = tonumber(str:sub(1, i - 1))
	str = removeWhite(str:sub(i))
	return val, str
end

function parseString(str)
	local i,j = str:find('[^\\]"')
	local s = str:sub(2, j - 1)

	for k,v in pairs(controls) do
		s = s:gsub(v, k)
	end
	str = removeWhite(str:sub(j + 1))
	return s, str
end

function parseArray(str)
	str = removeWhite(str:sub(2))

	local val = {}
	local i = 1
	while str:sub(1, 1) ~= "]" do
		local v = nil
		v, str = parseValue(str)
		val[i] = v
		i = i + 1
		str = removeWhite(str)
	end
	str = removeWhite(str:sub(2))
	return val, str
end

function parseObject(str)
	str = removeWhite(str:sub(2))

	local val = {}
	while str:sub(1, 1) ~= "}" do
		local k, v = nil, nil
		k, v, str = parseMember(str)
		val[k] = v
		str = removeWhite(str)
	end
	str = removeWhite(str:sub(2))
	return val, str
end

function parseMember(str)
	local k = nil
	k, str = parseValue(str)
	local val = nil
	val, str = parseValue(str)
	return k, val, str
end

function parseValue(str)
	local fchar = str:sub(1, 1)
	if fchar == "{" then
		return parseObject(str)
	elseif fchar == "[" then
		return parseArray(str)
	elseif tonumber(fchar) ~= nil or numChars[fchar] then
		return parseNumber(str)
	elseif str:sub(1, 4) == "true" or str:sub(1, 5) == "false" then
		return parseBoolean(str)
	elseif fchar == "\"" then
		return parseString(str)
	elseif str:sub(1, 4) == "null" then
		return parseNull(str)
	end
	return nil
end

function decode(str)
	str = removeWhite(str)
	t = parseValue(str)
	return t
end

-- Usage: decode(str) encode(val)

local url = "https://ender.fluidnode.com/"

function rawStart(chan)
	local res = http.get(url .. "start?channel=" .. chan)
	if res then
		local msg = decode(res.readAll())
		if msg then
			if msg.err then
				return false, msg.err
			end
			return true, msg.uuid, msg.name
		else
			return false
		end
	else
		return false
	end
end

function rawPoll(uuid)
	local res = http.get(url .. "poll?uuid=" .. uuid);
	if res then
		local msg = decode(res.readAll())
		if msg then
			if msg.err then
				return false, msg.err
			end
			if not msg.res then
				return false
			end
			return true, msg.res, msg.from
		else
			return false
		end
	else
		return false
	end
end

function rawSend(msg, uuid)
	local res = http.get(url .. "send?uuid=" .. uuid .. "&message=" .. textutils.urlEncode(msg));
	if res then
		local msg = decode(res.readAll())
		if msg then
			if msg.err then
				return false, msg.err
			end
			return true
		else
			return false
		end
	else
		return false
	end
end

function rawCheck(uuid)
	local res = http.get(url .. "check?uuid=" .. uuid)
	if res then
		return res.readAll() == "true"
	else
		return false
	end
end

local chans = {}

function connect(channel)
	if chans[channel] then
		if rawCheck(chans[channel][1]) then
			return chans[channel][1]
		else
			chans[channel] = nil
			return connect(channel)
		end
	else
		local res, uuid, name = rawStart(channel)
		if res then
			chans[channel] = {uuid, name}
			return uuid
		else
			return connect(channel)
		end
	end
end

function getName(channel)
	connect(channel)
	return chans[channel][2]
end

function send(channel, message)
	local uuid = connect(channel)
	return rawSend(message, uuid)
end

function receive(channel)
	local uuid = connect(channel)
	return rawPoll(uuid)
end
