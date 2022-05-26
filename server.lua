local QBCore = exports['qb-core']:GetCoreObject()

local function GetClosestHouse(source)
    local PlayerCoords = GetEntityCoords(GetPlayerPed(source))
    local ClosestHouse
    for i = 1, #Config.OpenHouses do
        if #(PlayerCoords - Config.OpenHouses[i].center) <= 30 then
            if ClosestHouse then
                if #(PlayerCoords - Config.OpenHouses[i].center) < #(PlayerCoords - ClosestHouse.center) then
                    ClosestHouse = Config.OpenHouses[i]
                end
            else
                ClosestHouse = Config.OpenHouses[i]
            end
        end
    end
    return ClosestHouse
end

QBCore.Commands.Add('createopenhouse', Lang:t('command.create_house'), {{name = 'House Name', help = Lang:t('command.name_of_house')}, {name = 'Owner CID | ID', help = Lang:t('command.owner_cid')}}, true, function(source, args)
    local src = source
    local HouseName = tostring(args[1])
    local OwnerCID = QBCore.Functions.GetPlayer(tonumber(args[2])).PlayerData.citizenid or tostring(args[2])
    local Owner = QBCore.Functions.GetPlayerByCitizenId(OwnerCID)
    if not Owner then TriggerClientEvent('QBCore:Notify', src, Lang:t('error.owner_not_found'), 'error') return end
    local PlayerCoords = GetEntityCoords(GetPlayerPed(src))
    local AmountOfHouses = (GetResourceKvpInt("Housescount") or 0) + 1
    Config.OpenHouses[AmountOfHouses] = {
        house = HouseName,
        owner = OwnerCID,
        doors = {},
        keyholders = {},
        center = PlayerCoords,
        stash = nil,
        outfit = nil,
        logout = nil,
        garage = nil
    }
    SetResourceKvp('Openhouse_'..tostring(AmountOfHouses), json.encode(Config.OpenHouses[AmountOfHouses]))
    SetResourceKvpInt('Housescount', AmountOfHouses)
    TriggerClientEvent('QBCore:Notify', src, Lang:t('success.create_house', {house = HouseName, owner = Owner.PlayerData.charinfo.firstname}), 'success')
    TriggerClientEvent('dc-open-houses:client:sync', -1, Config.OpenHouses)
end, 'admin')

QBCore.Commands.Add('addstash', Lang:t('command.create_stash'), {}, false, function(source)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local ClosestHouse = GetClosestHouse(src)
    if not ClosestHouse then TriggerClientEvent('QBCore:Notify', src, Lang:t('error.not_nearby_house'), 'error') return end
    if Player.PlayerData.citizenid ~= ClosestHouse.owner and not QBCore.Functions.HasPermission(src, 'admin') then TriggerClientEvent('QBCore:Notify', src, Lang:t('error.no_perms'), 'error') return end
end)

QBCore.Commands.Add('deleteallhouses', Lang:t('command.delete_all'), {}, false, function(source)
    local Lenght = GetResourceKvpInt("Housescount") or 0
    for i = 1, #Lenght do
        DeleteResourceKvpNoSync('Openhouse_'..tostring(i))
    end
    FlushResourceKvp()
    Config.OpenHouses = {}
    TriggerClientEvent('dc-open-houses:client:sync', -1, Config.OpenHouses)
end, 'god')

CreateThread(function()
    local Lenght = GetResourceKvpInt("Housescount") or 0
    for i = 1, #Lenght do
        Config.OpenHouses[i] = json.decode(GetResourceKvp('Openhouse_'..tostring(i)))
    end
end)