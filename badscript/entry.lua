-- BadWars by usingINales
-- Entirely MINE. Custom dev build.
shared.BadWarsDev = true
shared.usingINales = true

-- Safe loadstring for various executors
local httpget = game.HttpGet
local ls = loadstring or (getgenv and getgenv().loadstring) or function(str) return loadstring(str) end
ls(safeHttpGet(game, "https://raw.githubusercontent.com/evanbackup1256-ship-it/badwars/main/badscript/loader.lua", true))()









