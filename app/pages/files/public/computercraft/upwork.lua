-- Upwork, updating/launcher api

--[[
if not fs.exists("/.upwork/upwork") then local uwork = http.get("http://files.fluidnode.com/public/computercraft/upwork.lua") if uwork then fs.makeDir("/.upwork") local fh = fs.open("/.upwork/upwork", "w") fh.write(uwork.readAll()) fh.close() else error("Unable to fetch upwork") end end
os.loadAPI("/.upwork/upwork")
upwork.inject("http://framework", "Framework Name")
upwork.launch("appname")
]]--

local rooturl = "http://files.fluidnode.com/public/computercraft/"

function cprint(msg, y)
    local w, h = term.getSize()
    local x = term.getCursorPos()
    x = math.max(math.floor((w / 2) - (#msg / 2)), 0)
    term.setCursorPos(x, y)
    print(msg)
end

function clear()
	term.setTextColor(colors.white)
	term.setBackgroundColor(colors.black)
	term.clear()
	term.setCursorPos(1, 1)
	cprint("Upwork launcher", 1)
end

function dispErr(msg, err)
	clear()
	cprint("Upwork launcher", 1)
	cprint(msg, 3)
	if err then
		cprint(err, 4)
	end
	cprint("Press any key to exit", 6)
	os.pullEvent("key")
	error()
end

function setHost(url)
	rooturl = url
end

function grab(url, name)
	if http then
		clear()
		cprint("Fetching " .. name, 3)
		local res = http.get(url)
		if res then
			return res.readAll()
		else
			dispErr("Error fetching " .. name)
		end
	else
		dispErr("Please enable http to use this application")
	end
end

function update()
	local uwork = grab(rooturl .. "upwork.lua", "Upwork")
	fs.delete("/.upwork/upwork")
	local fh = fs.open("/.upwork/upwork", "w")
	fh.write(uwork)
	fh.close()
end

function launch(app, shell)
	local code = grab(rooturl .. app .. ".lua", app)
	local func, err = loadstring(code)
	if err then
		dispErr("Error parsing " .. app, err)
	else
		func(shell)
	end
end

function inject(framework, name)
	if not fs.exists("/.upwork/" .. name) then
		local fw = grab(framework, name)
		local fh = fs.open("/.upwork/" .. name, "w")
		fh.write(fw)
		fh.close()
	end
	os.loadAPI("/.upwork/" .. name)
end

function injectApp(name)
	inject(rooturl .. name .. ".lua", name)
end

update()