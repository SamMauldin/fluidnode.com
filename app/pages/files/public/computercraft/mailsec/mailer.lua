-- TODO: Use EnderCC, and send/receive strings instead of tables. textutils.serialize comes to use.
-- Also, is there a way to work without crypto accels?

local crypto = false

for k, v in pairs(peripheral.getNames()) do
	if peripheral.getType(v) == "cryptographic accelerator" then
		crypto = peripheral.wrap(v)
	end
end

if not http then
	error("HTTP must be enabled to use CryptoMail. Usage with an HTTP whitelist is not supported.", 0)
end

if not ender then
	os.loadAPI("ender")
	os.loadAPI("/ender")
	os.loadAPI("/System/programs/pkg/ender")
	if not ender then
		print("Downloading EnderCC...")
		local ecc = http.get("http://files.fluidnode.com/public/computercraft/endercc.lua")
		if ecc then
			local fh = fs.open("/ender", "w")
			fh.write(ecc.readAll())
			fh.close()
			os.loadAPI("ender")
		else
			error("Unable to download EnderCC", 0)
		end
	end
end

if not crypto then
	error("Please attach a cryptographic accelerator to use CryptoMail", 0)
end

local serverpub = "X.509:MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCmHZBHHPStH/10bN3ebW32OoUIZWTNkkI2dTdOYuS8hyUu6tDJ+z7eo5kwJ649mDlX8qt45o2Zlntc/UDxYpFW67SBjNYTUpPgoTSqBPQWdJcezucMmfC2pPhinsay03o2mL0UDBU5FkFVQvgfQwfVvpCqj3ng86IUkaCYY9VI7wIDAQAB"
serverpub = crypto.decodeKey("RSA", serverpub)

common = {}

local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

-- Base 64 Encoding
function common.benc(data)
    return ((data:gsub('.', function(x) 
        local r,b='',x:byte()
        for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
        return r;
    end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if (#x < 6) then return '' end
        local c=0
        for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
        return b:sub(c+1,c+1)
    end)..({ '', '==', '=' })[#data%3+1])
end

-- Base 64 Decoding
function common.bdec(data)
    data = string.gsub(data, '[^'..b..'=]', '')
    return (data:gsub('.', function(x)
        if (x == '=') then return '' end
        local r,f='',(b:find(x)-1)
        for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
        return r;
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if (#x ~= 8) then return '' end
        local c=0
        for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
        return string.char(c)
    end))
end

function common.sanitize(str)
	str = string.gsub(str, " ", ":")
	str = string.gsub(str, "/", ":")
	str = string.gsub(str, "%.", ":")
	return str
end

function common.genPair()
	return crypto.generateKeyPair("RSA", 1024)
end

function common.decodeKey(key)
	local stat, res = pcall(function()
		return crypto.decodeKey("RSA", key)
	end)
	return res
end

function common.readFile(path)
	if fs.exists(path) then
		local fh = fs.open(path, "r")
		local c = fh.readAll()
		fh.close()
		return c
	end
	return nil
end

function common.writeFile(path, contents)
	local fh = fs.open(path, "w")
	fh.write(contents)
	fh.close()
end

function common.loadKey(path)
	if fs.exists(path) then
		local fh = fs.open(path, "r")
		local key = fh.readAll()
		fh.close()
		return common.decodeKey(key)
	end
	return false
end

function common.decrypt(key, msg)
	local stat, res = pcall(function()
		return key.decrypt("RSA", msg)
	end)
	if stat then
		return res
	else
		return nil
	end
end

function common.fragmentEncrypt(msg, key)
	msg = common.benc(msg)
	local shards = math.ceil(#msg / 99)
	local final = {}
	for i = 1, shards do
		local shard = msg:sub(((i - 1) * 99) + 1, i * 99)
		final[#final + 1] = key.encrypt("RSA", shard)
	end
	return textutils.serialize(final)
end

function common.fragmentDecrypt(cp, key)
	local cp = textutils.unserialize(cp)
	if not common.decrypt(key, cp[1]) then
		return false
	end
	local msg = ""
	for k, v in pairs(cp) do
		msg = msg .. key.decrypt("RSA", v)
	end
	return common.bdec(msg)
end

function common.encodeMessage(toPub, fromPriv, fromPub, contents, id)
	local msg = {}
	msg.to = toPub.encode()
	msg.from = fromPub.encode()
	msg.contents = common.fragmentEncrypt(textutils.serialize(contents), toPub)
	if id then
		msg.id = id
	else
		msg.id = tostring(math.random()) .. tostring(math.random()) .. tostring(math.random())
	end
	msg.verif = common.fragmentEncrypt(msg.to .. ":" .. msg.from .. ":" .. msg.contents .. ":" .. msg.id, fromPriv)
	return msg, id
end

function common.decodeMessage(priv, msg, id)
	if msg.to and msg.from and msg.contents and msg.id and msg.verif then
		if id then
			if msg.id ~= id then
				return false
			end
		end
		if common.decodeKey(msg.to) and common.decodeKey(msg.from) then
			if common.fragmentDecrypt(msg.verif, common.decodeKey(msg.from)) and common.fragmentDecrypt(msg.contents, priv) then
				local verif = common.fragmentDecrypt(msg.verif, common.decodeKey(msg.from))
				if verif == (msg.to .. ":" .. msg.from .. ":" .. msg.contents .. ":" .. msg.id) then
					if shell then
						return true, msg.from, textutils.unserialize(common.fragmentDecrypt(msg.contents, priv)), msg.id
					elseif not fs.exists("/msgs/" .. msg.id) then
						fs.makeDir("/msgs/" .. msg.id)
						return true, msg.from, textutils.unserialize(common.fragmentDecrypt(msg.contents, priv)), msg.id
					end
				end
			end
		end
	end
	return false
end

client = {}

client.pub, client.priv = common.genPair()
client.key = nil
client.user = nil

function client.getMessage(id)
	while true do
		local _, msg = ender.receive("cryptomail")
		if textutils.unserialize(msg or "") then
			local stat, from, contents = common.decodeMessage(client.priv, textutils.unserialize(msg), id)
			if stat and from == serverpub.encode() then
				return contents
			end
		end
	end
end

function client.sendMessage(contents)
	local msg, id = common.encodeMessage(serverpub, client.priv, client.pub, contents)
	ender.send("cryptomail", textutils.serialize(msg))
	return id
end

function client.register(user, pass)
	local cmd = {}
	cmd.cmd = "REGISTER"
	cmd.user = user
	cmd.password = pass
	local id = client.sendMessage(cmd)
	local res = client.getMessage(id)
	return res.status
end

function client.authenticate(user, pass)
	local cmd = {}
	cmd.cmd = "AUTH"
	cmd.user = user
	cmd.password = pass
	local id = client.sendMessage(cmd)
	local res = client.getMessage(id)
	if res.key then
		client.key = res.key
		client.user = user
		return true
	end
	return false
end

function client.getInbox()
	local cmd = {}
	cmd.cmd = "INBOX"
	cmd.user = client.user
	cmd.key = client.key
	local id = client.sendMessage(cmd)
	local res = client.getMessage(id)
	return res.inbox
end

function client.setInbox(db)
	local cmd = {}
	cmd.cmd = "UPDINBOX"
	cmd.user = client.user
	cmd.key = client.key
	cmd.newdb = db
	local id = client.sendMessage(cmd)
	local res = client.getMessage(id)
	return res.status
end

function client.sendMail(to, subject, msg)
	local cmd = {}
	cmd.cmd = "SEND"
	cmd.user = client.user
	cmd.key = client.key
	cmd.to = to
	cmd.subject = subject
	cmd.message = msg
	local id = client.sendMessage(cmd)
	local res = client.getMessage(id)
	return res.status
end

function client.clear()
	term.setBackgroundColor(colors.white)
	term.setTextColor(colors.black)
	term.clear()
	term.setCursorPos(1, 1)
	if client.user then
		term.write("CryptoMail - " .. client.user)
	else
		term.write("CryptoMail")
	end
	term.setCursorPos(1, 3)
end

function client.getKey(max)
	while true do
		local _, char = os.pullEvent("char")
		if tonumber(char) then
			local num = tonumber(char)
			if num <= max and num >= 1 then
				return num
			end
		end
	end
end

function client.run()
	while true do
		client.clear()
		print("[1] Login")
		print("[2] Register")
		print("[3] Exit")
		local num
		if client.user then
			num = 1
		else
			num = client.getKey(4)
		end
		if num == 1 then
			local stat
			if not client.user then
				client.clear()
				print("Logging in")
				write("User: ")
				local name = read()
				write("Pass: ")
				local pass = read("*")
				print("")
				print("Contacting server...")
				stat = client.authenticate(name, pass)
			else
				stat = true
			end
			if stat then
				client.clear()
				print("[1] Inbox")
				print("[2] Compose")
				print("[3] Logout")
				local num = client.getKey(3)
				if num == 1 then
					client.clear()
					print("Getting inbox...")
					local exit = false
					local msgs = client.getInbox()
					if not msgs then
						exit = true
						print("Error getting mail.")
						sleep(2)
					end
					
					if #msgs == 0 then
						exit = true
						print("No mail.")
						sleep(2)
					end
					
					local cmsg = 1
					while not exit do
						client.clear()
						print("From: " .. msgs[cmsg].from)
						print("About: " .. msgs[cmsg].subject)
						print(msgs[cmsg].message)
						print("[1] Delete")
						print("[2] Back")
						print("[3-4] Last/next message")
						local num = client.getKey(4)
						if num == 1 then
							if #msgs == 1 then
								exit = true
							end
							newdb = {}
							for k, v in pairs(msgs) do
								if cmsg ~= k then
									newdb[#newdb + 1] = v
								end
							end
							client.clear()
							print("Deleting message...")
							local stat = client.setInbox(newdb)
							if not stat then
								exit = true
								client.clear()
								print("Failed to delete message")
								sleep(2)
							end
							cmsg = 1
							msgs = newdb
						elseif num == 2 then
							exit = true
						elseif num == 3 then
							if cmsg == 1 then
								cmsg = #msgs
							else
								cmsg = cmsg - 1
							end
						elseif num == 4 then
							if cmsg == #msgs then
								cmsg = 1
							else
								cmsg = cmsg + 1
							end
						end
					end
				elseif num == 2 then
					client.clear()
					print("Writing letter")
					write("To: ")
					local to = read()
					write("Subject: ")
					local subject = read()
					shell.run("/rom/programs/edit", "/CryptoMailMessage")
					if fs.exists("/CryptoMailMessage") then
						client.clear()
						print("Sending your message...")
						client.sendMail(to, subject, common.readFile("/CryptoMailMessage"))
						fs.delete("/CryptoMailMessage")
					end
				elseif num == 3 then
					client.user = nil
					client.key = nil
				end
			else
				print("Invalid login.")
				sleep(2)
			end
		elseif num == 2 then
			client.clear()
			print("Making new account")
			write("User: ")
			local name = read()
			write("Pass: ")
			local pass = read("*")
			print("")
			print("Contacting server...")
			local stat = client.register(name, pass)
			if stat then
				print("Account created!")
				sleep(2)
			else
				print("Account creation failed.")
				sleep(2)
			end
		elseif num == 3 then
			term.setBackgroundColor(colors.black)
			term.setTextColor(colors.white)
			term.clear()
			term.setCursorPos(1, 1)
			print("Goodbye!")
			print("Thanks for using CryptoMail!")
			return
		end
	end
end

server = {}

function server.genPass()
	local pass = ""
	pass = pass .. tostring(math.random(10)) .. tostring(math.random(10)) .. tostring(math.random(10)) .. tostring(math.random(10))
	pass = pass .. ":" .. tostring(math.random(10)) .. tostring(math.random(10)) .. tostring(math.random(10)) .. tostring(math.random(10))
	pass = pass .. ":" .. tostring(math.random(10)) .. tostring(math.random(10)) .. tostring(math.random(10)) .. tostring(math.random(10))
	pass = pass .. ":" .. tostring(math.random(10)) .. tostring(math.random(10)) .. tostring(math.random(10)) .. tostring(math.random(10))
	pass = pass .. ":" .. tostring(math.random(10)) .. tostring(math.random(10)) .. tostring(math.random(10)) .. tostring(math.random(10))
	return pass
end

function server.checkauth(data, user, key)
	if fs.exists(data .. "/users/" .. common.sanitize(user)) then
		if common.readFile(data .. "/users/" .. common.sanitize(user) .. "/key") == key then
			return true
		end
	end
	return false
end

function server.host(pub, priv, data)
	os.pullEvent = os.pullEventRaw
	local pub = common.loadKey(pub)
	assert(pub)
	local priv = common.loadKey(priv)
	assert(priv)
	while true do
		local _, msg = ender.receive("cryptomail")
		if textutils.unserialize(msg or "") then
			msg = textutils.unserialize(msg)
			local stat, from, contents, id = common.decodeMessage(priv, msg)
			if stat and type(contents) == "table" then
				if contents.cmd then
					if (contents.cmd ~= "AUTH" or contents.cmd ~= "REGISTER") and contents.key and contents.user then
						if server.checkauth(data, contents.user, contents.key) then
							if contents.cmd == "INBOX" then
								local res = {}
								res.status = true
								res.inbox = textutils.unserialize(common.readFile(data .. "/users/" .. common.sanitize(contents.user) .. "/db"))
								ender.send("cryptomail", textutils.serialize(common.encodeMessage(common.decodeKey(from), priv, pub, res, id)))
								print(common.sanitize(contents.user) .. " checked their mail")
							elseif contents.cmd == "UPDINBOX" and contents.newdb then
								local res = {}
								res.status = true
								common.writeFile(data .. "/users/" .. common.sanitize(contents.user) .. "/db", textutils.serialize(contents.newdb))
								ender.send("cryptomail", textutils.serialize(common.encodeMessage(common.decodeKey(from), priv, pub, res, id)))
								print(common.sanitize(contents.user) .. " changed their inbox")
							elseif contents.cmd == "SEND" and contents.to and contents.subject and contents.message then
								if fs.exists(data .. "/users/" .. common.sanitize(contents.to)) and contents.to ~= "" then
									local res = {}
									res.status = true
									ender.send("cryptomail", textutils.serialize(common.encodeMessage(common.decodeKey(from), priv, pub, res, id)))
									local db = textutils.unserialize(common.readFile(data .. "/users/" .. common.sanitize(contents.to) .. "/db"))
									db[#db + 1] = {}
									db[#db].from = contents.user
									db[#db].subject = contents.subject
									db[#db].message = contents.message
									common.writeFile(data .. "/users/" .. common.sanitize(contents.to) .. "/db", textutils.serialize(db))
									print(common.sanitize(contents.user) .. " sent mail to " .. common.sanitize(contents.to))
								else
									local res = {}
									res.status = false
									res.msg = "User does not exists"
									ender.send("cryptomail", textutils.serialize(common.encodeMessage(common.decodeKey(from), priv, pub, res, id)))
									print(common.sanitize(contents.user) .. " failed to send message to nonexistant user " .. common.sanitize(contents.to))
								end
							end
						else
							local res = {}
							res.status = false
							res.msg = "Invalid key"
							ender.send("cryptomail", textutils.serialize(common.encodeMessage(common.decodeKey(from), priv, pub, res, id)))
							print("Invalid key for " .. common.sanitize(contents.user))
						end
					else
						if contents.cmd == "AUTH" and contents.user and contents.password then
							local user = common.sanitize(contents.user)
							if fs.exists(data .. "/users/" .. common.sanitize(contents.user)) then
								local pass = common.readFile(data .. "/users/" .. common.sanitize(contents.user) .. "/pass")
								if contents.password == pass then
									local res = {}
									res.status = true
									res.key = common.readFile(data .. "/users/" .. common.sanitize(contents.user) .. "/key")
									ender.send("cryptomail", textutils.serialize(common.encodeMessage(common.decodeKey(from), priv, pub, res, id)))
									print(user .. " logged in")
								else
									local res = {}
									res.status = false
									res.error = "Wrong password"
									ender.send("cryptomail", textutils.serialize(common.encodeMessage(common.decodeKey(from), priv, pub, res, id)))
									print("Failed auth for " .. user)
								end
							else
								local res = {}
								res.status = false
								res.msg = "User does not exists"
								ender.send("cryptomail", textutils.serialize(common.encodeMessage(common.decodeKey(from), priv, pub, res, id)))
								print("Failed auth for nonexistant user " .. user)
							end
						elseif contents.cmd == "REGISTER" and contents.user and contents.password then
							local user = common.sanitize(contents.user)
							if not fs.exists(data .. "/users/" .. common.sanitize(contents.user)) and contents.user ~= "" then
								fs.makeDir(data .. "/users/" .. common.sanitize(contents.user))
								local key = server.genPass()
								common.writeFile(data .. "/users/" .. common.sanitize(contents.user) .. "/pass", contents.password)
								common.writeFile(data .. "/users/" .. common.sanitize(contents.user) .. "/key", key)
								common.writeFile(data .. "/users/" .. common.sanitize(contents.user) .. "/db", "{}")
								local res = {}
								res.status = true
								ender.send("cryptomail", textutils.serialize(common.encodeMessage(common.decodeKey(from), priv, pub, res, id)))
								print("User " .. user .. " created")
							else
								local res = {}
								res.status = false
								res.msg = "User already exists"
								ender.send("cryptomail", textutils.serialize(common.encodeMessage(common.decodeKey(from), priv, pub, res, id)))
								print("User " .. user .. " already in use")
							end
						end
					end
				end
			end
		end
	end
end

if shell then
	client.run()
end

-- Copyright Sam Mauldin, 2014. All rights reserved. No warranty is provided.
-- You may share and edit this code as long as you give credit to me and link to the original at http://files.fluidnode.com/public/computercraft
-- Thank you.
