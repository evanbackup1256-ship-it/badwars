-- BADWARS_DIAGNOSTICS_BOOTSTRAP_BEGIN
do
    shared = type(shared) == "table" and shared or {}
    shared.__badwars_diagnostic_buffer = type(shared.__badwars_diagnostic_buffer) == "table"
        and shared.__badwars_diagnostic_buffer
        or {}

    local function __badwarsBuffer(level, message, context)
        context = type(context) == "table" and context or {}
        table.insert(shared.__badwars_diagnostic_buffer, {
            severity = level or "ERROR",
            message = tostring(message),
            traceback = context.traceback,
            subsystem = context.subsystem or "Bootstrap",
            module = context.module,
            file = context.file,
            stage = context.stage or "bootstrap",
            fatal = context.fatal == true,
            caught = context.caught ~= false,
            native = context.native ~= false,
        })
    end

    local function __badwarsLoadDiagnostics()
        if type(shared.BadDiagnostics) == "table" then
            return shared.BadDiagnostics
        end

        local source
        local sourceName = "badscript/libraries/diagnostics.lua"

        if type(isfile) == "function" and type(readfile) == "function" then
            local ok, present = pcall(isfile, sourceName)
            if ok and present then
                local readOk, contents = pcall(readfile, sourceName)
                if readOk and type(contents) == "string" and contents ~= "" then
                    source = contents
                elseif not readOk then
                    __badwarsBuffer("WARN", contents, {
                        subsystem = "BootstrapFilesystem",
                        file = sourceName,
                    })
                end
            end
        end

        if not source then
            local urls = {
                "https://github.com/evanbackup1256-ship-it/badwars/raw/main/badscript/libraries/diagnostics.lua",
                "https://raw.githubusercontent.com/evanbackup1256-ship-it/badwars/main/badscript/libraries/diagnostics.lua",
            }
            for _, url in ipairs(urls) do
                local ok, result = pcall(function()
                    local fn = game and game.HttpGet
                    if type(fn) == "function" then
                        return fn(game, url, true)
                    end
                    local service = game:GetService("HttpService")
                    return service:GetAsync(url, true)
                end)
                if ok and type(result) == "string" and result ~= "" and result ~= "404: Not Found" then
                    source = result
                    sourceName = url
                    break
                elseif not ok then
                    __badwarsBuffer("WARN", result, {
                        subsystem = "BootstrapHTTP",
                        file = url,
                    })
                end
            end
        end

        if type(source) ~= "string" or source == "" then
            __badwarsBuffer("ERROR", "Unable to load diagnostics.lua", {
                subsystem = "Bootstrap",
                file = sourceName,
                fatal = false,
            })
            return nil
        end

        local env = getgenv and type(getgenv) == "function" and getgenv() or nil
        local compiler = (env and env.loadstring) or loadstring
        if type(compiler) ~= "function" then
            __badwarsBuffer("ERROR", "loadstring unavailable while loading diagnostics", {
                subsystem = "BootstrapCompiler",
                file = sourceName,
                fatal = true,
            })
            return nil
        end

        local fn, compileError = compiler(source, "@badscript/libraries/diagnostics.lua")
        if not fn then
            __badwarsBuffer("FATAL", compileError, {
                subsystem = "BootstrapCompiler",
                file = sourceName,
                fatal = true,
            })
            return nil
        end

        local ok, result = xpcall(fn, function(err)
            if debug and type(debug.traceback) == "function" then
                return debug.traceback(tostring(err), 2)
            end
            return tostring(err)
        end)
        if not ok then
            __badwarsBuffer("FATAL", result, {
                subsystem = "BootstrapRuntime",
                file = sourceName,
                traceback = result,
                fatal = true,
            })
            return nil
        end
        return result
    end

    __badwarsLoadDiagnostics()
end
-- BADWARS_DIAGNOSTICS_BOOTSTRAP_END-- BadWars by usingINales
-- Entry point
shared.BadWarsDev = true
shared.usingINales = true

local CFG={repo='evanbackup1256-ship-it',name='badwars',branch='main'}
local LOADER_PATH='badscript/loader.lua'

-- Try two URL formats: github.com/raw/ first, raw.githubusercontent.com fallback
local function rawUrl(path)
	local repo=CFG.repo..'/'..CFG.name
	local p=path:gsub(' ','%%20')
	return {'https://github.com/'..repo..'/raw/'..CFG.branch..'/'..p,'https://raw.githubusercontent.com/'..repo..'/'..CFG.branch..'/'..p}
end

local function httpGet(urls)
	for _,url in ipairs(urls) do
		local fn=(game and game.HttpGet)
		if type(fn)~='function' then
			local env=getgenv and type(getgenv)=='function' and getgenv()
			fn=env and env.HttpGet
		end
		if type(fn)=='function' then
			local ok,res=(shared.BadDiagnostics and shared.BadDiagnostics:Capture(function() return fn(game,url,true) end,{subsystem='HTTP',module='entry',file=url,stage='entry-download'}) or pcall(fn,game,url,true))
			if ok and type(res)=='string' and #res>0 then return res,url end
		end
		local ok,res=pcall(function()
			return cloneref(game:GetService('HttpService')):GetAsync(url,true)
		end)
		if ok and type(res)=='string' and #res>0 then return res,url end
	end
	return nil,nil
end

local function isNotFoundBody(body)
	if type(body)~='string' then return false end
	local trimmed=body:match('^%s*(.-)%s*$')
	return trimmed=='404: Not Found' or trimmed=='{"message":"Not Found"}' or (#trimmed<200 and trimmed:find('"message"%s*:%s*"Not Found"')~=nil)
end

warn('BadWars: [URL DIAGNOSTICS]')
local urls=rawUrl(LOADER_PATH)
warn('  Repository:   '..CFG.repo..'/'..CFG.name)
warn('  Branch:       '..CFG.branch)
warn('  File:         '..LOADER_PATH)
warn('  URLs to try:')
for i,u in ipairs(urls) do warn('    ['..i..'] '..u) end

local ls=loadstring or (function() local g=getgenv;if type(g)=='function'then g=g()end;return g and g.loadstring end)()
if type(ls)~='function' then local m='BadWars: loadstring not available';warn(m);error(m,0) end

local loaderCode,usedUrl=httpGet(urls)
if loaderCode==nil then
	local m='BadWars: All HTTP methods failed for all URL formats.'
	warn(m);error(m,0)
end
if type(loaderCode)~='string' or loaderCode=='' then
	local m='BadWars: Empty response from all URL formats.'
	warn(m);error(m,0)
end
-- Check for 404 in both GitHub raw format and API format
if isNotFoundBody(loaderCode) then
	warn('BadWars: [404 RESPONSE BODY - first 500 chars]')
	warn(loaderCode:sub(1,500))
	warn('BadWars: [END 404 BODY]')
	local m='FILE NOT FOUND at '..tostring(usedUrl)
	warn(m);error(m,0)
end
warn('BadWars: Downloaded from '..tostring(usedUrl)..' ('..#loaderCode..' bytes)')

local loaderFunc,loaderErr=ls(loaderCode,'badwars-loader')
if not loaderFunc then local m='BadWars: compile error: '..tostring(loaderErr);warn(m);error(m,0) end

local ok,result=xpcall(loaderFunc,function(err) local d=shared.BadDiagnostics return d and d:Traceback(err,2) or ((debug and debug.traceback) and debug.traceback(tostring(err),2) or tostring(err)) end)
if not ok then local m='BadWars: Loader error: '..tostring(result);warn(m);error(m,0) end

return result
