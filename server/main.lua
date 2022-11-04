QBCore = exports['qb-core']:GetCoreObject()

function Notify( sid, message, msgtype )
    if(Config.notify == "okok") then 
        TriggerClientEvent('okokNotify:Alert', sid, "Housing", message, 2000, msgtype)
        return true
    end
    if(Config.notify == "qb") then 
        TriggerClientEvent('QBCore:Notify', sid,message, msgtype)
        return true
    end
    print("[DC-Open-Houses] Notify type wasn't set properly. it should be qb or okok it is currently: " .. Config.notify)
    return false
end

function GetClosestHouseIndex(source)
    local PlayerCoords = GetEntityCoords(GetPlayerPed(source))
    local ClosestHouseIndex
    for i = 1, #Config.OpenHouses do
        if #(PlayerCoords - Config.OpenHouses[i].center) <= 30 then
            if ClosestHouseIndex then
                if #(PlayerCoords - Config.OpenHouses[i].center) < #(PlayerCoords - Config.OpenHouses[ClosestHouseIndex].center) then
                    ClosestHouseIndex = i
                end
            else
                ClosestHouseIndex = i
            end
        end
    end
    return ClosestHouseIndex
end

function IsKeyholder(CitizenID, House)
    for i = 1, #House.keyholders do
        if House.keyholders[i] == CitizenID then
            return true
        end
    end
    return false
end

function Trim(value)
	if not value then return nil end
    return (string.gsub(value, '^%s*(.-)%s*$', '%1'))
end

function Round(num, numDecimalPlaces)
    local mult = 10^(numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end

RegisterNetEvent('dc-open-houses:server:DoorInteract', function(HouseIndex, DoorIndex, LockState)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local PlayerCoords = GetEntityCoords(GetPlayerPed(src))
    local House = Config.OpenHouses[HouseIndex]

    if #(PlayerCoords - House.doors[DoorIndex].coords) > 5 then return end
    if not IsKeyholder(Player.PlayerData.citizenid, House) and Player.PlayerData.citizenid ~= House.owner then Notify(src, Lang:t('error.not_keyholder'), 'error') return end

    House.doors[DoorIndex].locked = LockState
    SetResourceKvp('Openhouse_'..tostring(HouseIndex), json.encode(House))
    TriggerEvent('qb-doorlock:server:updateState', House.doors[DoorIndex].name, LockState, false, false, true, true, true, src)
    TriggerClientEvent('dc-open-houses:client:sync', -1, Config.OpenHouses)
end)

CreateThread(function()
    local Lenght = GetResourceKvpInt("Housescount") or 0
    local Doors = {}
    for i = 1, Lenght do
        local House = json.decode(GetResourceKvpString('Openhouse_'..tostring(i)))
        for b = 1, #House.doors do
            Doors[b] = {
                name = House.doors[b].name,
                coords = vector3(House.doors[b].coords.x, House.doors[b].coords.y, House.doors[b].coords.z),
                locked = true
            }
        end
        Config.OpenHouses[i] = {
            house = House.house,
            owner = House.owner,
            doors = Doors,
            keyholders = House.keyholders,
            center = vector3(House.center.x, House.center.y, House.center.z),
            stash = vector3(House.stash.x, House.stash.y, House.stash.z),
            outfit = vector3(House.outfit.x, House.outfit.y, House.outfit.z),
            logout = vector3(House.logout.x, House.logout.y, House.logout.z),
            garage = vector3(House.garage.x, House.garage.y, House.garage.z),
            spawn = vector4(House.spawn.x, House.spawn.y, House.spawn.z, House.spawn.w)
        }
    end
    Wait(50)
    TriggerClientEvent('dc-open-houses:client:sync', -1, Config.OpenHouses)
    PerformHttpRequest('https://api.github.com/repos/Disabled-Coding/dc-open-houses/releases/latest', function(_, resultData)
        if not resultData then print('Failed to check for updates') return end
        local result = json.decode(resultData)
        if GetResourceMetadata(GetCurrentResourceName(), 'version') ~= result.tag_name then
            print('New version of '..GetCurrentResourceName()..' is available!')
        end
    end)
end)

AddEventHandler('playerJoining', function(source)
    TriggerClientEvent('dc-open-houses:client:sync', source, Config.OpenHouses)
end)

RegisterNetEvent('dc-open-houses:server:StoreCar', function(VehicleFuel, VehicleProps)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local Ped = GetPlayerPed(src)
    local PlayerCoords = GetEntityCoords(Ped)
    local ClosestHouseIndex = GetClosestHouseIndex(src)
    local House = Config.OpenHouses[ClosestHouseIndex]
    local Vehicle = GetVehiclePedIsIn(Ped, false)
    local Belongs

    if Vehicle == 0 then Notify(src, Lang:t('error.not_in_car'), 'error') return end
    if not House then Notify(src, Lang:t('error.not_nearby_house'), 'error') return end
    if not IsKeyholder(Player.PlayerData.citizenid, House) and Player.PlayerData.citizenid ~= House.owner then Notify('QBCore:Notify', src, Lang:t('error.not_keyholder'), 'error') return end
    if #(PlayerCoords - House.garage) > 5 then return end

    local VehiclePlate = Trim(GetVehicleNumberPlateText(Vehicle))
    local VehicleModel = GetEntityModel(Vehicle)
    local VehicleEngine = GetVehicleEngineHealth(Vehicle)
    local VehicleBody = GetVehicleBodyHealth(Vehicle)
    local result = MySQL.single.await('SELECT * FROM player_vehicles WHERE plate = ? AND hash = ? AND state = ?', {VehiclePlate, VehicleModel, 0})
    if not result then Notify(src, Lang:t('error.not_owner_car'), 'error') return end
    for i = 1, #House.keyholders do
        if House.keyholders[i] == result.citizenid then
            Belongs = true
        end
    end
    if House.owner == result.citizenid then Belongs = true end
    if not Belongs then Notify(src, Lang:t('error.dont_park_here'), 'error') return end
    MySQL.update('UPDATE player_vehicles SET state = ?, garage = ?, fuel = ?, engine = ?, body = ?, mods = ? WHERE plate = ? AND hash = ?', {1, House.house, VehicleFuel, VehicleEngine, VehicleBody, json.encode(VehicleProps), VehiclePlate, VehicleModel})
    TaskLeaveVehicle(Ped, Vehicle)
    TaskEveryoneLeaveVehicle(Vehicle) -- Doesn't work but hey. Once it does.
    SetTimeout(1850, function()
        DeleteEntity(Vehicle)
    end)
end)

QBCore.Functions.CreateCallback('dc-open-houses:callback:PullVehicles', function(source, cb)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local PlayerCoords = GetEntityCoords(GetPlayerPed(src))
    local ClosestHouseIndex = GetClosestHouseIndex(src)
    local House = Config.OpenHouses[ClosestHouseIndex]
    local Vehicles = {}

    if not House then Notify(src, Lang:t('error.not_nearby_house'), 'error') return end
    if not IsKeyholder(Player.PlayerData.citizenid, House) and Player.PlayerData.citizenid ~= House.owner then Notify(src, Lang:t('error.not_keyholder'), 'error') return end
    if #(PlayerCoords - House.garage) > 5 then return end

    local result = MySQL.query.await('SELECT * FROM player_vehicles WHERE garage = ? AND state = ?', {House.house, 1})
    if not result[1] then cb(nil) return end
    for i = 1, #result do
        Vehicles[i] = {
            name = QBCore.Shared.Vehicles[result[i].vehicle]['name'],
            plate = Trim(result[i].plate),
            engine = Round(result[i].engine, 1),
            fuel = Round(result[i].fuel, 1),
        }
    end
    cb(Vehicles)
end)

RegisterNetEvent('dc-open-houses:server:RetrieveCar', function(Data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local Ped = GetPlayerPed(src)
    local PlayerCoords = GetEntityCoords(Ped)
    local ClosestHouseIndex = GetClosestHouseIndex(src)
    local House = Config.OpenHouses[ClosestHouseIndex]
    local VehiclePlate = Data.plate

    if not House then Notify(src, Lang:t('error.not_nearby_house'), 'error') return end
    if not IsKeyholder(Player.PlayerData.citizenid, House) and Player.PlayerData.citizenid ~= House.owner then Notify(src, Lang:t('error.not_keyholder'), 'error') return end
    if #(PlayerCoords - House.garage) > 5 then return end

    local result = MySQL.single.await('SELECT * FROM player_vehicles WHERE plate = ? AND state = ? AND garage = ?', {VehiclePlate, 1, House.house})
    if not result then return end
    local Vehicle = CreateVehicle(tonumber(result.hash), House.garage.x, House.garage.y, House.garage.z, GetEntityHeading(Ped), true)
    while not DoesEntityExist(Vehicle) do Wait(0) end
    SetVehicleNumberPlateText(Vehicle, VehiclePlate)
    SetVehicleBodyHealth(Vehicle, result.body)
    TaskWarpPedIntoVehicle(Ped, Vehicle, -1)
    TriggerClientEvent('vehiclekeys:client:SetOwner', src, VehiclePlate)
    TriggerClientEvent('dc-open-houses:client:SetVehicle', src, NetworkGetNetworkIdFromEntity(Vehicle), result.engine, result.fuel, json.decode(result.mods))
    MySQL.update('UPDATE player_vehicles SET state = ? WHERE plate = ? AND hash = ?', {0, VehiclePlate, result.hash})
end)
