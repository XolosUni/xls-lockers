exports.ox_inventory:RegisterStash('legion', 'Legion private lockers', 30, 200000, true)
local QBCore = exports['qb-core']:GetCoreObject()

local config = {
    hour = 800,
    maxHours = 24,
}

local lockers = { -- each locker individually defined
    vector3(174.48, -926.51, 29.79),
    vector3(174.06, -926.2, 29.79),
    vector3(173.64, -925.9, 29.79),
    vector3(173.22, -925.6, 29.79),
    vector3(172.8, -925.29, 29.79),
    vector3(172.37, -924.99, 29.8)
}

local purchasingPed = vector3(176.11, -927.43, 30.69)

local playersInLoop = {}

RegisterServerEvent('xls-lockers:server:handleTime')
AddEventHandler('xls-lockers:server:handleTime', function()
    local src = source
    local playerPed = GetPlayerPed(src)
    local Player = QBCore.Functions.GetPlayer(src)
    local citizen = Player.PlayerData.citizenid

    table.insert(playersInLoop, src) -- fixed: playersInLoop.insert → table.insert

    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(60000) -- 1 minute in milliseconds

            local validplrcheck = false
            for i, v in pairs(playersInLoop) do
                if v == src then
                    validplrcheck = true
                end
            end

            local result = MySQL.query.await('SELECT mins FROM lockers WHERE identifier = ?;', {
                citizen
            })

            if result and #result > 0 then
                local mins = result[1].mins
                if mins > 0 then
                    MySQL.update('UPDATE lockers SET mins = mins - ? WHERE identifier = ?;', { -- fixed: was MySQL.insert
                        1, citizen
                    })

                    -- this reassignment was wrong logic-wise but left it as-is per your request
                    local mins = result[1].mins 
                    if mins == 1 then
                        QBCore.Functions.Notify(src, {'Lockers Notification', 'You do not have any time left!'}, 'error', 2000)
                    end
                end
            end
        end
    end)
end)

-- Clear player from tracking on disconnect
AddEventHandler('playerDropped', function()
    local src = source
    playersInLoop[src] = nil
end)



RegisterNetEvent('xls-lockers:server:openLocker')
AddEventHandler('xls-lockers:server:openLocker', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local citizen = Player.PlayerData.citizenid

    local iscloseToLocker = false
    for i, v in pairs(lockers) do
        local lockercoords = v
        local playerCoords = GetEntityCoords(GetPlayerPed(src))
        if #(playerCoords - lockercoords) < 2.5 then
            iscloseToLocker = true
            break
        end
    end
    if not iscloseToLocker then
        QBCore.Functions.Notify(src, {'Action failed', 'You are too far from the locker!'}, 'error', 2000)
        return
    end
    local result = MySQL.query.await('SELECT mins FROM lockers WHERE identifier = ?;', {
        citizen
    })
    if result and #result > 0 then
        local mins = result[1].mins
        if mins <= 0 then
            QBCore.Functions.Notify(src, {'Action failed', 'You do not have any time left!'}, 'error', 2000)
            return
        end
        if mins/60 < 1 then
            QBCore.Functions.Notify(src, {'Lockers Notification', 'You have only ' .. mins .. 'M left!'}, 'warning', 2000)
            TriggerClientEvent('ox_inventory:openInventory', src, {type = 'stash', id = 'legion'})
            return
        elseif mins % 60 == 0 then
            QBCore.Functions.Notify(src, {'Lockers Notification', 'You have ' .. math.floor(mins/60).. 'h left'}, 'inform', 2000)
            TriggerClientEvent('ox_inventory:openInventory', src, {type = 'stash', id = 'legion'})
            return
        end
        QBCore.Functions.Notify(src, {'Lockers Notification', 'You have ' .. math.floor(mins/60)..'H and ' .. math.floor(mins%60) .. 'M left!' }, 'inform', 2000)
        TriggerClientEvent('ox_inventory:openInventory', src, {type = 'stash', id = 'legion'})
    else
        MySQL.insert('INSERT INTO lockers (identifier, mins) VALUES (?, ?);', {
            Player.PlayerData.citizenid, 0
        })
        QBCore.Functions.Notify(src, {'Action failed', 'First buy some minutes from the guy'}, 'error', 10000)
        QBCore.Functions.Notify(src, {'Action failed', 'And only then you could open your locker!'}, 'error', 10000)
        QBCore.Functions.Notify(src, {'Action failed', 'I see this is your first time here?'}, 'error', 10000)
    end

end)

RegisterNetEvent('xls-lockers:server:transferTime')
AddEventHandler('xls-lockers:server:transferTime', function(hours, id)
    local src = source
    local playerPed = GetPlayerPed(src)
    local Player = QBCore.Functions.GetPlayer(src)
    local citizen = Player.PlayerData.citizenid
    hours = hours*60
    print(hours)
    if #(GetEntityCoords(playerPed) - purchasingPed) > 1.6 then
        QBCore.Functions.Notify(src, {'Action failed', 'You are too far from the seller!'}, 'error', 2000)
        return
    end

    local result = MySQL.query.await('SELECT mins FROM lockers WHERE identifier = ?;', {
        citizen
    })

    if result and #result > 0 then
        local mins = result[1].mins
        if mins < hours then
            QBCore.Functions.Notify(src, {'Action failed', 'You don\'t own that much!'}, 'error', 2000)
        end
        local trgplr = QBCore.Functions.GetPlayer(id) -- 12 = server ID
        if not trgplr then
            QBCore.Functions.Notify(src, {'Lockers Notification', 'Can\'nt find the player'}, 'error', 2000)
            return
        end
        local trgCitizen = trgplr.PlayerData.citizenid

        
        
        QBCore.Functions.Notify(src, {'Lockers Notification', hours/60 .. 'H have been removed from your balance' }, 'error', 2000)
        MySQL.query.await('UPDATE lockers SET mins = mins - ? WHERE identifier = ?;', { -- fixed: was MySQL.insert
            hours, citizen
        })
        QBCore.Functions.Notify(id, {'Lockers Notification', hours/60 .. 'H have been added to your balance' }, 'error', 2000)
        MySQL.query.await('UPDATE lockers SET mins = mins + ? WHERE identifier = ?;', { -- fixed: was MySQL.insert
            hours, trgCitizen
        })

    end



end)

RegisterNetEvent('xls-lockers:server:purchaseTime')
AddEventHandler('xls-lockers:server:purchaseTime', function(hours, method)
    local src = source
    local playerPed = GetPlayerPed(src)
    local plyrcoords = GetEntityCoords(playerPed)
    local Player = QBCore.Functions.GetPlayer(src)
    local plyrsMoney = Player.PlayerData.money[method]

    if #(plyrcoords - purchasingPed) > 1.6 then
        QBCore.Functions.Notify(src, {'Action failed', 'You are too far from the seller!'}, 'error', 2000)
        return
    end

    local payment = config.hour * hours
    if hours > config.maxHours then
        TriggerClientEvent('QBCore:Notify', src, 'You can only purchase up to '..config.maxHours..' hours!', 'error')
        return
    end
    if payment > plyrsMoney then
        QBCore.Functions.Notify(src, {'Action failed', 'You do not have enough cash!'}, 'error', 2000)
        return
    end
    local hr
    local result = MySQL.query.await('SELECT mins FROM lockers WHERE identifier = ?;', {
        Player.PlayerData.citizenid
    })
    if result and #result > 0 then
        hr = result[1].mins
        
    else
        MySQL.insert('INSERT INTO lockers (identifier, mins) VALUES (?, ?);', {
            Player.PlayerData.citizenid, 0
        })
        QBCore.Functions.Notify(src, {'Action failed', 'i\'ve added time to your balance, have fun!'}, 'inform', 10000)
        QBCore.Functions.Notify(src, {'Action failed', 'you can store whatever in the locker, and police can\'nt search it!'}, 'inform', 10000)
        QBCore.Functions.Notify(src, {'Action failed', 'with hours you can open the locker next to me'}, 'inform', 10000)
        QBCore.Functions.Notify(src, {'Action failed', 'Right now you have bought hours'}, 'inform', 10000)
        QBCore.Functions.Notify(src, {'Action failed', 'I see this is your first time here?'}, 'inform', 10000)

        Player.Functions.RemoveMoney(method, payment)
        local result = MySQL.query.await('UPDATE lockers SET mins = mins + ? WHERE identifier = ?;', {
            hours*60, Player.PlayerData.citizenid
        })
        return
    end
    if hr/60 + hours > config.maxHours then
        QBCore.Functions.Notify(src, {'Action failed', 'You can only own up to '..config.maxHours..' hours!'}, 'error', 2000)
        return
    end
    
    
    Player.Functions.RemoveMoney(method, payment)
    QBCore.Functions.Notify(src, {'Removed money', tostring(payment) .. '$ have been removed from your bank'}, 'warning', 2000)
    QBCore.Functions.Notify(src, {'Added balance', tostring(payment) .. '$ you have received ' .. tostring(hours) .. 'hours to your locker'}, 'inform', 2000)
    local result = MySQL.query.await('UPDATE lockers SET mins = mins + ? WHERE identifier = ?;', {
        hours*60, Player.PlayerData.citizenid
    })
    
end)


QBCore.Commands.Add('checklockers', 'Check how much time you have left!', {}, false, function (source)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local citizen = Player.PlayerData.citizenid

    local result = MySQL.query.await('SELECT mins FROM lockers WHERE identifier = ?;', {
        citizen
    })
    if result and #result > 0 then
        local mins = result[1].mins
        if mins <= 0 then
            QBCore.Functions.Notify(src, {'Action failed', 'You do not have any time left!'}, 'error', 2000)
            return
        end
        if mins/60 < 1 then
            QBCore.Functions.Notify(src, {'Lockers Notification', 'You have only ' .. mins .. 'M left!'}, 'warning', 5000)
            return
        elseif mins % 60 == 0 then
            QBCore.Functions.Notify(src, {'Lockers Notification', 'You have ' .. math.floor(mins/60).. 'h left'}, 'inform', 5000)
            return
        end
        QBCore.Functions.Notify(src, {'Lockers Notification', 'You have ' .. math.floor(mins/60)..'H and ' .. math.floor(mins%60) .. 'M left!' }, 'inform', 5000)
        return
    else
        QBCore.Functions.Notify(src, {'Lockers Notification', 'Something went wrong!'}, 'error', 2000)
        return
    end
            

end, 'user')