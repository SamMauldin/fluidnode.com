--[[
]]

local args = {...}
local shell = args[1]

fantom.lock()

-- Data
local stargates = {
	["base"] = {"BJBYMBA", "Base"},
	["enderdeath"] = {"YVCVMBA", "Enderdeath"},
	["outside"] = {"OGWXMBA", "Outside"}
}

local floors = {
	["control"] = "56",
	["bee"] = "45",
	["enterance"] = "63"
}

local gColors = {}
gColors.blue = 0x58FAF4
gColors.green = 0x58FA58
gColors.white = 0xFFFFFF
gColors.black = 0x000000
gColors.gray = 0xC4C4C4

local cfg = cconfig.new("meta.cfg", "Meta")
cfg:load()

local features = {}

local glassSide = cfg:getString("glassesSide", "bottom")

features.stargate = (cfg:getString("useStargate", "no") == "yes")
local sgSide = cfg:getString("stargateSide", "front")

features.modem = cfg:getString("modem", "no") == "yes"
local modemSide = cfg:getString("modemSide", "bottom")

local master = cfg:getString("master", "Sxw1212")

local canrun = cfg:getString("canrun", "no")

cfg:save()

fantom.mandate(canrun == "yes", "Please setup config first")

local glass
local sg
local modem

fantom.mandate(peripheral.getType(glassSide) == "terminal_glasses_bridge", "Unknown terminal glasses")
glass = peripheral.wrap(glassSide)

if features.stargate then
	fantom.mandate(peripheral.getType(sgSide) == "stargate_base", "Unknown stargate")
	sg = peripheral.wrap(sgSide)
end

if features.modem then
	fantom.mandate(peripheral.getType(modemSide) == "modem", "Unknown modem")
	modem = peripheral.wrap(modemSide)
	modem.open(50101)
end

fantom.busyScreen("Meta server running")

glass.clear()

local screen = {}
local commands = {}
local actions = {}
local loops = {}

screen.notificationBox = glass.addBox(10, 10, 150, 15, gColors.blue, 0)
screen.notificationText = glass.addText(12, 12, "", gColors.gray)
screen.notificationText.setScale(1.25)

screen.mainBox = glass.addBox(10, 26, 150, 53, gColors.white, 0.3)
screen.mainTextOne = glass.addText(12, 28, "Meta", gColors.blue)
screen.mainTextTwo = glass.addText(12, 38, "", gColors.blue)
screen.mainTextThree = glass.addText(12, 48, "", gColors.blue)
screen.mainTextFour = glass.addText(12, 58, "", gColors.blue)
screen.mainTextFive = glass.addText(12, 68, "", gColors.blue)

screen.timeText = glass.addText(1, 1, "Time", gColors.white)

function drawLoop()
	while true do
		for k,v in pairs(loops) do
			v()
		end
		sleep(0)
	end
end

function commandLoop()
	while true do
		local _, msg, user = os.pullEvent("chat_command")
		if user == master then
			local args = fantom.split(msg, " ")
			local cmd = table.remove(args, 1)
			if commands[cmd] then
				commands[cmd]()
			else
				screen.mainTextFive.setText("Command not found")
				actions[#actions+1] = {
					["action"] = function()
						screen.mainTextFive.setText("")
					end,
					["time"] = os.clock() + 2
				}
			end
		else
			screen.mainTextFive.setText("Access denied")
			actions[#actions+1] = {
				["action"] = function()
					screen.mainTextFive.setText("")
				end,
				["time"] = os.clock() + 2
			}
		end
	end
end

function actionLoop()
	while true do
		local tempact = {}
		for k,v in pairs(actions) do
			if v.time <= os.clock() then
				v.action()
			else
				tempact[#tempact+1] = v
			end
		end
		actions = tempact
		sleep(0)
	end
end

function notify(msg, temp)
	screen.notificationBox.setOpacity(0.3)
	screen.notificationText.setText(msg)
	if not temp then
		actions[#actions+1] = {
			["action"] = function()
				screen.notificationBox.setOpacity(0)
				screen.notificationText.setText("")
			end,
			["time"] = os.clock() + 5
		}
	end
end

function clearNotify()
	screen.notificationBox.setOpacity(0)
	screen.notificationText.setText("")
end

-- Command library

function sgLookup(addr, fallback)
	
	if stargates[addr] then
		return stargates[addr][1]
	end
	
	if fallback then
		return addr
	end
	return nil
end

function sgSearch(addr, fallback)
	for k, v in pairs(stargates) do
		if v[1] == addr then
			return v[2]
		end
	end
	
	if fallback then
		return addr
	end
	return nil
end

-- Commands
commands.update = function()
	screen.mainTextTwo.setText("Updating...")
	fs.delete("/.upwork")
	os.reboot()
end

if features.stargate then
commands.stargate = function()
	while true do
		screen.mainTextOne.setText("Meta Stargate")
		screen.mainTextTwo.setText("Address: " .. sg.getHomeAddress())
		screen.mainTextThree.setText("dc, dial, lock, unlock")
		if fs.exists("/.sglocked") then
			screen.mainTextFive.setText("Locked")
		else
			screen.mainTextFive.setText("Unlocked")
		end
		
		local _, msg, user = os.pullEvent("chat_command")
		if user == master then
			if msg == "back" then
				screen.mainTextOne.setText("Meta")
				screen.mainTextTwo.setText("")
				screen.mainTextThree.setText("")
				screen.mainTextFive.setText("")
				return
			elseif msg == "dc" then
				sg.disconnect()
			elseif msg == "dial" then
				screen.mainTextThree.setText("To where?")
				local _, addr, user = os.pullEvent("chat_command")
				if user == master then
					pcall(sg.connect, sgLookup(addr, true))
					screen.mainTextThree.setText("")
					if sg.getDialledAddress() ~= sgLookup(addr, true) then
						screen.mainTextThree.setText("Failed.")
					end
				end
			elseif msg == "lock" then
				fs.makeDir("/.sglocked")
			elseif msg == "unlock" then
				fs.delete("/.sglocked")
			end
		end
	end
end
end

if features.modem then
commands.elevator = function()
	while true do
		screen.mainTextOne.setText("Meta Elevator")
		screen.mainTextTwo.setText("send, clear")
		local _, msg, user = os.pullEvent("chat_command")
		if user == master then
			if msg == "back" then
				screen.mainTextOne.setText("Meta")
				screen.mainTextTwo.setText("")
				return
			elseif msg == "clear" then
				modem.transmit(50101, 50101, "SKYSCRAPER:" .. textutils.serialize({"CLEAR"}))
			elseif msg == "send" then
				screen.mainTextTwo.setText("Where to?")
				local _, msg, user = os.pullEvent("chat_command")
				if user == master then
					screen.mainTextTwo.setText("Clearing...")
					modem.transmit(50101, 50101, "SKYSCRAPER:" .. textutils.serialize({"CLEAR"}))
					sleep(0.3)
					screen.mainTextTwo.setText("Calling...")
					modem.transmit(50101, 50101, "SKYSCRAPER:" .. textutils.serialize({"CALL"}))
					sleep(1.1)
					local floor = floors[msg] or msg
					screen.mainTextTwo.setText("Sending...")
					modem.transmit(50101, 50101, "SKYSCRAPER:" .. textutils.serialize({"SENDING", floor}))
					sleep(0.3)
				end
				screen.mainTextTwo.setText("")
			end
		end
	end
end
end

commands.shell = function()
	fantom.unlock()
	fantom.clear()
	shell.run("shell")
	fantom.lock()
	fantom.busyScreen("Meta server running")
end

-- Loops
loops.clock = function()
	screen.timeText.setText(textutils.formatTime(os.time()))
end

if features.stargate then
local sgConnected = false
local sgDialing = false
loops.stargate = function()
	if sg.isConnected() == "true" then
		sgDialing = false
		if not sgConnected then
			notify("SG: " .. sgSearch(sg.getDialledAddress(), true), true)
			sgConnected = true
		end
	elseif sgConnected then
		sgConnected = false
		clearNotify()
	elseif sg.getDialledAddress() ~= "" then
		if fs.exists("/.sglocked") then
			sg.disconnect()
		end
		if not sgDialing then
			sgDialing = true
			notify("SG* " .. sgSearch(sg.getDialledAddress(), true), true)
		end
	elseif sgDialing then
		sgDialing = false
		clearNotify()
	end
end
end

parallel.waitForAny(fantom.busyLoop, drawLoop, commandLoop, actionLoop)
