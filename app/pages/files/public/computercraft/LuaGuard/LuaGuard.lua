local function drawScreen()
  term.setBackgroundColor(colors.blue)
  term.setTextColor(colors.white)
  term.clear()
  term.setCursorPos(1, 1)
  print("LuaGuard by SxwCorp CyberSecurity")
  term.setBackgroundColor(colors.lime)
  term.clearLine()
  term.setCursorPos(1, 3)
  term.setBackgroundColor(colors.blue)
end

local definitions = http.get("http://files.fluidnode.com/public/computercraft/LuaGuard/definitions.lua")

local oldLoadstring = loadstring

local function scanString(str)
  local hasFound = nil
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
    os.pullEvent("luaguard_" .. random)
    print("")
    print("[Press any key to continue]")
    os.pullEvent("key")
  else
    return true
  end
end

local function fakeLoadstring(theCode, stringName)
  local run = scanString(theCode)
  if run then
    return oldLoadstring(theCode, stringName)
  else
    return nil, "LuaGuard virus prevention triggered"
  end
end

local function fakeLoadfile(filename)
  local fh = fs.open(filename, "r")
  if fh then
    local func = fakeLoadstring(fh.readAll())
    return func
  end
end

local function fakeDofile(filename)
  local f = assert(fakeLoadfile(filename))
  return f()
end

local function fakeOSrun( _tEnv, _sPath, ... )
    local tArgs = { ... }
    local fnFile, err = fakeLoadfile( _sPath )
    if fnFile then
        local tEnv = _tEnv
        --setmetatable( tEnv, { __index = function(t,k) return _G[k] end } )
        setmetatable( tEnv, { __index = _G } )
        setfenv( fnFile, tEnv )
        local ok, err = pcall( function()
            fnFile( unpack( tArgs ) )
        end )
        if not ok then
            if err and err ~= "" then
                printError( err )
            end
            return false
        end
        return true
    end
    if err and err ~= "" then
        printError( err )
    end
    return false
end

if definitions then
  definitions = loadstring(definitions.readAll())()
  loadstring = fakeLoadstring
  loadfile = fakeLoadfile
  dofile = fakeDofile
  os.run = fakeOSrun
else
  drawScreen()
  print("Hello! LuaGuard was unable to fetch virus definitions.")
  print("Your computer will boot in unsafe mode")
  print("")
  print("[Press any key to continue, or ctrl-R to reboot]")
  os.pullEvent("key")
end

local function transparent()
  local oldfs = {}
  oldfs.open = fs.open
  oldfs.delete = fs.delete
  oldfs.move = fs.move
  oldfs.copy = fs.copy
  oldfs.exists = fs.exists
  oldfs.combine = fs.combine
  oldfs.list = fs.list
  local oldos = {}
  oldos.pullEventRaw = os.pullEventRaw


  local function redirect(path)
      if oldfs.combine("/", path) == "startup" then
          return "/.luaguardstartup"
      else
          return path
      end
  end

  fs.open = function(path, mode)
      return oldfs.open(redirect(path), mode)
  end

  fs.delete = function(path)
      return oldfs.delete(redirect(path))
  end

  fs.move = function(path, dest)
      return oldfs.move(redirect(path), redirect(dest))
  end

  fs.copy = function(path, dest)
      return oldfs.copy(redirect(path), redirect(dest))
  end

  fs.exists = function(path)
      return oldfs.exists(redirect(path))
  end

  fs.list = function(path)
      if oldfs.combine("/", path) == "" then
          if oldfs.exists("/.luaguardstartup") then
            local list = oldfs.list("/")
            local newlist = {}
            for k, v in pairs(list) do
                if v ~= oldfs.combine("/.luaguardstartup", "/") then
                    table.insert(newlist, v)
                end
            end
            return newlist
          else
              local list = oldfs.list("/")
              local newlist = {}
              for k, v in pairs(list) do
                  if v ~= "startup" then
                      table.insert(newlist, v)
                  end
              end
              return newlist
          end
      else
          return oldfs.list(path)
      end
  end
end

transparent()
print("LuaGuard active")

if fs.exists("/startup") then
  term.setTextColor(colors.white)
  shell.run("/startup")
end
