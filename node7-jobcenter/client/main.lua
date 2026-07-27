local RESOURCE = GetCurrentResourceName()
local spawnedPeds = {}
local createdBlips = {}
local registeredInteractions = {}
local nextSpawnAttempt = {}
local boardOpen = false
local activeCenterId
local activeWorkRouteBlip
local boardJobs = {}
local boardLoading = false

local function debugPrint(message)
    if Config.Debug then print(('^5[node7-jobcenter]^7 %s'):format(tostring(message))) end
end

local function notify(description, notificationType, title)
    local ok = pcall(function()
        exports['node7-core']:Notify({
            title = title or 'NODE7 JOB CENTER',
            description = description,
            type = notificationType or 'info',
            duration = 4500
        })
    end)

    if not ok then print(('^3[node7-jobcenter]^7 %s'):format(tostring(description))) end
end

local function releaseNuiFocus()
    SetNuiFocus(false, false)
    if type(SetNuiFocusKeepInput) == 'function' then SetNuiFocusKeepInput(false) end
end

local function closeBoard()
    boardOpen = false
    activeCenterId = nil
    boardJobs = {}
    boardLoading = false
    releaseNuiFocus()
    SendNUIMessage({ action = 'close' })
end

local function clearWorkRoute()
    pcall(function()
        Citizen.InvokeNative(0x4426D65E029A4DC0, false)
        Citizen.InvokeNative(0x9E0AB9AAEE87CE28)
    end)

    if activeWorkRouteBlip and DoesBlipExist(activeWorkRouteBlip) then RemoveBlip(activeWorkRouteBlip) end
    activeWorkRouteBlip = nil
end

local function setWorkRoute(job)
    local coords = job and job.workCoords
    if not coords or coords.x == nil or coords.y == nil or coords.z == nil then return false end

    clearWorkRoute()
    local x, y, z = coords.x + 0.0, coords.y + 0.0, coords.z + 0.0

    local routeOk = pcall(function()
        Citizen.InvokeNative(0x3D3D15AF7BCAAF83, joaat('COLOR_YELLOW'), true, true)
        Citizen.InvokeNative(0x64C59DD6834FA942, x, y, z, true)
        Citizen.InvokeNative(0x4426D65E029A4DC0, true)
    end)

    local blipOk, blip = pcall(function()
        local created = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, x, y, z)
        if created and created ~= 0 then
            Citizen.InvokeNative(0x74F74D3207ED525C, created, (Config.Blip and Config.Blip.sprite) or joaat('blip_shop_store'), true)
            SetBlipScale(created, 0.22)
            Citizen.InvokeNative(0x9CB1A1623062F402, created, job.startLabel or job.label or 'Public Work')
        end
        return created
    end)

    if blipOk and blip and blip ~= 0 then activeWorkRouteBlip = blip end
    return routeOk or activeWorkRouteBlip ~= nil
end

local function fallbackCurrentJob()
    local current = { name = 'unemployed', label = 'Civilian', grade = 'Freelancer', isPublic = false, protected = false }
    local ok, data = pcall(function()
        return exports['node7-core']:GetPlayerData()
    end)

    if ok and type(data) == 'table' and type(data.job) == 'table' then
        local job = data.job
        current.name = tostring(job.name or current.name):lower()
        current.label = tostring(job.label or current.label)
        if type(job.grade) == 'table' then
            current.grade = tostring(job.grade.name or job.grade.label or job.grade.level or current.grade)
        elseif job.grade ~= nil then
            current.grade = tostring(job.grade)
        end
        current.isPublic = Config.PublicJobs and Config.PublicJobs[current.name] ~= nil or false
        current.protected = Config.ProtectRestrictedJobs == true
            and current.name ~= 'unemployed'
            and not current.isPublic
    end

    return current
end


local function plainCoords(coords)
    if not coords or coords.x == nil or coords.y == nil or coords.z == nil then return nil end
    return { x = coords.x + 0.0, y = coords.y + 0.0, z = coords.z + 0.0 }
end

local function buildLocalBoardJobs()
    local jobs = {}

    for jobName, configJob in pairs(Config.PublicJobs or {}) do
        jobName = tostring(jobName):lower()
        if configJob.enabled ~= false and jobName ~= 'medic' and not jobName:find('law', 1, true) then
            local core = type(configJob.core) == 'table' and configJob.core or {}
            local grades = type(core.grades) == 'table' and core.grades or {}
            local grade = grades['0'] or grades[0] or {}

            jobs[#jobs + 1] = {
                name = jobName,
                order = tonumber(configJob.order) or 999,
                label = tostring(core.label or configJob.label or jobName),
                badge = tostring(configJob.badge or string.upper(string.sub(jobName, 1, 2))),
                category = tostring(configJob.category or 'labor'),
                location = tostring(configJob.location or 'Public Work Site'),
                description = tostring(configJob.description or 'Public employment available to every civilian.'),
                startingGrade = tostring(grade.name or 'Worker'),
                startLabel = tostring(configJob.location or 'Work Site'),
                workCoords = plainCoords(configJob.workCoords),
                available = true,
                activityAvailable = false
            }
        end
    end

    table.sort(jobs, function(a, b)
        if a.order == b.order then return a.label < b.label end
        return a.order < b.order
    end)

    return jobs
end

local function buildLocalCategories(jobs)
    local used = { all = true }
    for _, job in ipairs(jobs or {}) do used[job.category] = true end

    local result = {}
    for _, category in ipairs(Config.Categories or {}) do
        if used[category.id] then result[#result + 1] = category end
    end

    if #result == 0 then result[1] = { id = 'all', label = 'All Work' } end
    return result
end

local function showBoardShell(centerId)
    local center = Config.Centers[centerId]
    if not center then return false end

    local jobs = buildLocalBoardJobs()
    activeCenterId = centerId
    boardJobs = {}
    for _, job in ipairs(jobs) do boardJobs[job.name] = job end
    boardOpen = true
    boardLoading = false

    SendNUIMessage({
        action = 'open',
        payload = {
            centerId = centerId,
            centerLabel = center.label,
            brand = Config.Branding,
            categories = buildLocalCategories(jobs),
            jobs = jobs,
            currentJob = fallbackCurrentJob(),
            loading = false
        }
    })

    SetNuiFocus(true, true)
    if type(SetNuiFocusKeepInput) == 'function' then SetNuiFocusKeepInput(false) end
    return true
end

local function requestBoard(centerId)
    centerId = tostring(centerId or '')
    if not Config.Centers[centerId] then
        notify('This employment office is unavailable.', 'error')
        return
    end

    if not showBoardShell(centerId) then return end
    TriggerServerEvent('node7-jobcenter:server:requestBoard', centerId)
end

local function loadModel(modelName)
    local model = type(modelName) == 'number' and modelName or joaat(modelName)
    if not IsModelValid(model) then
        print(('^1[node7-jobcenter]^7 Invalid RedM NPC model: %s'):format(tostring(modelName)))
        return nil
    end

    RequestModel(model)
    local timeout = GetGameTimer() + (tonumber(Config.ModelLoadTimeoutMs) or 15000)
    while not HasModelLoaded(model) do
        if GetGameTimer() >= timeout then
            print(('^1[node7-jobcenter]^7 Timed out loading RedM NPC model: %s'):format(tostring(modelName)))
            return nil
        end
        Wait(50)
    end
    return model
end

local function createBlip(centerId, center)
    if createdBlips[centerId] or not Config.Blip.enabled or center.blip == false then return end
    local coords = center.coords
    local blip = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, coords.x, coords.y, coords.z)
    if not blip or blip == 0 then return end
    Citizen.InvokeNative(0x74F74D3207ED525C, blip, Config.Blip.sprite, true)
    SetBlipScale(blip, Config.Blip.scale or 0.22)
    Citizen.InvokeNative(0x9CB1A1623062F402, blip, center.label or Config.Blip.label)
    createdBlips[centerId] = blip
end

local function deleteNpcInteraction(centerId)
    local interactionId = registeredInteractions[centerId]
    registeredInteractions[centerId] = nil
    if not interactionId or GetResourceState('node7-interaction') ~= 'started' then return end
    pcall(function() exports['node7-interaction']:DeleteInteraction(interactionId) end)
end

local function registerNpcInteraction(centerId, ped)
    if not ped or not DoesEntityExist(ped) or GetResourceState('node7-interaction') ~= 'started' then return false end
    deleteNpcInteraction(centerId)

    local interactionId = ('node7_jobcenter_%s'):format(centerId)
    local ok, result = pcall(function()
        return exports['node7-interaction']:AddEntityInteraction({
            id = interactionId,
            entity = ped,
            renderDistance = Config.InteractionRenderDistance,
            interactionDistance = Config.InteractionUseDistance,
            offset = vector3(0.0, 0.0, 0.0),
            bone = 'SKEL_Spine2',
            options = {
                {
                    label = 'Read Employment Board',
                    event = 'node7-jobcenter:client:openFromInteraction',
                    args = { centerId = centerId }
                }
            }
        })
    end)

    if ok and result then
        registeredInteractions[centerId] = interactionId
        return true
    end

    debugPrint(('Interaction registration failed for %s: %s'):format(centerId, tostring(result)))
    return false
end

local function configurePed(ped, coords, center)
    SetEntityAsMissionEntity(ped, true, true)
    SetEntityHeading(ped, coords.w + 0.0)
    SetEntityVisible(ped, true)
    SetEntityAlpha(ped, 255, false)
    SetEntityCollision(ped, true, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedCanRagdoll(ped, false)
    if type(SetEntityCanBeDamaged) == 'function' then SetEntityCanBeDamaged(ped, false) end
    if type(SetRandomOutfitVariation) == 'function' then SetRandomOutfitVariation(ped, true) end

    if center.scenario and center.scenario ~= '' then
        TaskStartScenarioInPlace(ped, joaat(center.scenario), -1, true, false, false, false)
    end

    FreezeEntityPosition(ped, true)
end

local function spawnCenter(centerId, center)
    local existing = spawnedPeds[centerId]
    if existing and DoesEntityExist(existing) then return true end

    local now = GetGameTimer()
    if (nextSpawnAttempt[centerId] or 0) > now then return false end
    nextSpawnAttempt[centerId] = now + (tonumber(Config.NpcSpawnRetryMs) or 5000)

    local model = loadModel(center.pedModel)
    if not model then return false end

    local coords = center.coords
    local zOffset = tonumber(Config.NpcZOffset) or 0.0
    local spawnZ = coords.z + zOffset

    -- Use the exact configured center coordinates and offset. Do not ground-snap,
    -- relocate, clamp, or otherwise change the owner's NPC placement.
    RequestCollisionAtCoord(coords.x, coords.y, spawnZ)
    Wait(tonumber(Config.NpcCollisionWaitMs) or 250)

    local ped = CreatePed(model, coords.x, coords.y, spawnZ, coords.w, false, false, 0, 0)

    if not ped or ped == 0 or not DoesEntityExist(ped) then
        print(('^1[node7-jobcenter]^7 Failed to create RedM employment clerk for %s.'):format(centerId))
        SetModelAsNoLongerNeeded(model)
        return false
    end

    configurePed(ped, coords, center)
    spawnedPeds[centerId] = ped
    nextSpawnAttempt[centerId] = nil
    registerNpcInteraction(centerId, ped)
    SetModelAsNoLongerNeeded(model)
    return true
end

local function despawnCenter(centerId)
    deleteNpcInteraction(centerId)
    local ped = spawnedPeds[centerId]
    spawnedPeds[centerId] = nil
    nextSpawnAttempt[centerId] = nil
    if ped and DoesEntityExist(ped) then
        SetEntityAsMissionEntity(ped, true, true)
        DeleteEntity(ped)
    end
end

local function cleanup()
    closeBoard()
    clearWorkRoute()
    for centerId in pairs(Config.Centers) do despawnCenter(centerId) end
    for centerId, blip in pairs(createdBlips) do
        if DoesBlipExist(blip) then RemoveBlip(blip) end
        createdBlips[centerId] = nil
    end
end

RegisterNetEvent('node7-jobcenter:client:openFromInteraction', function(entity, args)
    local centerId = ''
    if type(args) == 'table' then centerId = tostring(args.centerId or '') end
    if centerId == '' and type(entity) == 'table' then centerId = tostring(entity.centerId or '') end
    requestBoard(centerId)
end)

RegisterNetEvent('node7-jobcenter:client:openBoard', function(payload)
    if type(payload) ~= 'table' or not payload.centerId then return end

    boardJobs = {}
    for _, job in ipairs(payload.jobs or {}) do
        if type(job) == 'table' and type(job.name) == 'string' then boardJobs[job.name] = job end
    end

    activeCenterId = tostring(payload.centerId)
    boardOpen = true
    boardLoading = false
    payload.loading = false
    SendNUIMessage({ action = 'open', payload = payload })

    SetNuiFocus(true, true)
    if type(SetNuiFocusKeepInput) == 'function' then SetNuiFocusKeepInput(false) end
end)

RegisterNetEvent('node7-jobcenter:client:boardError', function(centerId, message)
    if not boardOpen or tostring(centerId or '') ~= tostring(activeCenterId or '') then return end
    boardLoading = false
    SendNUIMessage({ action = 'boardError', message = tostring(message or 'Employment records could not be loaded.') })
end)

RegisterNetEvent('node7-jobcenter:client:goToWork', function(job)
    closeBoard()
    if type(job) ~= 'table' then return end

    if job.route ~= false and job.workCoords then
        if setWorkRoute(job) then
            notify(('Route marked for %s.'):format(job.startLabel or job.label or 'your work site'), 'success')
        else
            notify('The RedM work route could not be marked.', 'error')
        end
    end

    if type(job.clientEvent) == 'string' and job.clientEvent ~= '' then
        TriggerEvent(job.clientEvent, job.name, job.args or {})
    end
end)

RegisterNetEvent('node7-jobcenter:client:jobChanged', function()
    closeBoard()
end)

RegisterNUICallback('close', function(_, cb)
    closeBoard()
    cb({ ok = true })
end)

RegisterNUICallback('takeJob', function(data, cb)
    local centerId = activeCenterId
    local jobName = type(data) == 'table' and tostring(data.jobName or '') or ''
    if not centerId or jobName == '' then cb({ ok = false }) return end
    TriggerServerEvent('node7-jobcenter:server:selectJob', centerId, jobName)
    cb({ ok = true })
end)

RegisterNUICallback('goToWork', function(data, cb)
    local centerId = activeCenterId
    local jobName = type(data) == 'table' and tostring(data.jobName or '') or ''
    if not centerId or jobName == '' then cb({ ok = false }) return end
    TriggerServerEvent('node7-jobcenter:server:goToWork', centerId, jobName)
    cb({ ok = true })
end)

RegisterNUICallback('markWork', function(data, cb)
    local jobName = type(data) == 'table' and tostring(data.jobName or '') or ''
    local job = boardJobs[jobName]
    if not job or not job.workCoords then cb({ ok = false }) return end
    local ok = setWorkRoute(job)
    notify(ok and ('Route marked for %s.'):format(job.startLabel or job.label) or 'The work route could not be marked.', ok and 'success' or 'error')
    cb({ ok = ok })
end)

RegisterNUICallback('leaveJob', function(_, cb)
    local centerId = activeCenterId
    if not centerId then cb({ ok = false }) return end
    TriggerServerEvent('node7-jobcenter:server:leaveJob', centerId)
    cb({ ok = true })
end)

RegisterNetEvent('node7-jobcenter:client:open', function(centerId)
    requestBoard(tostring(centerId or 'valentine'))
end)

AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName ~= 'node7-interaction' then return end
    registeredInteractions = {}
    CreateThread(function()
        Wait(250)
        for centerId, ped in pairs(spawnedPeds) do
            if DoesEntityExist(ped) then registerNpcInteraction(centerId, ped) end
        end
    end)
end)

AddEventHandler('onClientResourceStop', function(resourceName)
    if resourceName == 'node7-interaction' then registeredInteractions = {} end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == RESOURCE then cleanup() end
end)

CreateThread(function()
    while not NetworkIsPlayerActive(PlayerId()) do Wait(250) end
    for centerId, center in pairs(Config.Centers) do createBlip(centerId, center) end
end)

CreateThread(function()
    while true do
        if boardOpen and IsPauseMenuActive() then closeBoard() end
        Wait(boardOpen and 100 or 750)
    end
end)

CreateThread(function()
    while not NetworkIsPlayerActive(PlayerId()) do Wait(250) end
    while true do
        local playerCoords = GetEntityCoords(PlayerPedId())
        local spawnDistance = tonumber(Config.NpcSpawnDistance) or 40.0
        local despawnDistance = math.max(tonumber(Config.NpcDespawnDistance) or 75.0, spawnDistance + 10.0)

        for centerId, center in pairs(Config.Centers) do
            local coords = center.coords
            local distance = #(playerCoords - vector3(coords.x, coords.y, coords.z))
            local ped = spawnedPeds[centerId]
            local exists = ped and DoesEntityExist(ped)

            if distance <= (center.spawnDistance or spawnDistance) then
                if not exists then
                    spawnCenter(centerId, center)
                elseif not registeredInteractions[centerId] and GetResourceState('node7-interaction') == 'started' then
                    registerNpcInteraction(centerId, ped)
                end
            elseif exists and distance >= (center.despawnDistance or despawnDistance) then
                despawnCenter(centerId)
            end
        end

        Wait(tonumber(Config.NpcScanIntervalMs) or 1000)
    end
end)

exports('Open', function(centerId) requestBoard(tostring(centerId or 'valentine')) end)
exports('Close', closeBoard)
exports('ClearWorkRoute', clearWorkRoute)
