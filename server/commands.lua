QBCore.Commands.Add('createopenhouse', Lang:t('command.create_house'), {{name = 'House Name', help = Lang:t('command.name_of_house')}, {name = 'Owner CID | ID', help = Lang:t('command.owner_cid')}}, true, function(source, args)
    local src = source
    local HouseName = tostring(args[1])
    local Owner = QBCore.Functions.GetPlayer(tonumber(args[2]))
    if not Owner then Owner = QBCore.Functions.GetPlayerByCitizenId(tostring(args[2])) end
    if not Owner then Notify(src, Lang:t('error.owner_not_found'), 'error') return end
    local Ped = GetPlayerPed(src)
    local PlayerCoords = GetEntityCoords(Ped)
    local PlayerHeading = GetEntityHeading(Ped)
    local AmountOfHouses = (GetResourceKvpInt("Housescount") or 0) + 1
    Config.OpenHouses[AmountOfHouses] = {
        house = HouseName,
        owner = Owner.PlayerData.citizenid,
        doors = {},
        keyholders = {},
        center = PlayerCoords,
        stash = vector3(0, 0, -150),
        outfit = vector3(0, 0, -150),
        logout = vector3(0, 0, -150),
        garage = vector3(0, 0, -150),
        spawn = vector4(PlayerCoords.x, PlayerCoords.y, PlayerCoords.z, PlayerHeading)
    }
    SetResourceKvp('Openhouse_'..tostring(AmountOfHouses), json.encode(Config.OpenHouses[AmountOfHouses]))
    SetResourceKvpInt('Housescount', AmountOfHouses)
    Notify(src, Lang:t('success.create_house', {house = HouseName, owner = Owner.PlayerData.charinfo.firstname}), 'success')
    TriggerClientEvent('dc-open-houses:client:sync', -1, Config.OpenHouses)
    TriggerClientEvent('dc-open-houses:client:CreateBlip', Owner.PlayerData.source, PlayerCoords, HouseName)
end, 'admin')

QBCore.Commands.Add('deleteallhouses', Lang:t('command.delete_all'), {}, false, function(source)
    local Lenght = GetResourceKvpInt("Housescount") or 0
    for i = 1, Lenght do
        DeleteResourceKvpNoSync('Openhouse_'..tostring(i))
    end
    Notify(source, Lang:t('info.deleted_houses', {amount = Lenght}))
    SetResourceKvpIntNoSync('Housescount', 0)
    FlushResourceKvp()
    Config.OpenHouses = {}
    TriggerClientEvent('dc-open-houses:client:sync', -1, Config.OpenHouses)
end, 'god')

QBCore.Commands.Add('deleteopenhouse', Lang:t('command.delete_house'), {{name = 'House Name', help = Lang:t('command.name_of_house')}}, true, function(source, args)
    for i = 1, #Config.OpenHouses do
        if Config.OpenHouses[i].house == tostring(args[1]) then
            DeleteResourceKvpNoSync('Openhouse_'..tostring(i))
            SetResourceKvpIntNoSync('Housescount', #Config.OpenHouses - 1)
            Notify(source, Lang:t('success.deleted_house', {house = tostring(args[1])}), 'success')
            local Owner = QBCore.Functions.GetPlayerByCitizenId(Config.OpenHouses[i].owner)
            TriggerClientEvent('dc-open-houses:client:DeleteBlip', Owner.PlayerData.source, Config.OpenHouses[i].center)
            table.remove(Config.OpenHouses, i)
            break
        end
    end
    FlushResourceKvp()
    TriggerClientEvent('dc-open-houses:client:sync', -1, Config.OpenHouses)
end, 'god')

QBCore.Commands.Add('addstash', Lang:t('command.create_stash'), {}, false, function(source)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local ClosestHouseIndex = GetClosestHouseIndex(src)
    local ClosestHouse = Config.OpenHouses[ClosestHouseIndex]
    local Doors = {}

    if not ClosestHouse then Notify(src, Lang:t('error.not_nearby_house'), 'error') return end
    if Player.PlayerData.citizenid ~= ClosestHouse.owner and not QBCore.Functions.HasPermission(src, 'admin') then Notify(src, Lang:t('error.no_perms'), 'error') return end

    local House = json.decode(GetResourceKvpString('Openhouse_'..tostring(ClosestHouseIndex)))
    for i = 1, #House.doors do
        Doors[i] = {
            name = House.doors[i].name,
            coords = vector3(House.doors[i].coords.x, House.doors[i].coords.y, House.doors[i].coords.z),
            locked = House.doors[i].locked
        }
    end
    Config.OpenHouses[ClosestHouseIndex] = {
        house = House.house,
        owner = House.owner,
        doors = Doors,
        keyholders = House.keyholders,
        center = vector3(House.center.x, House.center.y, House.center.z),
        stash = GetEntityCoords(GetPlayerPed(src)),
        outfit = vector3(House.outfit.x, House.outfit.y, House.outfit.z),
        logout = vector3(House.logout.x, House.logout.y, House.logout.z),
        garage = vector3(House.garage.x, House.garage.y, House.garage.z),
        spawn = vector4(House.spawn.x, House.spawn.y, House.spawn.z, House.spawn.w)
    }
    SetResourceKvp('Openhouse_'..tostring(ClosestHouseIndex), json.encode(Config.OpenHouses[ClosestHouseIndex]))
    Notify(src, Lang:t('success.create_stash', {house = Config.OpenHouses[ClosestHouseIndex].house}), 'success')
    TriggerClientEvent('dc-open-houses:client:sync', -1, Config.OpenHouses)
end)

QBCore.Commands.Add('addoutfit', Lang:t('command.create_outfit'), {}, false, function(source)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local ClosestHouseIndex = GetClosestHouseIndex(src)
    local ClosestHouse = Config.OpenHouses[ClosestHouseIndex]
    local Doors = {}

    if not ClosestHouse then Notify(src, Lang:t('error.not_nearby_house'), 'error') return end
    if Player.PlayerData.citizenid ~= ClosestHouse.owner and not QBCore.Functions.HasPermission(src, 'admin') then Notify(src, Lang:t('error.no_perms'), 'error') return end

    local House = json.decode(GetResourceKvpString('Openhouse_'..tostring(ClosestHouseIndex)))
    for i = 1, #House.doors do
        Doors[i] = {
            name = House.doors[i].name,
            coords = vector3(House.doors[i].coords.x, House.doors[i].coords.y, House.doors[i].coords.z),
            locked = House.doors[i].locked
        }
    end
    Config.OpenHouses[ClosestHouseIndex] = {
        house = House.house,
        owner = House.owner,
        doors = Doors,
        keyholders = House.keyholders,
        center = vector3(House.center.x, House.center.y, House.center.z),
        stash = vector3(House.stash.x, House.stash.y, House.stash.z),
        outfit = GetEntityCoords(GetPlayerPed(src)),
        logout = vector3(House.logout.x, House.logout.y, House.logout.z),
        garage = vector3(House.garage.x, House.garage.y, House.garage.z),
        spawn = vector4(House.spawn.x, House.spawn.y, House.spawn.z, House.spawn.w)
    }
    SetResourceKvp('Openhouse_'..tostring(ClosestHouseIndex), json.encode(Config.OpenHouses[ClosestHouseIndex]))
    Notify(src, Lang:t('success.create_outfit', {house = Config.OpenHouses[ClosestHouseIndex].house}), 'success')
    TriggerClientEvent('dc-open-houses:client:sync', -1, Config.OpenHouses)
end)

QBCore.Commands.Add('addlogout', Lang:t('command.create_logout'), {}, false, function(source)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local ClosestHouseIndex = GetClosestHouseIndex(src)
    local ClosestHouse = Config.OpenHouses[ClosestHouseIndex]
    local Doors = {}

    if not ClosestHouse then Notify(src, Lang:t('error.not_nearby_house'), 'error') return end
    if Player.PlayerData.citizenid ~= ClosestHouse.owner and not QBCore.Functions.HasPermission(src, 'admin') then Notify(src, Lang:t('error.no_perms'), 'error') return end

    local House = json.decode(GetResourceKvpString('Openhouse_'..tostring(ClosestHouseIndex)))
    for i = 1, #House.doors do
        Doors[i] = {
            name = House.doors[i].name,
            coords = vector3(House.doors[i].coords.x, House.doors[i].coords.y, House.doors[i].coords.z),
            locked = House.doors[i].locked
        }
    end
    Config.OpenHouses[ClosestHouseIndex] = {
        house = House.house,
        owner = House.owner,
        doors = Doors,
        keyholders = House.keyholders,
        center = vector3(House.center.x, House.center.y, House.center.z),
        stash = vector3(House.stash.x, House.stash.y, House.stash.z),
        outfit = vector3(House.outfit.x, House.outfit.y, House.outfit.z),
        logout = GetEntityCoords(GetPlayerPed(src)),
        garage = vector3(House.garage.x, House.garage.y, House.garage.z),
        spawn = vector4(House.spawn.x, House.spawn.y, House.spawn.z, House.spawn.w)
    }
    SetResourceKvp('Openhouse_'..tostring(ClosestHouseIndex), json.encode(Config.OpenHouses[ClosestHouseIndex]))
    Notify(src, Lang:t('success.create_logout', {house = Config.OpenHouses[ClosestHouseIndex].house}), 'success')
    TriggerClientEvent('dc-open-houses:client:sync', -1, Config.OpenHouses)
end)

QBCore.Commands.Add('addgarageopen', Lang:t('command.create_garage'), {}, false, function(source)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local ClosestHouseIndex = GetClosestHouseIndex(src)
    local ClosestHouse = Config.OpenHouses[ClosestHouseIndex]
    local Doors = {}

    if not ClosestHouse then Notify(src, Lang:t('error.not_nearby_house'), 'error') return end
    if Player.PlayerData.citizenid ~= ClosestHouse.owner and not QBCore.Functions.HasPermission(src, 'admin') then Notify(src, Lang:t('error.no_perms'), 'error') return end

    local House = json.decode(GetResourceKvpString('Openhouse_'..tostring(ClosestHouseIndex)))
    for i = 1, #House.doors do
        Doors[i] = {
            name = House.doors[i].name,
            coords = vector3(House.doors[i].coords.x, House.doors[i].coords.y, House.doors[i].coords.z),
            locked = House.doors[i].locked
        }
    end
    Config.OpenHouses[ClosestHouseIndex] = {
        house = House.house,
        owner = House.owner,
        doors = Doors,
        keyholders = House.keyholders,
        center = vector3(House.center.x, House.center.y, House.center.z),
        stash = vector3(House.stash.x, House.stash.y, House.stash.z),
        outfit = vector3(House.outfit.x, House.outfit.y, House.outfit.z),
        logout = vector3(House.logout.x, House.logout.y, House.logout.z),
        garage = GetEntityCoords(GetPlayerPed(src)),
        spawn = vector4(House.spawn.x, House.spawn.y, House.spawn.z, House.spawn.w)
    }
    SetResourceKvp('Openhouse_'..tostring(ClosestHouseIndex), json.encode(Config.OpenHouses[ClosestHouseIndex]))
    Notify(src, Lang:t('success.create_garage', {house = Config.OpenHouses[ClosestHouseIndex].house}), 'success')
    TriggerClientEvent('dc-open-houses:client:sync', -1, Config.OpenHouses)
end)

QBCore.Commands.Add('adddoor', Lang:t('command.create_door'), {{name = 'Door Name', help = Lang:t('command.door_name')}}, true, function(source, args)
    local src = source
    local ClosestHouseIndex = GetClosestHouseIndex(src)
    local ClosestHouse = Config.OpenHouses[ClosestHouseIndex]

    if not ClosestHouse then Notify(src, Lang:t('error.not_nearby_house'), 'error') return end

    local House = json.decode(GetResourceKvpString('Openhouse_'..tostring(ClosestHouseIndex)))
    local Doors = {}
    for i = 1, #House.doors do
        Doors[i] = {
            name = House.doors[i].name,
            coords = vector3(House.doors[i].coords.x, House.doors[i].coords.y, House.doors[i].coords.z),
            locked = House.doors[i].locked
        }
    end
    Doors[#Doors + 1] = {
        name = tostring(args[1]),
        coords = GetEntityCoords(GetPlayerPed(src)),
        locked = true
    }
    Config.OpenHouses[ClosestHouseIndex] = {
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
    SetResourceKvp('Openhouse_'..tostring(ClosestHouseIndex), json.encode(Config.OpenHouses[ClosestHouseIndex]))
    Notify(src, Lang:t('success.create_door', {house = Config.OpenHouses[ClosestHouseIndex].house}), 'success')
    TriggerClientEvent('dc-open-houses:client:sync', -1, Config.OpenHouses)
end, 'admin')

QBCore.Commands.Add('givehousekeys', Lang:t('command.give_keys'), {{name = 'Target ID', help = Lang:t('command.target_keys')}}, true, function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local Target = QBCore.Functions.GetPlayer(tonumber(args[1]))
    if not Target then Target = QBCore.Functions.GetPlayerByCitizenId(tostring(args[1])) end
    if not Target then Notify(src, Lang:t('error.target_not_found'), 'error') return end
    local ClosestHouseIndex = GetClosestHouseIndex(src)
    local ClosestHouse = Config.OpenHouses[ClosestHouseIndex]
    local Doors = {}

    if not ClosestHouse then Notify(src, Lang:t('error.not_nearby_house'), 'error') return end
    if Player.PlayerData.citizenid ~= ClosestHouse.owner and not QBCore.Functions.HasPermission(src, 'admin') then Notify(src, Lang:t('error.no_perms'), 'error') return end
    if Player.PlayerData.citizenid == Target.PlayerData.citizenid then Notify(src, Lang:t('error.cant_give_keys_to_self'), 'error') return end

    local House = json.decode(GetResourceKvpString('Openhouse_'..tostring(ClosestHouseIndex)))
    for i = 1, #House.doors do
        Doors[i] = {
            name = House.doors[i].name,
            coords = vector3(House.doors[i].coords.x, House.doors[i].coords.y, House.doors[i].coords.z),
            locked = House.doors[i].locked
        }
    end
    local KeyHolders = House.keyholders or {}
    KeyHolders[#KeyHolders + 1] = Target.PlayerData.citizenid
    Config.OpenHouses[ClosestHouseIndex] = {
        house = House.house,
        owner = House.owner,
        doors = Doors,
        keyholders = KeyHolders,
        center = vector3(House.center.x, House.center.y, House.center.z),
        stash = vector3(House.stash.x, House.stash.y, House.stash.z),
        outfit = vector3(House.outfit.x, House.outfit.y, House.outfit.z),
        logout = vector3(House.logout.x, House.logout.y, House.logout.z),
        garage = vector3(House.garage.x, House.garage.y, House.garage.z),
        spawn = vector4(House.spawn.x, House.spawn.y, House.spawn.z, House.spawn.w)
    }
    SetResourceKvp('Openhouse_'..tostring(ClosestHouseIndex), json.encode(Config.OpenHouses[ClosestHouseIndex]))
    Notify(src, Lang:t('success.give_keys', {target = Target.PlayerData.charinfo.firstname}), 'success')
    TriggerClientEvent('dc-open-houses:client:sync', -1, Config.OpenHouses)
end)

QBCore.Commands.Add('removehousekeys', Lang:t('command.remove_keys'), {{name = 'Target ID', help = Lang:t('command.target_keys')}}, true, function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local Target = QBCore.Functions.GetPlayer(tonumber(args[1]))
    if not Target then Target = QBCore.Functions.GetPlayerByCitizenId(tostring(args[1])) end
    if not Target then Notify(src, Lang:t('error.target_not_found'), 'error') return end
    local ClosestHouseIndex = GetClosestHouseIndex(src)
    local ClosestHouse = Config.OpenHouses[ClosestHouseIndex]
    local Doors = {}

    if not ClosestHouse then Notify(src, Lang:t('error.not_nearby_house'), 'error') return end
    if Player.PlayerData.citizenid ~= ClosestHouse.owner and not QBCore.Functions.HasPermission(src, 'admin') then Notify(src, Lang:t('error.no_perms'), 'error') return end
    if Player.PlayerData.citizenid == Target.PlayerData.citizenid then Notify(src, Lang:t('error.cant_remove_keys_from_self'), 'error') return end

    local House = json.decode(GetResourceKvpString('Openhouse_'..tostring(ClosestHouseIndex)))
    for i = 1, #House.doors do
        Doors[i] = {
            name = House.doors[i].name,
            coords = vector3(House.doors[i].coords.x, House.doors[i].coords.y, House.doors[i].coords.z),
            locked = House.doors[i].locked
        }
    end
    local KeyHolders = House.keyholders or {}
    for i = 1, #KeyHolders do
        if KeyHolders[i] == Target.PlayerData.citizenid then
            table.remove(KeyHolders, i)
            break
        end
    end
    Config.OpenHouses[ClosestHouseIndex] = {
        house = House.house,
        owner = House.owner,
        doors = Doors,
        keyholders = KeyHolders,
        center = vector3(House.center.x, House.center.y, House.center.z),
        stash = vector3(House.stash.x, House.stash.y, House.stash.z),
        outfit = vector3(House.outfit.x, House.outfit.y, House.outfit.z),
        logout = vector3(House.logout.x, House.logout.y, House.logout.z),
        garage = vector3(House.garage.x, House.garage.y, House.garage.z),
        spawn = vector4(House.spawn.x, House.spawn.y, House.spawn.z, House.spawn.w)
    }
    SetResourceKvp('Openhouse_'..tostring(ClosestHouseIndex), json.encode(Config.OpenHouses[ClosestHouseIndex]))
    Notify(src, Lang:t('success.remove_keys', {target = Target.PlayerData.charinfo.firstname}), 'success')
    TriggerClientEvent('dc-open-houses:client:sync', -1, Config.OpenHouses)
end)

QBCore.Commands.Add('viewallhouses', Lang:t('command.viewallhouses'), {}, false, function(source)
    TriggerClientEvent('dc-open-houses:client:viewallhouses', source, Config.OpenHouses)
end, 'god')
