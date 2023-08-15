QBCore = exports['qb-core']:GetCoreObject()
local CokePlants = {}

--- Functions

--- Method to calculate the growth percentage for a given CokePlants index
--- @param k number - CokePlants table index
--- @return retval number - growth index [0-100]
local calcGrowth = function(k)
    if not CokePlants[k] then return false end
    local current_time = os.time()
    local growTime = Shared.GrowTime * 60
    local progress = os.difftime(current_time, CokePlants[k].time)
    local growth = QBCore.Shared.Round(progress * 100 / growTime, 2)
    local retval = math.min(growth, 100.00)
    return retval
end

--- Method to calculate the growth stage of a cokeplant for a given growth index
--- @param growth number - growth index [0-100]
--- @return stage number - growth stage number [1-5]
local calcStage = function(growth)
    local stage = math.floor(growth / 20)
    if stage == 0 then stage += 1 end
    return stage
end

--- Method to calculate the current fertilizer percentage for a given CokePlants index
--- @param k number - CokePlants table index
--- @return retval number - fertilizer index [0-100]
local calcFertilizer = function(k)
    if not CokePlants[k] then return false end
    local current_time = os.time()

    if #CokePlants[k].fertilizer == 0 then
        return 0
    else
        local last_fertilizer = CokePlants[k].fertilizer[#CokePlants[k].fertilizer]
        local time_elapsed = os.difftime(current_time, last_fertilizer)
        local fertilizer = QBCore.Shared.Round(100 - (time_elapsed / 60 * Shared.FertilizerDecay), 2)
        local retval = math.max(fertilizer, 0.00)
        return retval
    end
end

--- Method to calculate the current water percentage for a given CokePlants index
--- @param k number - CokePlants table index
--- @return retval number - water index [0-100]
local calcWater = function(k)
    if not CokePlants[k] then return false end
    local current_time = os.time()

    if #CokePlants[k].water == 0 then
        return 0
    else
        local last_water = CokePlants[k].water[#CokePlants[k].water]
        local time_elapsed = os.difftime(current_time, last_water)
        local water = QBCore.Shared.Round(100 - (time_elapsed / 60 * Shared.WaterDecay), 2)
        local retval = math.max(water, 0.00)
        return retval
    end
end

--- Method to calculate the health percentage for a given CokePlants index
--- @param k number - CokePlants table index
--- @return health number - health index [0-100]
local calcHealth = function(k)
    if not CokePlants[k] then return false end
    local health = 100
    local current_time = os.time()
    local planted_time = CokePlants[k].time
    local elapsed_time = os.difftime(current_time, planted_time)
    local intervals = math.floor(elapsed_time / 60 / Shared.LoopUpdate)
    if intervals == 0 then return 100 end

    for i=1, intervals, 1 do
        -- check current water and fertilizer levels at every interval timestamp, if below thresholds, remove some health
        local interval_time = planted_time + (i * Shared.LoopUpdate * 60)

        -- fertilizer at interval_time amount:
        local fertilizer_amount
        if #CokePlants[k].fertilizer == 0 then
            fertilizer_amount = 0
            health -= math.random(Shared.HealthBaseDecay[1], Shared.HealthBaseDecay[2])
        else
            local last_fertilizer = math.huge
            for i=1, #CokePlants[k].fertilizer, 1 do
                last_fertilizer = last_fertilizer < CokePlants[k].fertilizer[i] and last_fertilizer or CokePlants[k].fertilizer[i]
            end
            local time_since_fertilizer = os.difftime(interval_time, last_fertilizer)

            fertilizer_amount = math.max(QBCore.Shared.Round(100 - (time_since_fertilizer / 60 * Shared.FertilizerDecay), 2), 0.00)
            if fertilizer_amount < Shared.FertilizerThreshold then
                health -= math.random(Shared.HealthBaseDecay[1], Shared.HealthBaseDecay[2])
            end
        end

        -- water at interval_time amount:
        local water_amount
        if #CokePlants[k].water == 0 then
            water_amount = 0
            health -= math.random(Shared.HealthBaseDecay[1], Shared.HealthBaseDecay[2])
        else
            local last_water = math.huge
            for i=1, #CokePlants[k].water, 1 do
                last_water = last_water < CokePlants[k].water[i] and last_water or CokePlants[k].water[i]
            end
            local time_since_water = os.difftime(interval_time, last_water)

            water_amount = math.max(QBCore.Shared.Round(100 - (time_since_water / 60 * Shared.WaterDecay), 2), 0.00)
            if water_amount < Shared.WaterThreshold then
                health -= math.random(Shared.HealthBaseDecay[1], Shared.HealthBaseDecay[2])
            end
        end
    end

    return math.max(health, 0.0)
end

--- Method to setup all the cokeplants, fetched from the database
--- @return nil
local setupPlants = function()
    local result = MySQL.Sync.fetchAll('SELECT * FROM cokeplants')
    local current_time = os.time()
    local growTime = Shared.GrowTime * 60

    for k, v in pairs(result) do
        local progress = os.difftime(current_time, v.time)
        local growth = math.min(QBCore.Shared.Round(progress * 100 / growTime, 2), 100.00)
        local stage = calcStage(growth)
        local ModelHash = Shared.CokeProps[stage]
        local coords = json.decode(v.coords)
        local plant = CreateObjectNoOffset(ModelHash, coords.x, coords.y, coords.z + Shared.ObjectZOffset, true, true, false)
        FreezeEntityPosition(plant, true)
        CokePlants[plant] = {
            id = v.id,
            coords = vector3(coords.x, coords.y, coords.z),
            time = v.time,
            fertilizer = json.decode(v.fertilizer),
            water = json.decode(v.water),
        }
    end
end

--- Method to delete all cached coke plants and their entities
--- @return nil
local destroyAllPlants = function()
    for k, v in pairs(CokePlants) do
        if DoesEntityExist(k) then
            DeleteEntity(k)
            CokePlants[k] = nil
        end
    end
end

--- Method to update a plant object, removing the existing one and placing a new object
--- @param k number - CokePlants table index
--- @param stage number - Stage number
--- @return nil
local updatePlantProp = function(k, stage)
    if not CokePlants[k] then return end
    if not DoesEntityExist(k) then return end
    local ModelHash = Shared.CokeProps[stage]
    DeleteEntity(k)
    local plant = CreateObjectNoOffset(ModelHash, CokePlants[k].coords.x, CokePlants[k].coords.y, CokePlants[k].coords.z + Shared.ObjectZOffset, true, true, false)
    FreezeEntityPosition(plant, true)
    CokePlants[plant] = CokePlants[k]
    CokePlants[k] = nil
end

--- Method to perform an update on every cokeplant, updating their prop if needed, repeats every Shared.LoopUpdate minutes
--- @return nil
updatePlants = function()
    for k, v in pairs(CokePlants) do
        local growth = calcGrowth(k)
        local stage = calcStage(growth)
        if stage ~= v.stage then
            CokePlants[k].stage = stage
            updatePlantProp(k, stage)
        end
    end

    SetTimeout(Shared.LoopUpdate * 60 * 1000, updatePlants)
end

--- Resource start/stop events

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    setupPlants()
    if Shared.ClearOnStartup then
        Wait(5000) -- Wait 5 seconds to allow all functions to be executed on startup
        for k, v in pairs(CokePlants) do
            if calcHealth(k) == 0 then
                DeleteEntity(k)
                MySQL.query('DELETE from cokeplants WHERE id = :id', {
                    ['id'] = CokePlants[k].id
                })
                CokePlants[k] = nil
            end
        end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    destroyAllPlants()
end)

--- Events

RegisterNetEvent('ps-cokeplanting:server:ClearPlant', function(netId)
    local entity = NetworkGetEntityFromNetworkId(netId)
    if not CokePlants[entity] then return end
    if #(GetEntityCoords(GetPlayerPed(source)) - CokePlants[entity].coords) > 10 then return end
    if calcHealth(entity) ~= 0 then return end

    if DoesEntityExist(entity) then
        DeleteEntity(entity)
        MySQL.query('DELETE from cokeplants WHERE id = :id', {
            ['id'] = CokePlants[entity].id
        })
        CokePlants[entity] = nil
    end
end)

RegisterNetEvent('ps-cokeplanting:server:HarvestPlant', function(netId)
    local entity = NetworkGetEntityFromNetworkId(netId)
    if not CokePlants[entity] then return end
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    if #(GetEntityCoords(GetPlayerPed(src)) - CokePlants[entity].coords) > 10 then return end
    if calcGrowth(entity) ~= 100 then return end

    if DoesEntityExist(entity) then
        local health = calcHealth(entity)
        local info = { health = health }
        Player.Functions.AddItem(Shared.HarvestItem, 1, false, info)
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Shared.HarvestItem], 'add', 1)
        local cSeeds = math.floor(health / 20)
        Player.Functions.AddItem(Shared.CokeSeed, cSeeds, false)
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Shared.CokeSeed], 'add', cSeeds)
        DeleteEntity(entity)
        MySQL.query('DELETE from cokeplants WHERE id = :id', {
            ['id'] = CokePlants[entity].id
        })
        CokePlants[entity] = nil
    end
end)

RegisterNetEvent('ps-cokeplanting:server:PoliceDestroy', function(netId)
    local entity = NetworkGetEntityFromNetworkId(netId)
    if not CokePlants[entity] then return end
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    if Player.PlayerData.job.type ~= Shared.CopJob then return end
    if #(GetEntityCoords(GetPlayerPed(src)) - CokePlants[entity].coords) > 10 then return end

    if DoesEntityExist(entity) then
        MySQL.query('DELETE from cokeplants WHERE id = :id', {
            ['id'] = CokePlants[entity].id
        })

        TriggerClientEvent('ps-cokeplanting:client:FireGoBrrrrrrr', -1, CokePlants[entity].coords)
        Wait(Shared.FireTime)
        DeleteEntity(entity)

        CokePlants[entity] = nil
    end
end)

RegisterNetEvent('ps-cokeplanting:server:GiveWater', function(netId)
    local entity = NetworkGetEntityFromNetworkId(netId)
    if not CokePlants[entity] then return end
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    if #(GetEntityCoords(GetPlayerPed(src)) - CokePlants[entity].coords) > 10 then return end

    if Player.Functions.RemoveItem(Shared.FullCanItem, 1, false) then
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Shared.FullCanItem], 'remove', 1)
        TriggerClientEvent('QBCore:Notify', src, _U('watered_plant'), 'success', 2500)
        Player.Functions.AddItem(Shared.EmptyCanItem, 1, false)
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Shared.EmptyCanItem], 'add', 1)

        CokePlants[entity].water[#CokePlants[entity].water + 1] = os.time()
        MySQL.update('UPDATE cokeplants SET water = (:water) WHERE id = (:id)', {
            ['water'] = json.encode(CokePlants[entity].water),
            ['id'] = CokePlants[entity].id,
        })
    end
end)

RegisterNetEvent('ps-cokeplanting:server:GiveFertilizer', function(netId)
    local entity = NetworkGetEntityFromNetworkId(netId)
    if not CokePlants[entity] then return end
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    if #(GetEntityCoords(GetPlayerPed(src)) - CokePlants[entity].coords) > 10 then return end

    if Player.Functions.RemoveItem(Shared.FertilizerItem, 1, false) then
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Shared.FertilizerItem], 'remove', 1)
        TriggerClientEvent('QBCore:Notify', src, _U('fertilizer_added'), 'success', 2500)

        CokePlants[entity].fertilizer[#CokePlants[entity].fertilizer + 1] = os.time()
        MySQL.update('UPDATE cokeplants SET fertilizer = (:fertilizer) WHERE id = (:id)', {
            ['fertilizer'] = json.encode(CokePlants[entity].fertilizer),
            ['id'] = CokePlants[entity].id,
        })
    end
end)

RegisterNetEvent('ps-cokeplanting:server:CreateNewPlant', function(coords)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    if #(GetEntityCoords(GetPlayerPed(src)) - coords) > Shared.rayCastingDistance + 10 then return end
    if Player.Functions.RemoveItem(Shared.CokeSeed, 1)then
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Shared.CokeSeed], 'remove', 1)
        local ModelHash = Shared.CokeProps[1]
        local plant = CreateObjectNoOffset(ModelHash, coords.x, coords.y, coords.z + Shared.ObjectZOffset, true, true, false)
        FreezeEntityPosition(plant, true)
        local time = os.time()
        MySQL.insert('INSERT into cokeplants (coords, time, fertilizer, water) VALUES (:coords, :time, :fertilizer, :water)', {
            ['coords'] = json.encode(coords),
            ['time'] = time,
            ['fertilizer'] = json.encode({}),
            ['water'] = json.encode({}),
        }, function(data)
            CokePlants[plant] = {
                id = data,
                coords = coords,
                time = time,
                fertilizer = {},
                water = {},
            }
        end)
    end
end)

RegisterNetEvent('ps-cokeplanting:server:GetFullWateringCan', function(netId)

    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if Player.Functions.RemoveItem(Shared.EmptyCanItem, 1, false) and Player.Functions.RemoveItem(Shared.WaterItem, 1, false) then
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Shared.EmptyCanItem], 'remove', 1)
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Shared.WaterItem], 'remove', 1)
        TriggerClientEvent('QBCore:Notify', src, _U('filled_can'), 'success', 2500)
        Player.Functions.AddItem(Shared.FullCanItem, 1, false)
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Shared.FullCanItem], 'add', 1)
    end
end)

--- Callbacks

QBCore.Functions.CreateCallback('ps-cokeplanting:server:GetPlantData', function(source, cb, netId)
    local entity = NetworkGetEntityFromNetworkId(netId)
    if not CokePlants[entity] then cb(nil) return end
    local temp = {
        id = CokePlants[entity].id,
        coords = CokePlants[entity].coords,
        time = CokePlants[entity].time,
        fertilizer = calcFertilizer(entity),
        water = calcWater(entity),
        stage = calcStage(calcGrowth(entity)),
        health = calcHealth(entity),
        growth = calcGrowth(entity)
    }
    cb(temp)
end)

--- Items

QBCore.Functions.CreateUseableItem(Shared.CokeSeed, function(source)
    local src = source
	local Player = QBCore.Functions.GetPlayer(src)
    --local tub = Player.Functions.GetItemByName(Shared.PlantTubItem)

    --if tub ~= nil then
        TriggerClientEvent("ps-cokeplanting:client:UseCokeSeed", source)
    --else
        --TriggerClientEvent('QBCore:Notify', src, _U('missing_tub'), 'error', 2500)
    --end
end)

QBCore.Functions.CreateUseableItem(Shared.EmptyCanItem, function(source)
    local src = source
    TriggerClientEvent("ps-cokeplanting:client:OpenFillWaterMenu", src)
end)


--- Threads

CreateThread(function()
    Wait(Shared.LoopUpdate * 60 * 1000)
    updatePlants()
end)
