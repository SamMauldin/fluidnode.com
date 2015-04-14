--[[
    We're checking to see that all the files exist for this version of Nucleus.
    This isn't hardcoded into the resource pack so we can add additional verification
    later, like file checksums. This file is assumed to be intact and unmodified.
]]

local fileList = {
    "downloadfinished",
    "main.lua",
    "version",
    "protect.lua",
    "security",
    "adminpanel.lua"
}

for k, v in pairs(fileList) do
    if not fs.exists("/.nucleusbios/" .. v) then
        -- Trigger a verification failure
        fs.delete("/.nucleusbios/verify.lua")
        os.reboot()
    end
end

-- Verification passed
print("Verification succeded")
