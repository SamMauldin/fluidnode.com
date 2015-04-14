local base = "/"
local rootfs = {}

for k,v in pairs(fs) do
	rootfs[k] = v
end

-- Use only local functions to prevent hijacking
local sub = string.sub
local err = error

-- From Lua Users Wiki
local function starts(String, Start)
   return sub(String, 1, string.len(Start)) == Start
end

local function normalize(filestr)
	return rootfs.combine(base, filestr)
end

local function shorten(filestr)
	if starts(normalize(filestr), normalize("/.nucleusbios")) then
		return normalize("/.nucleusbios/fakedir/", filestr)
	else
		return normalize(filestr)
	end
end

local function valid(path, mode)
	local allowed=true
	local xpath=shorten(path)
	if starts(xpath, shorten("/.nucleusbios/")) then
        allowed = false
    end

	if allowed then
		if mode then
			return true
		end
		return xpath
	else
		if mode then
			return false
		end
		err("Access denied")
	end
end

local function validread(path)
	return shorten(path)
end

fs.list = function(path)
	if shorten(path) == shorten("/") then
		local list = rootfs.list("/")
		local newList = {}
		for k, v in pairs(list) do
			if not starts(shorten(v), shorten("/.nucleusbios/")) then
				newList[#newList + 1] = v
			end
		end
		return newList
	else
		return rootfs.list(validread(path))
	end
end

fs.exists = function(path)
	return rootfs.exists(validread(path))
end

fs.isDir = function(path)
	return rootfs.isDir(validread(path))
end

fs.isReadOnly = function(path)
	if valid(path, true) then
		return rootfs.isReadOnly(valid(path))
	else
		return true
	end
end

fs.getDrive = function(path)
	return rootfs.getDrive(validread(path))
end

fs.getSize = function(path)
	return rootfs.getSize(validread(path))
end

fs.getFreeSpace = function(path)
	return rootfs.getFreeSpace(validread(path))
end

fs.find = function(path)
	local found = rootfs.find(base .. path)
	local newfound = {}
	for k, v in pairs(found) do
		newfound[k] = v:sub(#base)
	end
	return newfound
end

fs.makeDir = function(path)
	return rootfs.makeDir(valid(path))
end

fs.move = function(path, cpath)
	return rootfs.move(valid(path), valid(cpath))
end

fs.copy = function(path, cpath)
	return rootfs.copy(validread(path), valid(cpath))
end

fs.delete = function(path)
	return rootfs.delete(valid(path))
end

fs.open = function(path, m)
	if m == "r" or m =="rb" then
		return rootfs.open(validread(path), m)
	else
		return rootfs.open(valid(path), m)
	end
end
