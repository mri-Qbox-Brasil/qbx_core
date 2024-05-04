local config = require 'config.client'
local defaultSpawn = require 'config.shared'.defaultSpawn

if config.characters.useExternalCharacters then return end

local previewCam = nil
local randomLocation = config.characters.locations[math.random(1, #config.characters.locations)]

local randomPedModels = {
    `a_m_o_soucent_02`,
    `mp_g_m_pros_01`,
    `a_m_m_prolhost_01`,
    `a_f_m_prolhost_01`,
    `a_f_y_smartcaspat_01`,
    `a_f_y_runner_01`,
    `a_f_y_vinewood_04`,
    `a_f_o_soucent_02`,
    `a_m_y_cyclist_01`,
    `a_m_m_hillbilly_02`,
}

local ScenarioType = {
    'WORLD_HUMAN_SMOKING_POT',
    'WORLD_HUMAN_MUSICIAN',
    'WORLD_HUMAN_COP_IDLES',
    'WORLD_HUMAN_CHEERING',
    'WORLD_HUMAN_TOURIST_MAP',
    -- 'WORLD_HUMAN_HAMMERING',
    'WORLD_HUMAN_PUSH_UPS',
    'WORLD_HUMAN_PARTYING',
    'WORLD_HUMAN_PICNIC',
    'WORLD_HUMAN_SIT_UPS',
    -- 'WORLD_HUMAN_TENNIS_PLAYER',
    'WORLD_HUMAN_DRINKING',
    -- 'WORLD_HUMAN_BINOCULARS',
    'WORLD_HUMAN_HANG_OUT_STREET',
    -- 'WORLD_HUMAN_PAPARAZZI',
    -- 'WORLD_HUMAN_TOURIST_MOBILE',
    'WORLD_HUMAN_VALET',
    'WORLD_HUMAN_STAND_IMPATIENT_CLUBHOUSE',
    -- 'WORLD_HUMAN_MUSCLE_FREE_WEIGHTS'
}
local camera = nil

function setupPreviewCam()
    -- SetTimecycleModifier('hud_def_blur')
    SetTimecycleModifierStrength(1.0)
    FreezeEntityPosition(cache.ped, false)
    TaskStartScenarioInPlace(cache.ped, ScenarioType[math.random(1,#ScenarioType)], 0, true)
    local coords = GetOffsetFromEntityInWorldCoords(cache.ped, 0, 1.6, 0)
    camera = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamActive(camera, true)
    RenderScriptCams(true, true, 1250, 1, 0)
    SetCamCoord(camera, coords.x, coords.y, coords.z + 0.65)
    SetCamFov(camera, 38.0)
    SetCamRot(camera, 0.0, 0.0, GetEntityHeading(cache.ped) + 180)
    PointCamAtPedBone(camera, cache.ped, 31086, 0.0 - 0.4, 0.0, 0.03, 1)
    local camCoords = GetCamCoord(camera)
    TaskLookAtCoord(cache.ped, camCoords.x, camCoords.y, camCoords.z, 5000, 1, 1)
    SetCamUseShallowDofMode(camera, true)
    SetCamNearDof(camera, 1.2)
    SetCamFarDof(camera, 12.0)
    SetCamDofStrength(camera, 1.0)
    SetCamDofMaxNearInFocusDistance(camera, 1.0)
    Citizen.Wait(500)

    DoScreenFadeIn(1000)
    CreateThread(function()
        while DoesCamExist(camera) do
            SetUseHiDof()
            Wait(0)
        end
    end)
end

function destroyPreviewCam()
    if not camera then return end

    SetTimecycleModifier('default')
    RenderScriptCams(false, true, 1250, 1, 0)
    DestroyCam(camera, false)
    camera = nil
    ClearPedTasks(PlayerPedId())
    FreezeEntityPosition(cache.ped, false)
end

---@param citizenId? string
local function previewPed(citizenId)

    if not citizenId then
        local model = randomPedModels[math.random(1, #randomPedModels)]
        lib.requestModel(model, config.loadingModelsTimeout)
        SetPlayerModel(cache.playerId, model)

        destroyPreviewCam()
        Citizen.Wait(100)
        setupPreviewCam()
        return
    end

    DoScreenFadeOut(500)
    Citizen.Wait(500)

    local clothing, model = lib.callback.await('qbx_core:server:getPreviewPedData', false, citizenId)
    if model and clothing then
        lib.requestModel(model, config.loadingModelsTimeout)
        SetPlayerModel(cache.playerId, model)
        pcall(function() exports['illenium-appearance']:setPedAppearance(PlayerPedId(), json.decode(clothing)) end)
    else
        model = randomPedModels[math.random(1, #randomPedModels)]
        lib.requestModel(model, config.loadingModelsTimeout)
        SetPlayerModel(cache.playerId, model)
    end

    destroyPreviewCam()
    Citizen.Wait(100)
    setupPreviewCam()
end

---@class CharacterRegistration
---@field firstname string
---@field lastname string
---@field nationality string
---@field gender number
---@field birthdate string
---@field cid integer

---@return string[]?
local function characterDialog()
    return lib.inputDialog(locale('info.character_registration_title'), {
        {
            type = 'input',
            required = true,
            icon = 'user-pen',
            label = locale('info.first_name'),
            placeholder = 'Murai'
        },
        {
            type = 'input',
            required = true,
            icon = 'user-pen',
            label = locale('info.last_name'),
            placeholder = 'Dev'
        },
        {
            type = 'select',
            required = true,
            icon = 'user-shield',
            label = locale('info.nationality'),
            placeholder = '',
            options = {
                {
                    value = "Brasil"
                },
                {
                    value = "Portugal"
                }
            }
        },
        {
            type = 'select',
            required = true,
            icon = 'circle-user',
            label = locale('info.gender'),
            placeholder = locale('Selecionar nacionalidade'),
            options = {
                {
                    value = locale('info.char_male')
                },
                {
                    value = locale('info.char_female')
                }
            }
        },
        {
            type = 'date',
            required = true,
            icon = 'calendar-days',
            label = locale('info.birth_date'),
            format = 'DD-MM-YYYY',
            returnString = true,
            min = '01-01-1900', -- Has to be in the same in the same format as the format argument
            max = '12-31-2006', -- Has to be in the same in the same format as the format argument
            default = '12-31-2006'
        }
    })
end

---@param dialog string[]
---@param input integer
---@return boolean
local function checkStrings(dialog, input)
    local str = dialog[input]
    if config.characters.profanityWords[str:lower()] then return false end

    local split = {string.strsplit(' ', str)}
    if #split > 5 then return false end

    for i = 1, #split do
        local word = split[i]
        if config.characters.profanityWords[word:lower()] then return false end
    end

    return true
end

-- @param str string
-- @return string?
local function capString(str)
    return str:gsub("(%w)([%w']*)", function(first, rest)
        return first:upper() .. rest:lower()
    end)
end

local function spawnDefault() -- We use a callback to make the server wait on this to be done
    DoScreenFadeOut(500)

    while not IsScreenFadedOut() do
        Wait(0)
    end

    destroyPreviewCam()

    pcall(function() exports.spawnmanager:spawnPlayer({
        x = defaultSpawn.x,
        y = defaultSpawn.y,
        z = defaultSpawn.z,
        heading = defaultSpawn.w
    }) end)

    TriggerServerEvent('QBCore:Server:OnPlayerLoaded')
    TriggerEvent('QBCore:Client:OnPlayerLoaded')
    TriggerServerEvent('qb-houses:server:SetInsideMeta', 0, false)
    TriggerServerEvent('qb-apartments:server:SetInsideMeta', 0, 0, false)

    while not IsScreenFadedIn() do
        Wait(0)
    end
    TriggerEvent('qb-clothes:client:CreateFirstCharacter')
end

local function spawnLastLocation()
    DoScreenFadeOut(500)

    while not IsScreenFadedOut() do
        Wait(0)
    end

    destroyPreviewCam()

    pcall(function() exports.spawnmanager:spawnPlayer({
        x = QBX.PlayerData.position.x,
        y = QBX.PlayerData.position.y,
        z = QBX.PlayerData.position.z,
        heading = QBX.PlayerData.position.w
    }) end)

    TriggerServerEvent('QBCore:Server:OnPlayerLoaded')
    TriggerEvent('QBCore:Client:OnPlayerLoaded')
    TriggerServerEvent('qb-houses:server:SetInsideMeta', 0, false)
    TriggerServerEvent('qb-apartments:server:SetInsideMeta', 0, 0, false)

    while not IsScreenFadedIn() do
        Wait(0)
    end
end

---@param cid integer
---@return boolean
local function createCharacter(cid)
    -- previewPed()

    :: noMatch ::

    local dialog = characterDialog()

    if not dialog then return false end

    for input = 1, 3 do -- Run through first 3 inputs, aka first name, last name and nationality
        if not checkStrings(dialog, input) then
            Notify(locale('error.no_match_character_registration'), 'error', 10000)
            goto noMatch
            break
        end
    end

    DoScreenFadeOut(150)
    local newData = lib.callback.await('qbx_core:server:createCharacter', false, {
        firstname = capString(dialog[1]),
        lastname = capString(dialog[2]),
        nationality = capString(dialog[3]),
        gender = dialog[4] == locale('info.char_male') and 0 or 1,
        birthdate = dialog[5],
        cid = cid
    })

    if GetResourceState('qbx_spawn') == 'missing' then
        spawnDefault()
        TriggerEvent('qb-clothes:client:CreateFirstCharacter')
    else
        if config.characters.startingApartment then
            TriggerEvent('apartments:client:setupSpawnUI', newData)
        else
            TriggerEvent('qbx_core:client:spawnNoApartments')
        end
    end

    destroyPreviewCam()
    return true
end

local function chooseCharacter()
    randomLocation = config.characters.locations[math.random(1, #config.characters.locations)]
    SetFollowPedCamViewMode(2)

    DoScreenFadeOut(500)

    while not IsScreenFadedOut() and cache.ped ~= PlayerPedId()  do
        Wait(0)
    end

    FreezeEntityPosition(cache.ped, true)
    Wait(1000)

    RequestCollisionAtCoord(randomLocation.pedCoords.x, randomLocation.pedCoords.y, randomLocation.pedCoords.z)
    while not HasCollisionLoadedAroundEntity(cache.ped) do Wait(0) end

    SetEntityCoords(cache.ped, randomLocation.pedCoords.x, randomLocation.pedCoords.y, randomLocation.pedCoords.z, false, false, false, false)
    SetEntityHeading(cache.ped, randomLocation.pedCoords.w)
    ---@diagnostic disable-next-line: missing-parameter
    lib.callback('qbx_core:server:setCharBucket', false)
    Wait(1500)
    ShutdownLoadingScreen()
    ShutdownLoadingScreenNui()
    setupPreviewCam()

    ---@type PlayerEntity[], integer
    local characters, amount = lib.callback.await('qbx_core:server:getCharacters')
    local options = {}
    for i = 1, amount do
        local character = characters[i]
        local name = character and ('%s %s'):format(character.charinfo.firstname, character.charinfo.lastname)
        options[i] = {
            title = character and ('%s %s - %s'):format(character.charinfo.firstname, character.charinfo.lastname, character.citizenid) or locale('info.multichar_new_character', i),
            metadata = character and {
                ['Nome'] = name,
                ['Gênero'] = character.charinfo.gender == 0 and locale('info.char_male') or locale('info.char_female'),
                ['Data de Nascimento'] = character.charinfo.birthdate,
                ['Nacionalidade'] = character.charinfo.nationality,
                ['Número da conta'] = character.charinfo.account,
                ['Banco'] = lib.math.groupdigits(character.money.bank),
                ['Carteira'] = lib.math.groupdigits(character.money.cash),
                ['Emprego'] = character.job.label,
                ['Nível de emprego'] = character.job.grade.name,
                ['Gangue'] = character.gang.label,
                ['Patente'] = character.gang.grade.name,
                ['Telefone'] = character.charinfo.phone
            } or nil,
            icon = 'user',
            onSelect = function()
                if character then
                    lib.showContext('qbx_core_multichar_character_'..i)
                    previewPed(character.citizenid)
                else
                    local success = createCharacter(i)
                    if success then return end

                    lib.showContext('qbx_core_multichar_characters')
                end
            end
        }

        if character then
            lib.registerContext({
                id = 'qbx_core_multichar_character_'..i,
                title = ('%s %s - %s'):format(character.charinfo.firstname, character.charinfo.lastname, character.citizenid),
                canClose = false,
                menu = 'qbx_core_multichar_characters',
                options = {
                    {
                        title = locale('info.play'),
                        description = locale('info.play_description', name),
                        icon = 'play',
                        onSelect = function()
                            DoScreenFadeOut(10)
                            lib.callback.await('qbx_core:server:loadCharacter', false, character.citizenid)
                            if GetResourceState('qbx_apartments'):find('start') then
                                TriggerEvent('apartments:client:setupSpawnUI', character.citizenid)
                            elseif GetResourceState('qbx_spawn'):find('start') then
                                TriggerEvent('qb-spawn:client:setupSpawns', character.citizenid)
                                TriggerEvent('qb-spawn:client:openUI', true)
                            else
                                spawnLastLocation()
                            end
                            destroyPreviewCam()
                        end
                    },
                    config.characters.enableDeleteButton and {
                        title = locale('info.delete_character'),
                        description = locale('info.delete_character_description', name),
                        icon = 'trash',
                        onSelect = function()
                            local alert = lib.alertDialog({
                                header = locale('info.delete_character'),
                                content = locale('info.confirm_delete'),
                                centered = true,
                                cancel = true
                            })
                            if alert == 'confirm' then
                                TriggerServerEvent('qbx_core:server:deleteCharacter', character.citizenid)
                                destroyPreviewCam()
                                chooseCharacter()
                            else
                                lib.showContext('qbx_core_multichar_character_'..i)
                            end
                        end
                    } or nil
                }
            })
        end
    end

    lib.registerContext({
        id = 'qbx_core_multichar_characters',
        title = locale('info.multichar_title'),
        canClose = false,
        options = options
    })

    SetTimecycleModifier('default')
    lib.showContext('qbx_core_multichar_characters')
end

RegisterNetEvent('qbx_core:client:spawnNoApartments', function() -- This event is only for no starting apartments
    DoScreenFadeOut(500)
    Wait(2000)
    SetEntityCoords(cache.ped, defaultSpawn.x, defaultSpawn.y, defaultSpawn.z, false, false, false, false)
    SetEntityHeading(cache.ped, defaultSpawn.w)
    Wait(500)
    destroyPreviewCam()
    SetEntityVisible(cache.ped, true, false)
    Wait(500)
    DoScreenFadeIn(250)
    TriggerServerEvent('QBCore:Server:OnPlayerLoaded')
    TriggerEvent('QBCore:Client:OnPlayerLoaded')
    TriggerServerEvent('qb-houses:server:SetInsideMeta', 0, false)
    TriggerServerEvent('qb-apartments:server:SetInsideMeta', 0, 0, false)
    TriggerEvent('qb-weathersync:client:EnableSync')
    TriggerEvent('qb-clothes:client:CreateFirstCharacter')
end)

RegisterNetEvent('qbx_core:client:playerLoggedOut', function()
    if GetInvokingResource() then return end -- Make sure this can only be triggered from the server
    chooseCharacter()
end)

CreateThread(function()
    local model = randomPedModels[math.random(1, #randomPedModels)]
    while true do
        Wait(0)
        if NetworkIsSessionStarted() then
            pcall(function() exports.spawnmanager:setAutoSpawn(false) end)
            Wait(250)
            lib.requestModel(model, config.loadingModelsTimeout)
            SetPlayerModel(cache.playerId, model)
            SetModelAsNoLongerNeeded(model)
            chooseCharacter()
            break
        end
    end
end)
