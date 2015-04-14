local baseURL = "http://files.fluidnode.com/public/computercraft/nucleus/"

local files = {
    "version",
    "main.lua",
    "verify.lua",
    "protect.lua",
    "security",
    "adminpanel.lua"
}

for k, v in pairs(files) do
    local fh = http.get(baseURL .. v)
    if fh then
        local ffh = fs.open("/.nucleusbios/" .. v, "w")
        ffh.write(fh.readAll())
        ffh.close()
    end
end

local fh = fs.open("/.nucleusbios/downloadfinished", "w")
fh.write("Yup, it finished")
fh.close()

os.reboot()
