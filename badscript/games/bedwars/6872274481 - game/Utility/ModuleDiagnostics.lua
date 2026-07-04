local ModuleDiagnostics
local CopyReport

local function healthReport()
    local compatibility = Bad.BedWarsCompatibility
    if type(compatibility) == "table" and type(compatibility.AuditAll) == "function" then
        local ok, report = pcall(compatibility.AuditAll, compatibility)
        if ok and type(report) == "table" then
            return report
        end
    end
    return shared.__badwars_module_health or {
        Total = 0,
        Ready = 0,
        Failed = 0,
        Issues = {},
        Modules = {},
    }
end

local function encodeReport(report)
    local encoded
    pcall(function()
        encoded = game:GetService("HttpService"):JSONEncode(report)
    end)
    return encoded or tostring(report)
end

ModuleDiagnostics = Bad.Categories.Utility:CreateModule({
    Name = "ModuleDiagnostics",
    Function = function(callback)
        if not callback then
            return
        end

        local report = healthReport()
        local issueCount = 0
        for _ in pairs(report.Issues or {}) do
            issueCount += 1
        end

        Bad:CreateNotification(
            "Module Diagnostics",
            string.format(
                "%d loaded, %d ready, %d failed, %d contract warning%s.",
                tonumber(report.Total) or 0,
                tonumber(report.Ready) or 0,
                tonumber(report.Failed) or 0,
                issueCount,
                issueCount == 1 and "" or "s"
            ),
            7,
            (tonumber(report.Failed) or 0) > 0 and "warning" or "success"
        )

        if CopyReport and CopyReport.Enabled then
            local encoded = encodeReport(report)
            pcall(function()
                if type(setclipboard) == "function" then
                    setclipboard(encoded)
                elseif type(toclipboard) == "function" then
                    toclipboard(encoded)
                end
            end)
        end

        task.defer(function()
            if ModuleDiagnostics.Enabled then
                ModuleDiagnostics:Toggle()
            end
        end)
    end,
    Tooltip = "Runs the BedWars module health scan.",
})

CopyReport = ModuleDiagnostics:CreateToggle({
    Name = "Copy report",
    Default = true,
    Tooltip = "Copies the JSON health report to your clipboard.",
})
