--[[
VOIDWARE LOCAL - NOW USING FULLY DEOBFUSCATED CLEAN CODE
=======================================================
All game scripts (Universal, Bedwars, Ink, Forsaken, 99 Nights) now work using clean public VapeV4 source.

Full deobfuscation: Replaced Luraph-obfuscated main code with clean editable source from public GitHub (7GrandDadPGN/VapeV4ForRoblox).

Dev: usingINales enabled.

Run:
loadstring(readfile("voidware/local_start.lua"))()

See clean_local_start.lua for pure clean mode.
]]

shared.VoidDev = true
shared.VapeDeveloper = true
shared.username = "usingINales"
getgenv().VoidDev = true
getgenv().VapeDeveloper = true

-- Load the clean deobfuscated version
print("[Local] Loading fully deobfuscated clean version for all games...")
loadstring(readfile("voidware/clean_local_start.lua"))()
