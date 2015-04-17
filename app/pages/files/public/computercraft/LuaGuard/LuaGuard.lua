local function drawScreen()
  term.setBackgroundColor(colors.blue)
  term.setTextColor(colors.white)
  term.clear()
  term.setCursorPos(1, 1)
  print("LuaGuard by SxwCorp CyberSecurity")
  term.setBackgroundColor(colors.lime)
  term.clearLine()
  term.setCursorPos(1, 3)
end

local definitions = http.get("https://files.fluidnode.com/public/computercraft/LuaGuard/definitions.lua")

local oldLoadstring = loadstring

local function scanString(str)
  local hasFound = vname
  for k, v in pairs(definitions) do
    local found = str:find(v.fragment)
    if found then
      hasFound = v.name
    end
  end

  if hasFound then
    drawScreen()
    print("Close call!")
    print("Your computer was almost infected with:")
    print(hasFound)
    print("LuaGuard has nullified the threat.")
    print("You're safe.")
    local random = tostring(math.random())
    os.queueEvent("luaguard_" .. random)
    os.pullEvent(random)
    print("")
    print("[Press any key to continue]")
    os.pullEvent("key")
  else
    return true
  end
end

local function fakeLoadstring(theCode, stringName)

  return oldLoadstring(theCode, stringName)
end

if definitions then
  definitions = loadstring(definitions)()
  loadstring = fakeLoadstring
else
  drawScreen()
  print("Hello! LuaGuard was unable to fetch virus definitions.")
  print("Your computer will boot in unsafe mode")
  print("")
  print("[Press any key to continue, or ctrl-R to reboot]")
  os.pullEvent("key")
end
