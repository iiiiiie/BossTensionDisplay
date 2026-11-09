-- Read-only reflection inspection. Never writes a combat property or readout.
local Probe = {}
local function log(s) print('[BossTensionDisplay][Probe] ' .. tostring(s) .. '\n') end
local function valid(o)
    if o == nil then return false end
    local ok, answer = pcall(function() return o:IsValid() end)
    return ok and answer == true
end
local paths = {
    '/Script/TensionMeter.TensionReadout',
    '/Script/TensionMeter.TensionEventRecord',
    '/Script/TensionMeter.OutcomeRecord',
    '/Script/TensionMeter.TensionMultiplierContribution',
    '/Script/TensionMeter.BossSpecificState',
    '/Script/TensionMeter.PlayerGlobalState',
    '/Script/TensionMeter.TensionSession',
    '/Script/TensionMeter.TensionWorldSubsystem',
    '/Script/TensionMeter.TensionLibrary',
    '/Script/TensionMeter.TensionProfile',
    '/Script/TensionMeter.TensionWorldSubsystem:GetReadout',
    '/Script/TensionMeter.TensionWorldSubsystem:HasActiveSessionForBoss',
    '/Script/TensionMeter.TensionLibrary:GetTensionReadout',
    '/Script/TensionMeter.TensionLibrary:HasActiveSession',
    '/Script/TensionMeter.TensionLibrary:GetTensionSubsystem',
}
function Probe.definitions()
    for _, path in ipairs(paths) do
        local object = StaticFindObject(path)
        log('Definition ' .. path .. ' valid=' .. tostring(valid(object)))
        if valid(object) then
            local ok, err = pcall(function()
                object:ForEachProperty(function(property)
                    log(string.format('  0x%X %s %s', property:GetOffset_Internal(),
                        property:GetClass():GetFName():ToString(), property:GetFName():ToString()))
                end)
            end)
            if not ok then log('metadata: ' .. tostring(err)) end
        end
    end
end
function Probe.runtime()
    for _, class in ipairs({'TensionWorldSubsystem', 'TensionSession', 'GameEngine', 'PlayerController'}) do
        local list = FindAllOf(class) or {}
        log('Runtime ' .. class .. ' count=' .. #list)
        for i = 1, math.min(#list, 4) do
            local object = list[i]
            if valid(object) then
                log('  ' .. object:GetFullName())
                if class == 'TensionWorldSubsystem' then
                    local ok, value = pcall(function() return object.SessionsByBoss end)
                    log('  SessionsByBoss access=' .. tostring(ok) .. ' value=' .. tostring(value))
                    if ok and value then
                        local typeOK, valueType = pcall(function() return value:type() end)
                        log('  map type=' .. tostring(typeOK and valueType or 'unknown'))
                    end
                end
            end
        end
    end
end
return Probe
