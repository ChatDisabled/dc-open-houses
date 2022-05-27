# don't even use. pre alpha beta release

# dc-open-houses

An housing system to support open interior houses as owned housing for players.
This is not a job related resource. This is operated by staff since 9/10 these kind of houses are sold by staff anyways.
It is expected that you have the latest version of [qb-doorlock](https://github.com/qbcore-framework/qb-doorlock).
THIS DOESN'T WORK WITH HOUSES THAT DON'T HAVE OPEN DOORS TO ENTER BUT NEED TELEPORTATION!!!
#### *Might* be supported in the future

You can always find support [here](https://discord.gg/SqRsSsSskg) in our Discord.
### Donations are **greatly** appreciated
[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/N4N4BE29E)


## 1. Creating the house

Go stand in the middle of the house. This position will also be used as spawn location inside of `qb-spawn` if you follow `How to add owned houses as spawn locations?` down below.
Now use the command `createopenhouse` along with the name of the house <sub>The name has to be **unique**</sub> and the server ID or CitizenID of the owner <sub>The owner has to be **online**</sub>.

## 2. Setting up the doors

Go stand in the middle of the door so that the door will be pushed half open. Now use the command `adddoor` along side with an **unique** name <sub>**Copy** the name, you will need it later.</sub>. Now use the `newdoor` command to create a new door inside of `qb-doorlock`. The configuration of the door should look like the following screenshot. Important points being: HouseName should be the name of the house you are in now. Makes it easier to find the doors back inside of `qb-doorlock`. Copied DoorName being the same name you used when doing the `adddoor` command.
[x] Locked
[x] Can't Unlock
[x] Hide Door Label

![image](https://cdn.discordapp.com/attachments/967850345306914826/979872034278498344/unknown.png)

## 3. Setting up interactions

Now either you or the owner can use the commands `addstash`, `addoutfit` or `addlogout`.

## How to add owned houses as spawn locations?

Your `qb-spawn` resource should have the following lines on the client side.

https://github.com/qbcore-framework/qb-spawn/blob/716b376cf1d06a6671cd4c08b7d346acf2d56c8a/client.lua#L57-L62

Replace those with the following.

```
            local OldConfig = QB.Spawns
            for i = 1, #OpenHouses do
                if OpenHouses[i].owner == cData.citizenid then
                    if QB.Spawns[OpenHouses[i].house] then return end
                    QB.Spawns[OpenHouses[i].house] = {
                        coords = OpenHouses[i].spawn,
                        location = OpenHouses[i].house,
                        label = OpenHouses[i].house,
                    }
                end
            end
            local NewConfig = QB.Spawns
            QB.Spawns = OldConfig
            Wait(500)
            SendNUIMessage({
                action = "setupLocations",
                locations = NewConfig,
                houses = myHouses,
            })
```

And now add the following lines anywhere in the same file

```
RegisterNetEvent('dc-open-houses:client:sync', function(OpenHousesConfig)
    OpenHouses = OpenHousesConfig
end)
```

## Known Bugs

If you logout with a character that owns a house without disconnecting, and you then want to log back in with another character. The house will still be listed in the spawn list. Since only the owner of the house will see this I don't expect any abuse unless the owner wants to lock himself inside of an house he doesn't have keys for.