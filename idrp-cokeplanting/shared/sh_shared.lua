Shared = Shared or {}

--- Other
Shared.Debug = false
Shared.CopJob = "leo"
Shared.Dispatch = "ps-dispatch"

--- Items
Shared.CokeSeed = 'cokeplant_seed'
Shared.EmptyCanItem = 'empty_watering_can'
Shared.FullCanItem = 'full_watering_can'
Shared.FertilizerItem = 'weed_nutrition'
Shared.WaterItem = 'water_bottle'
Shared.HarvestItem = 'coca_leaf'

--- Props
Shared.CokeProps = {
    [1] = `coke_stage001`,
    [2] = `coke_stage002`,
    [3] = `coke_stage002`,
    [4] = `coke_stage003`,
    [5] = `coke_stage003`
}

--- Growing Related Settings
Shared.rayCastingDistance = 7.0 -- distance in meters
Shared.ClearOnStartup = true -- Clear dead plants on script start-up
Shared.ObjectZOffset = - 0.1 -- Z-coord offset for CokeProps
Shared.FireTime = 10000

Shared.GrowTime = 5 -- Time in minutes for a plant to grow from 0 to 100
Shared.LoopUpdate = 2 -- Time in minutes to perform a loop update for water, nutrition, health, growth, etc.
Shared.WaterDecay = 0.4 -- Percent of water that decays every minute
Shared.FertilizerDecay = 0.4 -- Percent of fertilizers that decays every minute

Shared.FertilizerThreshold = 40
Shared.WaterThreshold = 40
Shared.HealthBaseDecay = {7, 10} -- Min/Max Amount of health decay when the plant is below the above thresholds for water and nutrition

