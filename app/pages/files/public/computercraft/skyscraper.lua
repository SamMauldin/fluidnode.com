function centerPrint(sText)
	local w, h = term.getSize()
	local x, y = term.getCursorPos()
	x = math.max(math.floor((w / 2) - (#sText / 2)), 0)
	term.setCursorPos(x, y)
	term.write(sText)
end

function clear()
	term.clear()
	term.setCursorPos(1, 1)
end

function nextLine(n)
	n = n or 1
	local x, y = term.getCursorPos()
	term.setCursorPos(x, y + n)
end


-- System test
	clear()
	centerPrint("SkyScraper by Sxw1212")
	nextLine()
	centerPrint("Elevator starting. Please wait")
	nextLine()
	centerPrint("Running System Test...")
	
	if peripheral.getType("bottom") ~= "rednet_cable" then
		nextLine()
		centerPrint("Error: No cable on bottom")
		error()
	end
	if peripheral.getType("back") ~= "modem" then
		nextLine()
		centerPrint("Error: No modem on back")
		error()
	end
	
	sleep(0.25)
	
	nextLine()
	centerPrint("System test completed, starting...")
	
	sleep(0.25)
	clear()

-- Vars
	cfg = {}
	PORT = 50101
	PREFIX = "SKYSCRAPER:"
	COLORS = {
		["detector"] = colors.white,
		["boarding"] = colors.orange,
		["elevator"] = colors.magenta
	}
	MODEM = peripheral.wrap("back")
	ELEVATORS = {}
	FLOORS = {"Call Elevator"}
	STAT = "CLEAR"
	SELECTED = 1
	REFRESHQUEUE = true
	MODEM.open(PORT)

-- Helper functions
	
	function refresh()
		if REFRESHQUEUE then
			REFRESHQUEUE = false
			os.queueEvent("refresh")
		end
	end
	
	function table.copy(t)
		local t2 = {}
		for k,v in pairs(t) do
			t2[k] = v
		end
		return t2
	end
	function send(msg)
		MODEM.transmit(PORT, PORT, PREFIX .. textutils.serialize(msg))
	end
	
	function recv()
		while true do
			local _, _, _, _, msg = os.pullEvent("modem_message")
			if msg:sub(1, #PREFIX) == PREFIX then
				local trans = msg:sub((#PREFIX)+1)
				return textutils.unserialize(trans)
			end
		end
	end
	
	function menuCompat()
		-- Somebody help me, I have no idea how else to do this
		local smenu = table.copy(ELEVATORS)
		smenu[#smenu+1] = cfg
		table.sort(smenu, function (a,b) return (a.y > b.y) end)
		
		local sorted = {}
		local len = #smenu
		for i = 1, len do
			sorted[i] = smenu[i].name
		end
		table.insert(sorted, 1, "Call Elevator")
		FLOORS = sorted
	end
	
	function addFloor(data)
		local contains = false
		for k, v in pairs(ELEVATORS) do
			if v.y == data.y then
				contains = true
				ELEVATORS[k].name = data.name
			end
		end
		if not contains then
			table.insert(ELEVATORS, data)
		end
		menuCompat()
	end
	
	function runmenu()
		local function render()
			clear()
			term.setCursorPos(1, 1)
			centerPrint("SkyScraper by Sxw1212")
			nextLine(2)
			for k, v in pairs(FLOORS) do
				local val = v
				if cfg.name == v then
					val = "-" .. val .. "-"
				elseif SELECTED == k then
					val = "[" .. val .. "]"
				end
				centerPrint(val)
				nextLine()
			end
		end
		render()
		while true do
			local e, k = os.pullEvent("key")
			if k == keys.up then
				if SELECTED ~= 1 then
					if FLOORS[SELECTED - 1] ~= cfg.name then
						SELECTED = SELECTED - 1
					elseif SELECTED > 2 then
						SELECTED = SELECTED - 2
					end
				end
			elseif k == keys.down then
				if FLOORS[SELECTED + 1] then
					if FLOORS[SELECTED + 1] ~= cfg.name then
						SELECTED = SELECTED + 1
					elseif FLOORS[SELECTED + 2] then
						SELECTED = SELECTED + 2
					end
				end
			elseif k == keys.enter then
				local sel = FLOORS[SELECTED]
				SELECTED = 1
				return sel
			end
			render()
		end
	end

-- Config
	if not fs.exists("/sky.cfg") then
		centerPrint("SkyScraper configuration")
		term.setCursorPos(1, 2)
		write("Y-Level: ")
		cfg.y = tonumber(read())
		write("Floor name: ")
		cfg.name = read()
		
		local fh = fs.open("/sky.cfg", "w")
		fh.write(textutils.serialize(cfg))
		fh.close()
		
		centerPrint("Done!")
		sleep(0.25)
		clear()
	end
	local fh = fs.open("/sky.cfg", "r")
	cfg = textutils.unserialize(fh.readAll())
	fh.close()
	if cfg.y and cfg.name then
		centerPrint("SkyScraper configuration")
		nextLine()
		centerPrint("Loaded from file!")
		clear()
		cfg.y = tonumber(cfg.y)
	else
		fs.delete("/sky.cfg")
		os.reboot()
	end

-- Announce
	send({ "DISCOVER", cfg })

-- Handlers
	
	function msgHandler()
		while true do
			local msg = recv()
			if msg[1] == "CALL" then
				if STAT == "COMING" then
				else
					STAT = "BUSY"
					rs.setBundledOutput("bottom", COLORS.boarding)
					sleep(1)
					rs.setBundledOutput("bottom", 0)
					refresh()
				end
			elseif msg[1] == "SENDING" then
				STAT = "BUSY"
				
				if tostring(msg[2]) == tostring(cfg.y) then
					STAT = "COMING"
					rs.setBundledOutput("bottom", COLORS.elevator)
				end
				refresh()
			elseif msg[1] == "DISCOVER" then
				addFloor(msg[2])
				send({ "HELLO", cfg })
				refresh()
			elseif msg[1] == "HELLO" then
				addFloor(msg[2])
				refresh()
			elseif msg[1] == "CLEAR" then
				STAT = "CLEAR"
				refresh()
				rs.setBundledOutput("bottom", 0)
			elseif msg[1] == "RESET" then
				os.reboot()
			end
		end
	end
	
	function menu()
		if STAT == "CLEAR" then
			local x, y = term.getSize()
			local floor = runmenu()
			if floor == "Call Elevator" then
				send({ "CALL", cfg })
				STAT = "COMING"
				rs.setBundledOutput("bottom", COLORS.elevator)
			elseif floor ~= cfg.name then
				for k, v in pairs(ELEVATORS) do
					if v.name == floor then
						send({ "SENDING", v.y, cfg})
					end
				end
				STAT = "BUSY"
				rs.setBundledOutput("bottom", COLORS.boarding)
			end
			refresh()
		elseif STAT == "BUSY" then
			clear()
			centerPrint("SkyScraper by Sxw1212")
			nextLine(7)
			centerPrint("Elevator busy, please wait")
			os.pullEvent("AReallyLongEventThatYou'dBetterNotCallOrElse...")
		elseif STAT == "COMING" then
			clear()
			centerPrint("SkyScraper by Sxw1212")
			nextLine(7)
			centerPrint("Elevator coming, please wait")
			while true do
				os.pullEvent("redstone")
				if colors.test(rs.getBundledInput("bottom"), COLORS.detector) then
					STAT = "CLEAR"
					send({ "CLEAR", cfg })
					rs.setBundledOutput("bottom", 0)
					refresh()
				end
			end
		end
	end
	
	function main()
		goroutine.spawn("msgHandler", msgHandler)
		goroutine.assignEvent("msgHandler", "modem_message")
		while true do
			REFRESHQUEUE = true
			goroutine.spawn("menu", menu)
			
			goroutine.assignEvent("menu", "key")
			goroutine.assignEvent("menu", "redstone")
			
			os.pullEvent("refresh")
			
			sleep(0.1)
			goroutine.kill("menu")
			sleep(0.1)
		end
	end
	
	goroutine.run(main)
