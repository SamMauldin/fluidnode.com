function run()
    fantom.busyScreen("Running POST, please wait....")
    
    local modem = peripheral.wrap("back")
    
    if not modem then
        fantom.busyScreen("No modem on back")
        sleep(5)
        os.reboot()
    end
    
    local monitor = peripheral.wrap("monitor_58")
    
    if not monitor then
        fantom.busyScreen("No monitor_58")
        sleep(5)
        os.reboot()
    end
    
    local p = modem.getNamesRemote()
    
    local port = 0
    
    for k, v in pairs(p) do
        if modem.getTypeRemote(v) == "modem" then
            local wrapped = peripheral.wrap(v)
            for i=1, 128 do
                if port <= 65535 then
                    wrapped.open(port)
                    port = port + 1
                end
            end
            sleep(0.01)
        end
    end
    
    if port == 65536 then
        fantom.busyScreen("65536 frequencies open")
    else
        fantom.busyScreen("Not enough ports")
        sleep(5)
        os.reboot()
    end
    
    term.redirect(monitor)
    
    fantom.clear()
    fantom.cprint("Very Large Array Listening", 1)
    
    while true do
        local e = {os.pullEvent("modem_message")}
        print(e[4] .. " -> " .. e[3] .. ":" .. e[5])
    end
end

os.queueEvent("modem_message")
local p = _G.printError
function _G.printError()
    _G.printError = p
    pcall(run)
    os.reboot()
end