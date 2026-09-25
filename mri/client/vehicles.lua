-- Applies the runtime vehicle registry (mri/server/vehicles.lua) to the shared
-- table, so GetVehiclesByName/GetVehiclesByHash see the same list as the server.

local vehicles = QBX.Shared.Vehicles
local vehicleHashes = QBX.Shared.VehicleHashes

---@param model string
---@param vehicle Vehicle | false | nil
local function applyVehicle(model, vehicle)
    local current = vehicles[model]
    if current then
        vehicleHashes[current.hash] = nil
    end

    vehicles[model] = vehicle or nil
    if vehicle then
        vehicleHashes[vehicle.hash] = vehicle
    end
end

RegisterNetEvent('qbx_core:client:onVehicleUpdate', applyVehicle)

-- Replays the changes as local events, so resources that cached the list while
-- this was loading get them too.
for model, vehicle in pairs(lib.callback.await('qbx_core:server:getVehicleChanges') or {}) do
    TriggerEvent('qbx_core:client:onVehicleUpdate', model, vehicle or nil)
end
