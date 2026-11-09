-- BossTensionDisplay 0.1.1, created for the local Steam installation.
-- __DEPRECATED_20261107__ Initial reflection-only bootstrap, retained for traceability:
-- local Probe = require('Probe')
-- print('[BossTensionDisplay] Read-only inspection bootstrap\n')
-- ExecuteWithDelay(3000, function()
--     ExecuteInGameThread(function() Probe.definitions(); Probe.runtime() end)
-- end)

local source=debug.getinfo(1,'S').source:gsub('^@','')
local prior=_G.BossTensionDisplayRuntime
if prior and prior.shutdown then prior.shutdown() end
for _, name in ipairs({'Reader','HUD','Settings'}) do package.loaded[name]=nil end
-- __DEPRECATED_20261107__ UE4SS's require cache survives package.loaded invalidation.
-- local Reader=require('Reader')
-- local HUD=require('HUD')
-- local settings=require('Settings')
local directory=source:match('^(.*)[/\\][^/\\]+$')
local Reader=dofile(directory..'/Reader.lua')
local HUD=dofile(directory..'/HUD.lua')
local settings=dofile(directory..'/Settings.lua')
local reader=Reader.new()
local hud=HUD.new(settings)
local runtime={alive=true,visible=true,pending=false,lastLog=0}
_G.BossTensionDisplayRuntime=runtime
local function log(message) print('[BossTensionDisplay] '..tostring(message)..'\n') end
function runtime.shutdown()
    runtime.alive=false
    hud:destroy()
end
local function update()
    if not runtime.alive then return end
    local context=reader:context()
    -- __DEPRECATED_20261107__ if not context then return end -- left the last reading on loading screens
    if not context then hud:destroy(); return end
    local sample,reason=reader:sample()
    hud:update(context,sample,reason,runtime.visible)
    local now=os.time()
    if now-runtime.lastLog>=10 then
        runtime.lastLog=now
        if sample then
            log(string.format('Live raw=%.4f tier=%s delta=%.4f events=%d boss=%s',
                sample.raw,tostring(sample.tier),sample.delta or 0,#sample.events,sample.boss))
        else log(reason or 'No active encounter') end
    end
end
LoopAsync(settings.PollMilliseconds,function()
    if not runtime.alive then return true end
    if not runtime.pending then
        runtime.pending=true
        ExecuteInGameThread(function()
            runtime.pending=false
            if not runtime.alive then return end
            local ok,err=pcall(update)
            if not ok and os.time()-(runtime.lastError or 0)>=10 then
                runtime.lastError=os.time()
                log('ERROR '..tostring(err))
            end
        end)
    end
    return false
end)
if not _G.BossTensionDisplayKeys then
    RegisterKeyBind(Key[settings.ToggleKey],function()
        local current=_G.BossTensionDisplayRuntime
        if current then current.visible=not current.visible end
    end)
    RegisterKeyBind(Key[settings.ReloadKey],function()
        ExecuteInGameThread(function()
            local ok,err=pcall(dofile,source)
            if not ok then log('Reload failed: '..tostring(err)) end
        end)
    end)
    _G.BossTensionDisplayKeys=true
end
log('v0.1.1 loaded; read-only; '..settings.ToggleKey..' toggle, '..settings.ReloadKey..' reload')
if settings.Diagnostics then
    ExecuteWithDelay(3000,function()
        ExecuteInGameThread(function() require('Probe').definitions(); require('Probe').runtime() end)
    end)
end
