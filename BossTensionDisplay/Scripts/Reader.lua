-- Only getters and property reads. No hooks, setters, console commands or AI edits.
local Reader = {}
Reader.__index = Reader

function Reader.valid(object)
    if object == nil then return false end
    local ok, answer = pcall(function() return object:IsValid() end)
    return ok and answer == true
end
function Reader.get(object, key)
    local ok, result = pcall(function() return object[key] end)
    if ok then return result end
end
function Reader.unwrap(value)
    for _ = 1, 2 do
        if value == nil then return nil end
        local ok, inner = pcall(function() return value:get() end)
        if not ok then break end
        value = inner
    end
    return value
end
local function text(value)
    if value == nil then return '' end
    if type(value) == 'string' then return value end
    local name = Reader.get(value, 'TagName')
    if name ~= nil then value = name end
    local ok, answer = pcall(function() return value:ToString() end)
    return ok and answer or tostring(value)
end
local function number(value)
    local n = tonumber(value)
    if n and n == n and n ~= math.huge and n ~= -math.huge then return n end
end
local function each(container, callback)
    if type(container)=='table' then
        for key,value in pairs(container) do callback(key,value) end
    else
        container:ForEach(callback)
    end
end
local function plainReadout(readout)
    local raw = number(readout.Raw)
    if raw == nil then return nil end
    local result = {
        raw = raw, tier = number(readout.Tier), confidence = number(readout.Confidence),
        delta = number(readout.DeltaPerSec), peak = number(readout.PeakLast10s),
        trough = number(readout.TroughLast10s), dimensions = {}, events = {},
    }
    local scores = Reader.get(readout, 'DimScores')
    if scores then
        -- __DEPRECATED_20261107__ scores:ForEach(function(key, value)
        each(scores,function(key, value)
            result.dimensions[text(Reader.unwrap(key))] = number(Reader.unwrap(value))
        end)
    end
    return result
end
local function readEvents(state, profile)
    local result = {}
    local weights={}
    local baseWeights=Reader.get(profile,'OutcomeBaseWeights')
    if baseWeights then
        each(baseWeights,function(key,value)
            weights[text(Reader.unwrap(key))]=number(Reader.unwrap(value))
        end)
    end
    local events = Reader.get(state, 'RecentEvents')
    if events then
        -- __DEPRECATED_20261107__ events:ForEach(function(_, value)
        each(events,function(_, value)
            local item = Reader.unwrap(value)
            if item then
                result[#result + 1] = {
                    time = number(item.Time) or 0, tag = text(item.OutcomeTag),
                    -- __DEPRECATED_20261107__ RecentEvents is OutcomeRecord, not TensionEventRecord.
                    -- weight = number(item.FinalWeight), base = number(item.BaseWeight),
                    -- dimension = text(item.RoutedDim),
                    base = weights[text(item.OutcomeTag)], positive = item.bIsPositive,
                }
            end
        end)
    end
    table.sort(result, function(a, b) return a.time > b.time end)
    return result
end
function Reader.new()
    return setmetatable({ bosses={}, lastSearch=0 }, Reader)
end
function Reader:context()
    local engine = FindFirstOf('GameEngine')
    if not Reader.valid(engine) then return nil end
    local gi = engine.GameInstance
    if not Reader.valid(gi) then return nil end
    local players = gi.LocalPlayers
    if not players or #players < 1 then return nil end
    local player = Reader.unwrap(players[1])
    if not Reader.valid(player) then return nil end
    local pc = player.PlayerController
    if not Reader.valid(pc) then return nil end
    -- UMG created on the server-check / menu world is discarded during save loading.
    if not Reader.valid(pc.Pawn) then return nil end
    return { gameInstance = gi, controller = pc, world = pc:GetWorld() }
end
function Reader:sample()
    local context = self:context()
    if not context or not Reader.valid(context.world) then return nil, '等待游戏世界' end
    local library = StaticFindObject('/Script/TensionMeter.Default__TensionLibrary')
    if not Reader.valid(library) then return nil, '压力接口尚未就绪' end
    local subsystem = library:GetTensionSubsystem(context.world)
    if not Reader.valid(subsystem) then return nil, '压力系统尚未就绪' end
    local samples = {}
    -- __DEPRECATED_20261107__ UE4SS rejects GetParam for WeakObjectProperty map keys.
    -- subsystem.SessionsByBoss:ForEach(function(key, value)
    --     local session = Reader.unwrap(value)
    --     local boss = session and Reader.unwrap(session.Boss) or nil
    --     if not Reader.valid(boss) then boss = Reader.unwrap(key) end
    -- __DEPRECATED_20261107__ UObject userdata equality is not portable across UE4SS builds.
    -- if self.world ~= context.world or os.time()-self.lastSearch>=2 then
    --     self.world=context.world
    local worldAddress=context.world:GetAddress()
    if self.worldAddress ~= worldAddress or os.time()-self.lastSearch>=2 then
        self.worldAddress=worldAddress
        self.lastSearch=os.time()
        self.bosses={}
        -- __DEPRECATED_20261107__ for _, candidate in ipairs(FindAllOf('Character') or {}) do
        for _, candidate in ipairs(FindAllOf('Actor') or {}) do
            -- __DEPRECATED_20261107__ candidate:GetWorld()==context.world rejected equal native pointers.
            if Reader.valid(candidate) then
                local world=candidate:GetWorld()
                if Reader.valid(world) and world:GetAddress()==worldAddress
                    and subsystem:HasActiveSessionForBoss(candidate) then
                    self.bosses[#self.bosses+1]=candidate
                end
            end
        end
    end
    for _, boss in ipairs(self.bosses) do
        if Reader.valid(boss) and subsystem:HasActiveSessionForBoss(boss) then
            local readout = subsystem:GetReadout(boss)
            local result = plainReadout(readout)
            if result then
                result.boss = boss:GetFName():ToString()
                -- __DEPRECATED_20261107__ Sessions were supplied by unsupported weak-key ForEach.
                -- result.events = readEvents(session.BossState)
                -- result.duration = number(session.BossState.SessionDuration) or 0
                local sessionOK, session = pcall(function()
                    return Reader.unwrap(subsystem.SessionsByBoss:Find(boss))
                end)
                if sessionOK and session then
                    result.events=readEvents(session.BossState,session.Profile)
                    result.duration=number(session.BossState.SessionDuration) or 0
                elseif not self.mapWarning then
                    self.mapWarning=true
                    print('[BossTensionDisplay] Session history: '..tostring(session)..'\n')
                end
                local playerState = subsystem.PlayerState
                result.hp = number(playerState.HpRatio)
                result.posture = number(playerState.PostureRatio)
                result.medicine = number(playerState.TotalMedicineCount)
                samples[#samples + 1] = result
            end
        end
    -- __DEPRECATED_20261107__ end) -- weak-key map callback
    end
    -- Multi-boss encounters: show the session with the most recent real event.
    table.sort(samples, function(a, b)
        local at = a.events[1] and a.events[1].time or 0
        local bt = b.events[1] and b.events[1].time or 0
        if at == bt then return a.boss < b.boss end
        return at > bt
    end)
    if samples[1] then samples[1].bossCount = #samples end
    if #samples==0 and #subsystem.SessionsByBoss>0 and not self.searchWarning then
        self.searchWarning=true
        print('[BossTensionDisplay] Session entries='..#subsystem.SessionsByBoss..' matched actors='..#self.bosses..'\n')
    end
    return samples[1], #samples == 0 and '等待首领战' or nil
end
return Reader
