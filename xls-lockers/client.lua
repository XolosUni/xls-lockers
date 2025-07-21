local QBCore = exports['qb-core']:GetCoreObject()


local ped
local Locker1
local Locker2
local Locker3
local Locker4
local Locker5
local Locker6

local GlobalHeading = 144.19

Citizen.CreateThread(function ()

    local lockerModel = 'p_cs_locker_01_s'
    local lockerHash  = GetHashKey(lockerModel)

    RequestModel(lockerHash)

    Citizen.Wait(70) 
    while not HasModelLoaded(lockerHash) do RequestModel(lockerHash) print('Still Loading') Citizen.Wait(70) end
    

    Locker1 = CreateObject(lockerHash, 173.64, -925.9, 30.69 -1, false, false, false)
    SetEntityHeading(Locker1, GlobalHeading)
    FreezeEntityPosition(Locker1, true)

    local pos2 = GetOffsetFromEntityInWorldCoords(Locker1, 0.52, 0.0, -0.10)
    Locker2 = CreateObject(lockerHash, pos2.x, pos2.y, pos2.z, false, false, false)
    SetEntityHeading(Locker2, GlobalHeading)
    FreezeEntityPosition(Locker2, true)

    -- Create Locker3 to the left (offset in X negative)
    local pos3 = GetOffsetFromEntityInWorldCoords(Locker1, -0.52, 0.0, -0.10)
    Locker3 = CreateObject(lockerHash, pos3.x, pos3.y, pos3.z, false, false, false)
    SetEntityHeading(Locker3, GlobalHeading)
    FreezeEntityPosition(Locker3, true)

    local pos4 = GetOffsetFromEntityInWorldCoords(Locker3, -0.52, 0.0, -0.10)
    Locker4 = CreateObject(lockerHash, pos4.x, pos4.y, pos4.z, false, false, false)
    SetEntityHeading(Locker4, GlobalHeading)
    FreezeEntityPosition(Locker4, true)

    -- Create Locker3 to the left (offset in X negative)
    local pos5 = GetOffsetFromEntityInWorldCoords(Locker2, 0.52, 0.0, -0.10)
    Locker5 = CreateObject(lockerHash, pos5.x, pos5.y, pos5.z, false, false, false)
    SetEntityHeading(Locker5, GlobalHeading)
    FreezeEntityPosition(Locker5, true)
    
    local pos6 = GetOffsetFromEntityInWorldCoords(Locker5, 0.52, 0.0, -0.10)
    Locker6 = CreateObject(lockerHash, pos6.x, pos6.y, pos6.z, false, false, false)
    SetEntityHeading(Locker6, GlobalHeading)
    FreezeEntityPosition(Locker6, true)

    SetModelAsNoLongerNeeded(lockerHash)



        exports.ox_target:addBoxZone({
            name = "Lockerboxzone",
            coords = vec3(173.5, -925.75, 30.75),
            size = vec3(0.75, 3.25, 2.0),
            rotation = 55.0,
            options = {
                {
                    label = 'Access locker',
                    name  = 'LockersTarget',
                    icon  = 'fa-solid fa-toolbox',
                    distance = 2.5,
                    onSelect = function ()
                        if IsPedInAnyVehicle(PlayerPedId(), true) then 
                            QBCore.Functions.Notify({'Unavailable', "You can't reach for the locker inside a vehicle!"}, "error", 5000, 'ban')
                            return 
                        end
                        local playerLoc = GetEntityCoords(PlayerPedId()) -- Gets the player's current location
                        local LockerLoc = GetEntityCoords(Locker1)       -- Example locker position
                        
                        if #(playerLoc - LockerLoc) <= 6 then
                            TriggerServerEvent('xls-lockers:server:openLocker')
                        else
                            QBCore.Functions.Notify({'Unavailable', "You are too far from the locker!"}, "error", 5000, 'ban')
                            return
                        end
                        
                    end
                }
            }
        })

        local vec4ped = vector4(176.11, -927.43, 30.69, 351.44)
        local pedmodel = 'a_m_m_ktown_01'
        local pedHash = GetHashKey(pedmodel)
        RequestModel(pedHash)
        while not HasModelLoaded(pedHash) do
            RequestModel(pedHash)
            Citizen.Wait(100)
        end
        ped = CreatePed(0, pedHash, vec4ped.x, vec4ped.y, vec4ped.z -1, vec4ped.w, false, false)
        FreezeEntityPosition(ped, true)
        FreezeEntityPosition(ped, true)
        SetEntityInvincible(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)

        exports.ox_target:addLocalEntity(ped, {
            name = 'LockerSeller',
            label = 'Purchase lockers time',
            icon = 'fa-solid fa-clock',
            distance = 1.5,
            onSelect = function ()
                -- local PlayerPed = PlayerPedId()
                -- if IsPedInAnyVehicle(PlayerPed, true) then 
                --     QBCore.Functions.Notify({'Unavailable', "You can't talk to the seller from a vehicle!"}, "error", 2000, 'ban')
                --     return 
                -- end

                -- local input = lib.inputDialog('Purchase hours', {
                --     { type = 'number', label = 'Hours', description = 'How many hours would you like to purchase?', placeholder = 'for example: 1', required = true, min = 1, max = 12, step = 1},
                --     { type = 'select', label = 'Payment method', description = 'Choose your payment method', options = { { value = 'cash', label = 'Cash' }, { value = 'bank', label = 'Bank' }}, required = true, default = 'cash' }
                    
                -- }) 
                -- print(json.encode(input))
                -- if not input then return end
                -- local hours = tonumber(input[1])
                -- hours = math.floor(hours)

                -- TriggerServerEvent('xls-lockers:server:purchaseTime', hours, input[2])

                lib.registerContext(
                    {
                        id = 'LockerPurchaseContext',
                        title = 'Purchase hours',
                        onBack = function()
                            lib.hideContext(true)
                        end,
                        options = {
                            {
                                title = 'Purchase hours',
                                description = 'Purchase access to the lockers for a certain amount of time.',
                                icon = 'fa-solid fa-clock',
                                onSelect = function()
                                    local input = lib.inputDialog('Purchase hours', {
                                        { type = 'number', label = 'Hours', description = 'How many hours would you like to purchase?', placeholder = 'for example: 1', required = true, min = 1, max = 12, step = 1},
                                        { type = 'select', label = 'Payment method', description = 'Choose your payment method', options = { { value = 'cash', label = 'Cash' }, { value = 'bank', label = 'Bank' }}, required = true, default = 'cash' }
                                        
                                    }) 
                                    if not input then return end
                                    local hours = tonumber(input[1])
                                    hours = math.floor(hours)
                                    TriggerServerEvent('xls-lockers:server:purchaseTime', hours, input[2])
                                end
                            },
                            {
                                title = 'Transfer Hours',
                                description = 'Transfer hours to your friends!',
                                icon = 'fa-solid fa-clock',
                                onSelect = function()
                                    local input = lib.inputDialog('Purchase hours', {
                                        { type = 'number', label = 'Hours', description = 'How many hours would you like to give?', placeholder = 'for example: 1', required = true, min = 1, max = 12, step = 1},
                                        { type = 'number', label = 'Id',    description = 'Who would you like to give your hours to?', placeholder = 'for example: 68', required = true, min = 1, step = 1},
                                    }) 
                                    if not input then return end
                                    local hours = tonumber(input[1])
                                    local id    = tonumber(input[2])
                                    TriggerServerEvent('xls-lockers:server:transferTime', hours, id)
                                end
                            },
                        }
                    }
                )
                lib.showContext('LockerPurchaseContext')
            end

        })






end)
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    TriggerServerEvent('xls-lockers:server:handleTime')
end)









AddEventHandler('onResourceStop', function (resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    if Locker1 then DeleteEntity(Locker1) end
    if Locker2 then DeleteEntity(Locker2) end
    if Locker3 then DeleteEntity(Locker3) end
    if Locker4 then DeleteEntity(Locker4) end
    if Locker5 then DeleteEntity(Locker5) end
    if Locker6 then DeleteEntity(Locker6) end
    if ped     then DeleteEntity(ped)     end
end)