local Security = {
	Version = '1.0.0',
	BuildId = 'badwars-security-2026-07-01',
	Verified = false,
	Status = 'not_started',
	Permissions = {},
	Events = {},
	Config = {}
}

local httpService = cloneref(game:GetService('HttpService'))
local playersService = cloneref(game:GetService('Players'))

local function getGlobal()
	local g = getgenv
	if type(g) == 'function' then
		local ok, res = pcall(g)
		return ok and res or nil
	end
	return nil
end

local function mergeConfig()
	local g = getGlobal() or {}
	local cfg = type(shared.BadWarsSecurity) == 'table' and shared.BadWarsSecurity or {}
	local apiUrl = cfg.ApiUrl or shared.BadWarsLicenseApi or g.BadWarsLicenseApi
	local mode = cfg.Mode or shared.BadWarsSecurityMode or g.BadWarsSecurityMode
	if not mode then
		mode = apiUrl and 'production' or 'development'
	end

	return {
		Enabled = cfg.Enabled ~= false,
		Mode = mode,
		ApiUrl = apiUrl,
		LicenseKey = cfg.LicenseKey or shared.BadWarsLicenseKey or g.BadWarsLicenseKey,
		ReleaseChannel = cfg.ReleaseChannel or shared.BadWarsReleaseChannel or g.BadWarsReleaseChannel or 'main',
		BuildId = cfg.BuildId or shared.BadWarsBuildId or Security.BuildId,
		Timeout = tonumber(cfg.Timeout) or 10,
		MaxRetries = tonumber(cfg.MaxRetries) or 2,
		Backoff = tonumber(cfg.Backoff) or 0.6,
		RequireSignature = cfg.RequireSignature == true,
		VerifySignature = cfg.VerifySignature or shared.BadWarsVerifySignature or g.BadWarsVerifySignature,
		AllowDevelopmentBypass = cfg.AllowDevelopmentBypass ~= false,
		RequiredFiles = cfg.RequiredFiles or {
			'badscript/main.lua',
			'badscript/security.lua',
			'badscript/guis/new/gui.lua'
		}
	}
end

local function now()
	return os.time()
end

local function nonce()
	return tostring(math.floor(now()))..'-'..tostring(math.random(100000, 999999))..'-'..tostring(game.JobId or 'local')
end

function Security:Log(level, message, extra)
	local entry = {
		level = level or 'Info',
		message = tostring(message or ''),
		time = now(),
		extra = extra
	}
	table.insert(self.Events, entry)
	if #self.Events > 100 then
		table.remove(self.Events, 1)
	end
	if shared.BadStatus then
		shared.BadStatus((level == 'Error' and 'ERROR security: ' or 'security: ')..entry.message, level == 'Error')
	end
	local api = shared.Bad
	if api and type(api.AddLog) == 'function' then
		pcall(function()
			api.AddLog(level or 'Info', 'Security: '..entry.message, extra)
		end)
	elseif api and type(api.CreateNotification) == 'function' and (level == 'Error' or level == 'Warning') then
		pcall(function()
			api:CreateNotification('BadWars Security', entry.message, 10, level == 'Error' and 'alert' or 'info')
		end)
	end
end

function Security:Fail(status, message, extra)
	self.Status = status or 'failed'
	self.Verified = false
	self:Log('Error', message or self.Status, extra)
	return false, self.Status
end

function Security:Allow(status, message, permissions)
	self.Status = status or 'valid'
	self.Verified = true
	self.Permissions = type(permissions) == 'table' and permissions or {}
	self:Log('Info', message or 'license verified')
	return true, self.Status
end

function Security:ValidateEnvironment()
	local missing = {}
	for _, pair in {
		{'game', game},
		{'HttpService', httpService},
		{'Players.LocalPlayer', playersService.LocalPlayer},
		{'pcall', pcall},
		{'task', task}
	} do
		if not pair[2] then
			table.insert(missing, pair[1])
		end
	end
	if #missing > 0 then
		return self:Fail('unsupported', 'environment missing: '..table.concat(missing, ', '))
	end
	return true
end

function Security:RunSelfChecks()
	if shared.BadSecurityStarted and not 	shared.BadReload then
		return self:Fail('tampered', 'duplicate security initialization detected')
	end
	shared.BadSecurityStarted = true

	local issues = {}
	for _, path in self.Config.RequiredFiles do
		local ok, contents = pcall(function()
			return isfile(path) and readfile(path) or nil
		end)
		if not ok or type(contents) ~= 'string' or contents == '' then
			table.insert(issues, 'missing or empty '..path)
		elseif contents:match('^%s*404:%s*Not Found%s*$') then
			table.insert(issues, '404 cached in '..path)
		end
	end
	if #issues > 0 then
		return self:Fail('integrity_failed', table.concat(issues, '; '))
	end

	self:Log('Info', 'deep self-checks complete')
	return true
end

local function encodeQuery(data)
	local parts = {}
	for key, value in pairs(data) do
		table.insert(parts, httpService:UrlEncode(tostring(key))..'='..httpService:UrlEncode(tostring(value)))
	end
	return table.concat(parts, '&')
end

function Security:Request(payload)
	local body = httpService:JSONEncode(payload)
	local synTable = type(syn) == 'table' and syn or nil
	local req = (synTable and synTable.request) or http_request or request
	if type(req) == 'function' then
		local response = req({
			Url = self.Config.ApiUrl,
			Method = 'POST',
			Headers = {
				['Content-Type'] = 'application/json',
				['Accept'] = 'application/json'
			},
			Body = body
		})
		return response and (response.Body or response.body), response and (response.StatusCode or response.status_code or response.Status)
	end

	local url = self.Config.ApiUrl
	url ..= (url:find('?', 1, true) and '&' or '?')..encodeQuery(payload)
	return game:HttpGet(url, true), 200
end

function Security:DecodeResponse(raw)
	if type(raw) ~= 'string' or raw == '' then
		return nil, 'empty API response'
	end
	local ok, data = pcall(function()
		return httpService:JSONDecode(raw)
	end)
	if not ok or type(data) ~= 'table' then
		return nil, 'malformed API response'
	end
	return data
end

function Security:VerifyResponse(data, requestNonce)
	local status = tostring(data.status or data.state or ''):lower()
	local validStates = {
		valid = true,
		expired = true,
		banned = true,
		revoked = true,
		rate_limited = true,
		unsupported = true,
		api_unavailable = true
	}
	if not validStates[status] then
		return false, 'malformed_response', 'unsupported license status'
	end

	if data.nonce and tostring(data.nonce) ~= requestNonce then
		return false, 'replay_detected', 'nonce mismatch'
	end

	local responseTime = tonumber(data.timestamp)
	if responseTime and math.abs(now() - responseTime) > 300 then
		return false, 'stale_response', 'stale API timestamp'
	end

	if self.Config.RequireSignature or data.signature then
		if type(self.Config.VerifySignature) ~= 'function' then
			return false, 'signature_unsupported', 'signature required but no verifier is configured'
		end
		local ok, verified = pcall(self.Config.VerifySignature, data)
		if not ok or verified ~= true then
			return false, 'signature_invalid', 'API response signature is invalid'
		end
	end

	if status ~= 'valid' then
		return false, status, data.message or ('license '..status)
	end

	return true, 'valid', data.message or 'license verified'
end

function Security:VerifyLicense()
	if self.Config.Mode ~= 'production' then
		if self.Config.AllowDevelopmentBypass then
			return self:Allow('development', 'development mode - license API not enforced', {
				allowAll = true,
				modules = {allowAll = true},
				features = {allowAll = true}
			})
		end
		return self:Fail('license_required', 'development bypass disabled and production API is not configured')
	end

	if type(self.Config.ApiUrl) ~= 'string' or not self.Config.ApiUrl:match('^https://') then
		return self:Fail('api_unavailable', 'missing HTTPS license API endpoint')
	end
	if type(self.Config.LicenseKey) ~= 'string' or self.Config.LicenseKey == '' then
		return self:Fail('license_required', 'missing license key')
	end

	local requestNonce = nonce()
	local payload = {
		license = self.Config.LicenseKey,
		userId = playersService.LocalPlayer.UserId,
		username = playersService.LocalPlayer.Name,
		placeId = game.PlaceId,
		gameId = game.GameId,
		buildId = self.Config.BuildId,
		channel = self.Config.ReleaseChannel,
		nonce = requestNonce,
		timestamp = now()
	}

	local lastErr
	for attempt = 1, math.max(1, self.Config.MaxRetries) do
		self:Log('Info', 'contacting license API (attempt '..attempt..')')
		local ok, raw, code = pcall(function()
			local body, statusCode = self:Request(payload)
			return body, statusCode
		end)
		if ok then
			local data, decodeErr = self:DecodeResponse(raw)
			if data then
				local valid, status, message = self:VerifyResponse(data, requestNonce)
				if valid then
					return self:Allow('valid', message, data.permissions or data.features or {})
				end
				return self:Fail(status, message)
			end
			lastErr = decodeErr or ('HTTP '..tostring(code))
		else
			lastErr = raw
		end
		task.wait(self.Config.Backoff * attempt)
	end

	return self:Fail('api_unavailable', 'license API unavailable: '..tostring(lastErr))
end

local function listAllows(list, value)
	if type(list) ~= 'table' then return nil end
	if list[value] == true then return true end
	for _, item in list do
		if item == value then return true end
	end
	return false
end

function Security:IsModuleAllowed(name, category)
	if not self.Verified then return false, 'license not verified' end
	local perms = self.Permissions or {}
	if perms.allowAll == true then return true end

	local gameRules = perms.games
	if type(gameRules) == 'table' then
		local allowedGame = listAllows(gameRules.allowed, tostring(game.PlaceId)) or listAllows(gameRules.allowed, game.PlaceId)
		if gameRules.allowed and not allowedGame then return false, 'game not licensed' end
		if listAllows(gameRules.blocked, tostring(game.PlaceId)) or listAllows(gameRules.blocked, game.PlaceId) then return false, 'game blocked' end
	end

	local modules = perms.modules or perms
	if type(modules) == 'table' then
		if modules.allowAll == true then return true end
		if listAllows(modules.blocked, name) or listAllows(modules.blockedCategories, category) then
			return false, 'module blocked'
		end
		if modules.allowed or modules.allowedCategories then
			return listAllows(modules.allowed, name) or listAllows(modules.allowedCategories, category), 'module not licensed'
		end
	end

	return true
end

function Security:ApplyToApi(api)
	api.Security = self
	shared.BadSecurity = self
	self:Log('Info', 'permissions applied')
	return true
end

function Security:Start(api)
	self.Config = mergeConfig()
	shared.BadSecurity = self
	if not self.Config.Enabled then
		return self:Allow('disabled', 'security disabled by configuration', {allowAll = true})
	end
	local ok = self:ValidateEnvironment()
	if not ok then return false, self.Status end
	ok = self:RunSelfChecks()
	if not ok then return false, self.Status end
	ok = self:VerifyLicense()
	if not ok then return false, self.Status end
	if api then
		self:ApplyToApi(api)
	end
	return true, self.Status
end

return Security
