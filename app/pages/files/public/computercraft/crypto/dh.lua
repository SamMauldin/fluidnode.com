-- BigInt library from: http://www.computercraft.info/forums2/index.php?/topic/12137-bigint-arbitrary-precision-unsigned-integers/

-- NOTE:
-- Fixed carry bug in add
-- And added yielding
-- - Sxw1212

-- This source file is at version 1 as of the last time I've bothered to update it.
-- KillaVanilla's arbitrary-precision API in Lua. Please don't steal it.

-- All arbitrary precision integers (or "bigInts" or any other capitalization of such) are unsigned. Operations where the result is less than 0 are undefined.
-- BigInts are stored as tables with each digit occupying an entry. These tables store values least-significant digit first.
-- For example, the number 1234 in BigInt format would be {4, 3, 2, 1}. This process is automatically done with bigInt.toBigInt().

-- Several of these functions have multiple names. For example, bigInt.mod(a,b) can also be called as bigInt.modulo(a,b), and bigInt.cmp_lt(a,b) can be called as bigInt.cmp_less_than(a,b).

-- Alternate names:
-- left and right shifts: blshift() and brshift()
-- sub, mul, div, mod, exp: subtract(), multiply(), divide(), modulo(), exponent()
-- <the comparison functions>: cmp_<full name of comparision> (e.g "cmp_greater_than_or_equal_to", "cmp_greater_than_equal_to", or "cmp_gteq")
-- toStr: tostring()
-- bitwise operations (AND, OR, XOR, NOT): band(), bor(), bxor(), bnot().

local function round(i) -- round a float
    yield()
    if i - math.floor(i) >= 0.5 then
        return math.ceil(i)
    end
    return math.floor(i)
end

local function copy(input)
    yield()
    if type(input) == "number" then
        return toBigInt(input)
    end
    local t = {}
    for i,v in pairs(input) do
        t[i] = v
    end
    return t
end

local function removeTrailingZeroes(a)
    yield()
    local cpy = copy(a)
    for i=#cpy, 1, -1 do
        if cpy[i] ~= 0 then
            break
        else
            cpy[i] = nil
        end
    end
    return cpy
end

local cmp_lt = function(a,b) -- Less Than
    yield()
    local a2 = removeTrailingZeroes(a)
    local b2 = removeTrailingZeroes(b)

    if #a2 > #b2 then
        return false
    end
    if #b2 > #a2 then
        return true
    end

    for i=#a2, 1, -1 do
        if a2[i] > b2[i] then
            return false
        elseif a2[i] < b2[i] then
            return true
        end
    end
    return false
end

local cmp_gt = function(a,b) -- Greater Than
    yield()
    local a2 = removeTrailingZeroes(a)
    local b2 = removeTrailingZeroes(b)

    if #a2 < #b2 then
        return false
    end
    if #b2 < #a2 then
        return true
    end

    for i=#a2, 1, -1 do
        if a2[i] > b2[i] then
            return true
        elseif a2[i] < b2[i] then
            return false
        end
    end
    return false
end

local cmp_lteq = function(a,b) -- Less Than or EQual to
    yield()
    local a2 = removeTrailingZeroes(a)
    local b2 = removeTrailingZeroes(b)

    if #a2 > #b2 then
        return false
    end
    if #b2 > #a2 then
        return true
    end

    for i=#a2, 1, -1 do
        if a2[i] > b2[i] then
            return false
        elseif a2[i] < b2[i] then
            return true
        end
    end
    return true
end

local cmp_gteq = function(a,b) --Greater Than or EQual to
    yield()
    local a2 = removeTrailingZeroes(a)
    local b2 = removeTrailingZeroes(b)

    if #a2 < #b2 then
        --print("[debug] GTEQ: a2="..toStr(a2).." b2="..toStr(b2).." #a2="..#a2.." #b2="..#b2.." #a2<#b2")
        return false
    end
    if #b2 < #a2 then
        --print("[debug] GTEQ: a2="..toStr(a2).." b2="..toStr(b2).." #a2="..#a2.." #b2="..#b2.." #b2<#a2")
        return true
    end

    for i=#a2, 1, -1 do
        if a2[i] > b2[i] then
            return true
        elseif a2[i] < b2[i] then
            return false
        end
    end
    return true
end

local cmp_eq = function(a,b) --EQuality
    yield()
    local a2 = removeTrailingZeroes(a)
    local b2 = removeTrailingZeroes(b)

    if #a2 < #b2 then
        return false
    end
    if #b2 < #a2 then
        return false
    end

    for i=#a2, 1, -1 do
        if a2[i] > b2[i] then
            return false
        elseif a2[i] < b2[i] then
            return false
        end
    end
    return true
end

local cmp_ieq = function(a,b) -- InEQuality
    yield()
    local a2 = removeTrailingZeroes(a)
    local b2 = removeTrailingZeroes(b)

    if #a2 < #b2 then
        return true
    end
    if #b2 < #a2 then
        return true
    end

    for i=#a2, 1, -1 do
        if a2[i] > b2[i] then
            return true
        elseif a2[i] < b2[i] then
            return true
        end
    end
    return false
end

local function validateBigInt(a)
    yield()
    if type(a) ~= "table" then
        return false
    end
    for i=1, #a do
        if type(a[i]) ~= "number" then
            return false
        end
    end
    return true
end

local function cleanCarry(n)
    yield()
    for i=1, #n do
        if n[i] > 9 then
            n[i] = n[i] - 10
            if n[i + 1] then
                n[i + 1] = n[i + 1] + 1
            else
                n[i + 1] = 1
            end
        end
    end
    return n
end

local function add_bigInt(a, b)
    yield()
    local cpy = copy(a)
    local carry = 0
    if cmp_gt(b, a) then
        return add_bigInt(b,a)
    end

    for i=1, #b do
        local n = a[i] or 0
        local m = b[i] or 0
        cpy[i] = n+m+carry
        if cpy[i] > 9 then
            carry = 1 -- cpy[i] cannot be greater than 18
            cpy[i] = cpy[i] % 10
        else
            carry = 0
        end
    end
    if carry > 0 then
        local n = cpy[ #b+1 ] or 0
        cpy[ #b+1 ] = n+carry
        cpy = cleanCarry(cpy)
    end
    return removeTrailingZeroes(cpy)
end

local function sub_bigInt(a,b)
    yield()
    local cpy = copy(a)
    local borrow = 0

    for i=1, #a do
        local n = a[i] or 0
        local n2 = b[i] or 0
        cpy[i] = n-n2-borrow
        if cpy[i] < 0 then
            cpy[i] = 10+cpy[i]
            borrow = 1
        else
            borrow = 0
        end
    end

    return removeTrailingZeroes(cpy)
end

local function mul_bigInt(a,b)
    yield()
    local sum = {}
    local tSum = {}
    local carry = 0

    for i=1, #a do
        yield()
        carry = 0
        sum[i] = {}
        for j=1, #b do
            yield()
            sum[i][j] = (a[i]*b[j])+carry
            if sum[i][j] > 9 then
                carry = math.floor( sum[i][j]/10 )
                sum[i][j] = sum[i][j] % 10
                --sum[i][j] = ( (sum[i][j]/10) - carry )*10
            else
                carry = 0
            end
        end
        if carry > 0 then
            sum[i][#b+1] = carry
        end
        for j=2, i do
            table.insert(sum[i], 1, 0) -- table.insert(bigInt, 1, 0) is equivalent to bigInt*10. Likewise, table.remove(bigInt, 1) is equivalent to bigInt/10. table.insert(bigInt, 1, x) is eqivalent to bigInt*10+x, assuming that x is a 1-digit number
        end
    end

    yield()

    for i=1, #a+#b do
        tSum[i] = 0
    end
    for i=1, #sum do
        tSum = add_bigInt(tSum, sum[i])
    end
    return removeTrailingZeroes(tSum)
end

local function div_bigInt(a,b)
    yield()
    local bringDown = {}
    local quotient = {}

    for i=#a, 1, -1 do
        yield()
        table.insert(bringDown, 1, a[i])
        if cmp_gteq(bringDown, b) then
            local add = 0
            while cmp_gteq(bringDown, b) do -- while bringDown >= b do
                yield()
                bringDown = sub_bigInt(bringDown, b)
                add = add+1
            end
            table.insert(quotient, 1, add)
        else
            table.insert(quotient, 1, 0)
        end
    end
    return removeTrailingZeroes(quotient), removeTrailingZeroes(bringDown)
end

local function exp_bigInt(a,b) -- exponentation by squaring. This *should* work, no promises though.
    yield()
    if cmp_eq(b, 1) then
        return a
    elseif cmp_eq(mod(b, 2), 0) then
        return exp_bigInt(mul(a,a), div(b,2))
    elseif cmp_eq(mod(b, 2), 1) then
        return mul(a, exp_bigInt(mul(a,a), div(sub(b,1),2)))
    end
end

local function toBinary(a) -- Convert from a arbitrary precision decimal number to an arbitrary-length table of bits (least-significant bit first)
    yield()
    local bitTable = {}
    local cpy = copy(a)

    while true do
        local quot, rem = div_bigInt(cpy, {2})
        cpy = quot
        rem[1] = rem[1] or 0
        table.insert(bitTable, rem[1])
        --print(toStr(cpy).." "..toStr(rem))
        if #cpy == 0 then
            break
        end
    end
    return bitTable
end

local function fromBinary(a) -- Convert from an arbitrary-length table of bits (from toBinary) to an arbitrary precision decimal number
    yield()
    local dec = {0}
    for i=#a, 1, -1 do
        dec = mul_bigInt(dec, {2})
        dec = add_bigInt(dec, {a[i]})
    end
    return dec
end

local function appendBits(i, sz) -- Appends bits to make #i match sz.
yield()
    local cpy = copy(i)
    for j=#i, sz-1 do
        table.insert(cpy, 0)
    end
    return cpy
end

local function bitwiseLeftShift(a, i)
    yield()
    return mul(a, exp(2, i))
end

local function bitwiseRightShift(a, i)
    yield()
    local q = div(a, exp(2, i))
    return q
end

local function bitwiseNOT(a)
    yield()
    local b = toBinary(a)
    for i=1, #b do
        if b[i] == 0 then
            b[i] = 1
        else
            b[i] = 0
        end
    end
    return fromBinary(b)
end

local function bitwiseXOR(a, b)
    yield()
    local a2 = toBinary(a)
    local b2 = appendBits(toBinary(b), #a2)
    if #a2 > #b2 then
        return bitwiseXOR(b,a)
    end
    for i=1, #a2 do
        if a2[i] == 1 and b2[i] == 1 then
            a2[i] = 0
        elseif a2[i] == 0 and b2[i] == 0 then
            a2[i] = 0
        else
            a2[i] = 1
        end
    end
    return fromBinary(a2)
end

local function bitwiseOR(a, b)
    yield()
    local a2 = toBinary(a)
    local b2 = appendBits(toBinary(b), #a2)
    if #a2 > #b2 then
        return bitwiseOR(b,a)
    end
    for i=1, #a2 do
        if a2[i] == 1 or b2[i] == 1 then
            a2[i] = 1
        else
            a2[i] = 0
        end
    end
    return fromBinary(a2)
end

local function bitwiseAND(a, b)
    yield()
    local a2 = toBinary(a)
    local b2 = appendBits(toBinary(b), #a2)
    if #a2 > #b2 then
        return bitwiseAND(b,a)
    end
    for i=1, #a2 do
        if a2[i] == 1 and b2[i] == 1 then
            a2[i] = 1
        else
            a2[i] = 0
        end
    end
    return fromBinary(a2)
end

function add(a, b)
    yield()
    if type(a) == "number" then
        a = toBigInt(a)
    end
    if type(b) == "number" then
        b = toBigInt(b)
    end
    if validateBigInt(a) and validateBigInt(b) then
        return add_bigInt(a,b)
    end
end

function sub(a, b)
    yield()
    if type(a) == "number" then
        a = toBigInt(a)
    end
    if type(b) == "number" then
        b = toBigInt(b)
    end
    if validateBigInt(a) and validateBigInt(b) then
        return sub_bigInt(a,b)
    end
end

function mul(a, b)
    yield()
    if type(a) == "number" then
        a = toBigInt(a)
    end
    if type(b) == "number" then
        b = toBigInt(b)
    end
    if validateBigInt(a) and validateBigInt(b) then
        return mul_bigInt(a,b)
    end
end

function div(a, b)
    yield()
    if type(a) == "number" then
        a = toBigInt(a)
    end
    if type(b) == "number" then
        b = toBigInt(b)
    end
    if validateBigInt(a) and validateBigInt(b) then
        return div_bigInt(a,b)
    end
end

function mod(a, b)
    yield()
    if type(a) == "number" then
        a = toBigInt(a)
    end
    if type(b) == "number" then
        b = toBigInt(b)
    end
    if validateBigInt(a) and validateBigInt(b) then
        local q, r = div_bigInt(a,b)
        return r
    end
end

local function exp(a,b)
    yield()
    if type(a) == "number" then
        a = toBigInt(a)
    end
    if type(b) == "number" then
        b = toBigInt(b)
    end
    if validateBigInt(a) and validateBigInt(b) then
        return exp_bigInt(a,b)
    end
end

local function toStr(a)
    yield()
    local str = ""
    for i=#a, 1, -1 do
        str = str..string.sub(tostring(a[i]), 1, 1)
    end
    return str
end

function toBigInt(n) -- can take either a string composed of numbers (like "1237162721379627129638372") or a small integer (such as literal 18957 or 4*197163%2)
    yield()
    local n2 = {}
    if type(n) == "number" then
        while n > 0 do
             table.insert(n2,  n%10)
             n = math.floor(n/10)
        end
    elseif type(n) == "string" then
        for i=1, #n do
            local digit = tonumber(string.sub(n, i,i))
            if digit then
                table.insert(n2, 1, digit)
            end
        end
    end
    return n2
end

-- Long names for the functions:
local cmp_equality = cmp_eq
local cmp_inequality = cmp_ieq
local cmp_greater_than = cmp_gt
local cmp_greater_than_or_equal_to = cmp_gteq
local cmp_greater_than_equal_to = cmp_gteq
local cmp_less_than = cmp_lt
local cmp_less_than_or_equal_to = cmp_lteq
local cmp_less_than_equal_to = cmp_lteq
local bor = bitwiseBOR
local bxor = bitwiseXOR
local band = bitwiseAND
local bnot = bitwiseNOT
local blshift = bitwiseLeftShift
local brshift = bitwiseRightShift
local subtract = sub
local multiply = mul
local divide = div
local modulo = mod
local exponent = exp

-- Random Numbers by KillaVanilla

-- KillaVanilla's RNG('s), composed of the Mersenne Twister RNG and the ISAAC algorithm.

-- Exposed functions:
-- initalize_mt_generator(seed) - Seed the Mersenne Twister RNG.
-- extract_mt() - Get a number from the Mersenne Twister RNG.
-- seed_from_mt(seed) - Seed the ISAAC RNG, optionally seeding the Mersenne Twister RNG beforehand.
-- generate_isaac() - Force a reseed.
-- random(min, max) - Get a random number between min and max.

-- Helper functions:
local function toBinary(a) -- Convert from an integer to an arbitrary-length table of bits
        local b = {}
        local copy = a
        while true do
                table.insert(b, copy % 2)
                copy = math.floor(copy / 2)
                if copy == 0 then
                        break
                end
        end
        return b
end

local function fromBinary(a) -- Convert from an arbitrary-length table of bits (from toBinary) to an integer
        local dec = 0
        for i=#a, 1, -1 do
                dec = dec * 2 + a[i]
        end
        return dec
end

-- ISAAC internal state:
local aa, bb, cc = 0, 0, 0
local randrsl = {} -- Acts as entropy/seed-in. Fill to randrsl[256].
local mm = {} -- Fill to mm[256]. Acts as output.

-- Mersenne Twister State:
local MT = {} -- Twister state
local index = 0

-- Other variables for the seeding mechanism
local mtSeeded = false
local mtSeed = math.random(1, 2^31-1)

-- The Mersenne Twister can be used as an RNG for non-cryptographic purposes.
-- Here, we're using it to seed the ISAAC algorithm, which *can* be used for cryptographic purposes.

local function initalize_mt_generator(seed)
        index = 0
        MT[0] = seed
        for i=1, 623 do
                local full = ( (1812433253 * bit.bxor(MT[i-1], bit.brshift(MT[i-1], 30) ) )+i)
                local b = toBinary(full)
                while #b > 32 do
                        table.remove(b, 1)
                end
                MT[i] = fromBinary(b)
        end
end

local function generate_mt() -- Restock the MT with new random numbers.
        for i=0, 623 do
                local y = bit.band(MT[i], 0x80000000)
                y = y + bit.band(MT[(i+1)%624], 0x7FFFFFFF)
                MT[i] = bit.bxor(MT[(i+397)%624], bit.brshift(y, 1))
                if y % 2 == 1 then
                        MT[i] = bit.bxor(MT[i], 0x9908B0DF)
                end
        end
end

local function extract_mt(min, max) -- Get one number from the Mersenne Twister.
        if index == 0 then
                generate_mt()
        end
        local y = MT[index]
        min = min or 0
        max = max or 2^32-1
        --print("Accessing: MT["..index.."]...")
        y = bit.bxor(y, bit.brshift(y, 11) )
        y = bit.bxor(y, bit.band(bit.blshift(y, 7), 0x9D2C5680) )
        y = bit.bxor(y, bit.band(bit.blshift(y, 15), 0xEFC60000) )
        y = bit.bxor(y, bit.brshift(y, 18) )
        index = (index+1) % 624
        return (y % max)+min
end

local function seed_from_mt(seed) -- seed ISAAC with numbers from the MT:
        if seed then
                mtSeeded = false
                mtSeed = seed
        end
        if not mtSeeded or (math.random(1, 100) == 50) then -- Always seed the first time around. Otherwise, seed approximately once per 100 times.
                initalize_mt_generator(mtSeed)
                mtSeeded = true
                mtSeed = extract_mt()
        end
        for i=1, 256 do
                randrsl[i] = extract_mt()
        end
end

local function mix(a,b,c,d,e,f,g,h)
        a = a % (2^32-1)
        b = b % (2^32-1)
        c = c % (2^32-1)
        d = d % (2^32-1)
        e = e % (2^32-1)
        f = f % (2^32-1)
        g = g % (2^32-1)
        h = h % (2^32-1)
         a = bit.bxor(a, bit.blshift(b, 11))
         d = (d + a) % (2^32-1)
         b = (b + c) % (2^32-1)
         b = bit.bxor(b, bit.brshift(c, 2) )
         e = (e + b) % (2^32-1)
     c = (c + d) % (2^32-1)
         c = bit.bxor(c, bit.blshift(d, 8) )
         f = (f + c) % (2^32-1)
         d = (d + e) % (2^32-1)
         d = bit.bxor(d, bit.brshift(e, 16) )
         g = (g + d) % (2^32-1)
         e = (e + f) % (2^32-1)
         e = bit.bxor(e, bit.blshift(f, 10) )
         h = (h + e) % (2^32-1)
         f = (f + g) % (2^32-1)
         f = bit.bxor(f, bit.brshift(g, 4) )
         a = (a + f) % (2^32-1)
         g = (g + h) % (2^32-1)
         g = bit.bxor(g, bit.blshift(h, 8) )
         b = (b + g) % (2^32-1)
         h = (h + a) % (2^32-1)
         h = bit.bxor(h, bit.brshift(a, 9) )
         c = (c + h) % (2^32-1)
         a = (a + b) % (2^32-1)
         return a,b,c,d,e,f,g,h
end

local function isaac()
        local x, y = 0, 0
        for i=1, 256 do
                x = mm[i]
                if (i % 4) == 0 then
                        aa = bit.bxor(aa, bit.blshift(aa, 13))
                elseif (i % 4) == 1 then
                        aa = bit.bxor(aa, bit.brshift(aa, 6))
                elseif (i % 4) == 2 then
                        aa = bit.bxor(aa, bit.blshift(aa, 2))
                elseif (i % 4) == 3 then
                        aa = bit.bxor(aa, bit.brshift(aa, 16))
                end
                aa = (mm[ ((i+128) % 256)+1 ] + aa) % (2^32-1)
                y = (mm[ (bit.brshift(x, 2) % 256)+1 ] + aa + bb) % (2^32-1)
                mm[i] = y
                bb = (mm[ (bit.brshift(y,10) % 256)+1 ] + x) % (2^32-1)
                randrsl[i] = bb
        end
end

local function randinit(flag)
        local a,b,c,d,e,f,g,h = 0x9e3779b9,0x9e3779b9,0x9e3779b9,0x9e3779b9,0x9e3779b9,0x9e3779b9,0x9e3779b9,0x9e3779b9-- 0x9e3779b9 is the golden ratio
        aa = 0
        bb = 0
        cc = 0
        for i=1,4 do
                a,b,c,d,e,f,g,h = mix(a,b,c,d,e,f,g,h)
        end
        for i=1, 256, 8 do
                if flag then
                        a = (a + randrsl[i]) % (2^32-1)
                        b = (b + randrsl[i+1]) % (2^32-1)
                        c = (c + randrsl[i+2]) % (2^32-1)
                        d = (b + randrsl[i+3]) % (2^32-1)
                        e = (e + randrsl[i+4]) % (2^32-1)
                        f = (f + randrsl[i+5]) % (2^32-1)
                        g = (g + randrsl[i+6]) % (2^32-1)
                        h = (h + randrsl[i+7]) % (2^32-1)
                end
                a,b,c,d,e,f,g,h = mix(a,b,c,d,e,f,g,h)
                mm[i] = a
                mm[i+1] = b
                mm[i+2] = c
                mm[i+3] = d
                mm[i+4] = e
                mm[i+5] = f
                mm[i+6] = g
                mm[i+7] = h
        end

        if flag then
                for i=1, 256, 8 do
                        a = (a + randrsl[i]) % (2^32-1)
                        b = (b + randrsl[i+1]) % (2^32-1)
                        c = (c + randrsl[i+2]) % (2^32-1)
                        d = (b + randrsl[i+3]) % (2^32-1)
                        e = (e + randrsl[i+4]) % (2^32-1)
                        f = (f + randrsl[i+5]) % (2^32-1)
                        g = (g + randrsl[i+6]) % (2^32-1)
                        h = (h + randrsl[i+7]) % (2^32-1)
                        a,b,c,d,e,f,g,h = mix(a,b,c,d,e,f,g,h)
                        mm[i] = a
                        mm[i+1] = b
                        mm[i+2] = c
                        mm[i+3] = d
                        mm[i+4] = e
                        mm[i+5] = f
                        mm[i+6] = g
                        mm[i+7] = h
                end
        end
        isaac()
        randcnt = 256
end

local function generate_isaac(entropy)
        aa = 0
        bb = 0
        cc = 0
        if entropy and #entropy >= 256 then
                for i=1, 256 do
                        randrsl[i] = entropy[i]
                end
        else
                seed_from_mt()
        end
        for i=1, 256 do
                mm[i] = 0
        end
        randinit(true)
        isaac()
        isaac() -- run isaac twice
end

local function getRandom()
        if #mm > 0 then
                return table.remove(mm, 1)
        else
                generate_isaac()
                return table.remove(mm, 1)
        end
end

local function random(min, max)
        if not max then
                max = 2^32-1
        end
        if not min then
                min = 0
        end
        return (getRandom() % max) + min
end

-- Misc functions

local yieldTime = 0
function yield()
    if os.clock() > yieldTime then
        sleep(0.05) -- Don't freak out the CC Emus
        -- Note to self: Don't sleep on real CC, only emu.
        -- Emu can't handle os.queueEvent() os.pullEvent
        yieldTime = os.clock() + 2
    end
end

-- Crypto time!

-- Expose in case people want to generate their own

function modular_pow(base, exponent, modulus)
    local c = 1
    local e = 0
    local progress = 0
    while cmp_lt(e, exponent) do
        progress = progress + 1
        if progress == 100 then
            print(toStr(e) .. "/" .. toStr(exponent))
            progress = 0
        end
        e = add(e, 1)
        c = mod(mul(c, base), modulus)
    end
    return c
end

function genPrivate()
    yield()
    local priv = ""
    for i = 1, 2 do
        priv = priv .. random()
    end
    yield()
    return toBigInt(priv)
end

-- Init crypto variables

-- p and g are public, and have to be the same everywhere

local p = toBigInt("2410312426921032588552076022197566074856950548502459942654116941958108831682612228890093858261341614673227141477904012196503648957050582631942730706805009223062734745341073406696246014589361659774041027169249453200378729434170325843778659198143763193776859869524088940195577346119843545301547043747207749969763750084308926339295559968882457872412993810129130294592999947926365264059284647209730384947211681434464714438488520940127459844288859336526896320919633919", 10)
local g = toBigInt(2)

-- Generation is expensive, so let the user use their own before we make one

local usPriv = nil
local usPub = nil

-- DF Functions

function ensurePrivate()
    if not usPriv then
        usPriv = genPrivate()
    end
end

function ensurePublic()
    ensurePrivate()
    if not usPub then
        yield()
        usPub = modular_pow(g, usPriv, p)
        yield()
    end
end

function getPublic()
    ensurePublic()
    return usPub
end
