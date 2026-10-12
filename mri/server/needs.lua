-- Hunger, thirst and stress from the mri_Qbox Necessidades module (GlobalState 'mri:needs'); no state keeps config/ as is.

-- same table loops.lua reads every tick, so the rates apply live
local config = require 'config.server'

local KEY = 'mri:needs'
local DEFAULT_RATES = { hunger = config.player.hungerRate, thirst = config.player.thirstRate }
-- value a turned off need is held at
local HELD = { hunger = 100, thirst = 100, stress = 0 }

---@type { hunger: boolean, thirst: boolean, stress: boolean, hungerRate: number?, thirstRate: number? }?
local needs

local function hold(source)
    for meta, value in pairs(HELD) do
        if needs[meta] == false then SetMetadata(source, meta, value) end
    end
end

local function apply(value)
    needs = type(value) == 'table' and value or nil

    for meta, default in pairs(DEFAULT_RATES) do
        local rate = needs and tonumber(needs[meta .. 'Rate']) or default
        if needs and needs[meta] == false then rate = 0 end
        config.player[meta .. 'Rate'] = rate
    end

    if not needs then return end
    for source in pairs(QBX.Players) do hold(source) end
end

AddStateBagChangeHandler(KEY, 'global', function(_, _, value)
    apply(value)
end)

AddEventHandler('QBCore:Server:PlayerLoaded', function(player)
    if needs then hold(player.PlayerData.source) end
end)

-- scripts that write the statebag or the metadata directly, skipping mri_Qhud
AddEventHandler('qbx_core:server:onSetMetaData', function(meta, _, value, source)
    local held = HELD[meta]
    if not needs or not held or needs[meta] ~= false or value == held then return end
    -- next tick: SetMetadata still writes the statebag after this event
    SetTimeout(0, function() SetMetadata(source, meta, held) end)
end)

apply(GlobalState[KEY])
