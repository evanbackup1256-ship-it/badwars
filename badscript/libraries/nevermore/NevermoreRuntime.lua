--!strict
-- BADWARS_NEVERMORE_RUNTIME_V20
-- Copy-and-paste adaptation layer for Quenty/NevermoreEngine packages.

shared = type(shared) == "table" and shared or {}
if type(shared.BadWarsNevermore) == "table" and shared.BadWarsNevermore.Ready == true then
    return shared.BadWarsNevermore
end

local ROOT = "badscript/libraries/nevermore/"
local REPOSITORY = "evanbackup1256-ship-it/badwars"
local BRANCH = "main"
local ORDER = {
    "Maid",
    "MaidTaskUtils",
    "Promise",
    "Spring",
    "EventHandlerUtils",
    "Signal",
    "BaseObject",
    "ServiceInitLogger",
    "ServiceBag",
    "Motion",
}

local function compiler()
    local env = getgenv and type(getgenv) == "function" and getgenv() or nil
    return (env and env.loadstring) or loadstring
end

local function readLocal(path)
    if type(isfile) ~= "function" or type(readfile) ~= "function" then
        return nil
    end
    local ok, exists = pcall(isfile, path)
    if not ok or not exists then
        return nil
    end
    local readOk, source = pcall(readfile, path)
    return readOk and type(source) == "string" and source ~= "" and source or nil
end

local function readRemote(path)
    local urls = {
        ("https://raw.githubusercontent.com/%s/%s/%s"):format(REPOSITORY, BRANCH, path),
        ("https://github.com/%s/raw/%s/%s"):format(REPOSITORY, BRANCH, path),
    }
    for _, url in ipairs(urls) do
        local ok, source = pcall(function()
            local httpGet = game and game.HttpGet
            if type(httpGet) == "function" then
                return httpGet(game, url, true)
            end
            return game:GetService("HttpService"):GetAsync(url, true)
        end)
        if ok and type(source) == "string" and source ~= "" and source ~= "404: Not Found" then
            return source
        end
    end
    return nil
end

local function cacheSource(path, source)
    if type(writefile) ~= "function" then
        return
    end
    pcall(function()
        if type(isfolder) == "function" and type(makefolder) == "function" then
            if not isfolder("badscript") then makefolder("badscript") end
            if not isfolder("badscript/libraries") then makefolder("badscript/libraries") end
            if not isfolder(ROOT:sub(1, -2)) then makefolder(ROOT:sub(1, -2)) end
        end
        writefile(path, source)
    end)
end

local function loadSource(name)
    local path = ROOT .. name .. ".lua"
    local source = readLocal(path)
    if not source then
        source = readRemote(path)
        if source then cacheSource(path, source) end
    end
    assert(type(source) == "string" and source ~= "", ("Unable to load Nevermore module %s"):format(name))
    local compile = compiler()
    assert(type(compile) == "function", "loadstring unavailable")
    local chunk, compileError = compile(source, "@" .. path)
    assert(chunk, compileError)
    local ok, result = xpcall(chunk, function(err)
        return debug and debug.traceback and debug.traceback(tostring(err), 2) or tostring(err)
    end)
    assert(ok, result)
    return result
end

local modules = type(shared.__BadWarsNevermoreModules) == "table" and shared.__BadWarsNevermoreModules or {}
shared.__BadWarsNevermoreModules = modules
for _, name in ipairs(ORDER) do
    if modules[name] == nil then
        modules[name] = loadSource(name)
    end
end

local Maid = modules.Maid
local Signal = modules.Signal
local Promise = modules.Promise
local Spring = modules.Spring
local ServiceBag = modules.ServiceBag
local Motion = modules.Motion

local LifecycleService = { ServiceName = "BadWarsNevermoreLifecycleService" }
function LifecycleService:Init()
    self.Maid = Maid.new()
    self.Destroying = Signal.new()
    self.Maid:GiveTask(self.Destroying)
end
function LifecycleService:Destroy()
    if self.Destroying then
        self.Destroying:Fire()
    end
    if self.Maid then
        self.Maid:DoCleaning()
    end
end

local MotionService = { ServiceName = "BadWarsNevermoreMotionService" }
function MotionService:Init(serviceBag)
    self.Lifecycle = serviceBag:GetService(LifecycleService)
    self.Motion = Motion
    self.Lifecycle.Maid:GiveTask(function()
        Motion.stopAll()
    end)
end
function MotionService:Target(instance, damping, frequency, properties)
    return self.Motion.target(instance, damping, frequency, properties)
end
function MotionService:Stop(instance, property)
    return self.Motion.stop(instance, property)
end

local AsyncService = { ServiceName = "BadWarsNevermoreAsyncService" }
function AsyncService:Init(serviceBag)
    self.Lifecycle = serviceBag:GetService(LifecycleService)
    self.Promise = Promise
end
function AsyncService:Try(callback)
    return Promise.spawn(function(resolve, reject)
        local ok, result = xpcall(callback, function(err)
            return debug and debug.traceback and debug.traceback(tostring(err), 2) or tostring(err)
        end)
        if ok then
            resolve(result)
        else
            reject(result)
        end
    end)
end

local serviceBag = ServiceBag.new()
local lifecycle = serviceBag:GetService(LifecycleService)
local motionService = serviceBag:GetService(MotionService)
local asyncService = serviceBag:GetService(AsyncService)
serviceBag:Init()
serviceBag:Start()

local Nevermore = {
    Ready = true,
    Version = "20.0.0",
    Source = "Quenty/NevermoreEngine",
    Maid = Maid,
    MaidTaskUtils = modules.MaidTaskUtils,
    Signal = Signal,
    Promise = Promise,
    Spring = Spring,
    ServiceBag = ServiceBag,
    Motion = Motion,
    Services = serviceBag,
    Lifecycle = lifecycle,
    MotionService = motionService,
    AsyncService = asyncService,
}

function Nevermore.newMaid()
    return Maid.new()
end
function Nevermore.newSignal()
    return Signal.new()
end
function Nevermore.newSpring(initial, clock)
    return Spring.new(initial, clock)
end
function Nevermore.promise(callback)
    return Promise.spawn(callback)
end
function Nevermore.Destroy()
    if shared.BadWarsNevermore == Nevermore then
        shared.BadWarsNevermore = nil
    end
    serviceBag:Destroy()
end

shared.BadWarsNevermore = Nevermore
shared.BadWarsSpr = Motion -- compatibility for older BadWars UI paths
return Nevermore
