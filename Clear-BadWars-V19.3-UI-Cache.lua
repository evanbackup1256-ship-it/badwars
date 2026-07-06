pcall(function()
    if shared.Bad and type(shared.Bad.Uninject) == "function" then
        shared.Bad:Uninject()
    end
end)

pcall(function()
    if shared.BadDiagnostics
        and type(shared.BadDiagnostics.Destroy) == "function"
    then
        shared.BadDiagnostics:Destroy("v19.3-ui-stabilization")
    end
end)

local cachedFiles = {
    "badscript/guis/new/gui.lua",
    "badscript/libraries/diagnostics.lua",
    "badscript/NewMainScript.lua",
    "badscript/loader.lua",
    "badscript/main.lua",
}

for _, path in ipairs(cachedFiles) do
    pcall(function()
        if type(isfile) == "function"
            and type(delfile) == "function"
            and isfile(path)
        then
            delfile(path)
            print("[BadWars Cache] Removed:", path)
        end
    end)
end

shared.Bad = nil
shared.vape = nil
shared.BadReload = nil
shared.BadIndependent = nil
shared.BadWarsLoader = nil
shared.BadwarsLoader = nil
shared.BadDiagnostics = nil
shared.BadStatus = nil
shared.BadStatusGui = nil
shared.CACHED_ICON_LIBRARY = nil
shared.__badwars_runtime_errors = nil
shared.__badwars_diagnostic_buffer = nil

print("[BadWars] V19.3 UI cache cleared. Reinject now.")