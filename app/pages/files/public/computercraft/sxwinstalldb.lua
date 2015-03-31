local baseurl = "http://files.fluidnode.com/public/computercraft/"
local programs = {}

programs.cryptomail = {}
programs.cryptomail.name = "CryptoMail"
programs.cryptomail.file = "cryptomail"
programs.cryptomail.url = baseurl .. "mailsec/mailer.lua"
programs.cryptomail.description = "Global encrypted mail"
programs.cryptomail.depends = {"ender"}

programs.ender = {}
programs.ender.name = "Ender"
programs.ender.file = "ender"
programs.ender.url = baseurl .. "endercc.lua"
programs.ender.description = "Global Computercraft Network"
programs.ender.depends = {}

return programs
