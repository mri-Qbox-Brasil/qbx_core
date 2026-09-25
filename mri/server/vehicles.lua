-- Runtime vehicle registry: adds, edits and removes vehicles without touching
-- shared/vehicles.lua. Mirrors the job pattern in server/groups.lua: the shared
-- table is updated in place and changes are broadcast via
-- qbx_core:server:onVehicleUpdate and qbx_core:client:onVehicleUpdate.

local vehicles = QBX.Shared.Vehicles
local vehicleHashes = QBX.Shared.VehicleHashes

local vehicleTypes = {
    automobile = true,
    bike = true,
    boat = true,
    heli = true,
    plane = true,
    submarine = true,
    trailer = true,
    train = true,
}

---Models changed at runtime; false marks a removed model. Sent to clients on load.
---@type table<string, Vehicle | false>
local changes = {}

---@param model string
local function notifyVehicleUpdate(model)
    local vehicle = vehicles[model]
    changes[model] = vehicle or false
    TriggerEvent('qbx_core:server:onVehicleUpdate', model, vehicle)
    TriggerClientEvent('qbx_core:client:onVehicleUpdate', -1, model, vehicle)
end

---Adds a vehicle, or updates the given fields of an existing one.
---@param model string spawn name, lower case
---@param data { name?: string, brand?: string, price?: number, category?: string, type?: string }
---@return boolean success
---@return string? message
local function upsertVehicleData(model, data)
    if type(model) ~= 'string' or model:match('^%s*$') then
        return false, 'invalid_model'
    end

    if model ~= model:lower() then
        return false, 'model_not_lower_case'
    end

    if type(data) ~= 'table' then
        return false, 'invalid_data'
    end

    if data.type ~= nil and not vehicleTypes[data.type] then
        return false, 'invalid_type'
    end

    if data.price ~= nil and (type(data.price) ~= 'number' or data.price < 0) then
        return false, 'invalid_price'
    end

    local current = vehicles[model]

    if not current and (type(data.name) ~= 'string' or not data.type) then
        return false, 'missing_name_or_type'
    end

    local vehicle = {
        name = data.name or current.name,
        brand = data.brand or (current and current.brand) or '',
        model = model,
        price = data.price or (current and current.price) or 0,
        category = data.category or (current and current.category) or '',
        type = data.type or current.type,
        hash = joaat(model),
    }

    vehicles[model] = vehicle
    vehicleHashes[vehicle.hash] = vehicle

    notifyVehicleUpdate(model)
    return true
end

exports('UpsertVehicleData', upsertVehicleData)

---@param model string
---@return boolean success
---@return string? message
local function removeVehicleData(model)
    local vehicle = vehicles[model]
    if not vehicle then
        return false, 'vehicle_not_exists'
    end

    vehicles[model] = nil
    vehicleHashes[vehicle.hash] = nil

    notifyVehicleUpdate(model)
    return true
end

exports('RemoveVehicleData', removeVehicleData)

---Allow clients to fetch the runtime changes on load
---@return table<string, Vehicle | false>
lib.callback.register('qbx_core:server:getVehicleChanges', function()
    return changes
end)
