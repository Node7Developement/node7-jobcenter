local lastChange = {}
local boardSessions = {}
local registeredIntegrations = {}

local RESTRICTED_TYPES = {
    leo = true,
    law = true,
    police = true,
    sheriff = true,
    medic = true,
    ems = true,
    ambulance = true,
    government = true,
    admin = true
}

local function debugPrint(message)
    if Config.Debug then
        print(('^5[node7-jobcenter]^7 %s'):format(tostring(message)))
    end
end

local function copyTable(value)
    if type(value) ~= 'table' then return value end
    local output = {}
    for key, item in pairs(value) do
        output[key] = copyTable(item)
    end
    return output
end

local function plainCoords(coords)
    if not coords or coords.x == nil or coords.y == nil or coords.z == nil then return nil end
    return {
        x = coords.x + 0.0,
        y = coords.y + 0.0,
        z = coords.z + 0.0
    }
end

local function notify(source, description, notificationType)
    local ok = pcall(function()
        exports['node7-core']:Notify(source, {
            title = 'NODE7 JOB CENTER',
            description = tostring(description or ''),
            type = notificationType or 'info',
            duration = 5000
        })
    end)

    if not ok then
        print(('^3[node7-jobcenter]^7 %s'):format(tostring(description)))
    end
end

local function getCoreJobs()
    if GetResourceState('node7-core') ~= 'started' then return nil end

    local ok, jobs = pcall(function()
        return exports['node7-core']:GetShared('Jobs')
    end)

    if ok and type(jobs) == 'table' then return jobs end
    return nil
end

local function getPlayer(source)
    source = tonumber(source)
    if not source or GetResourceState('node7-core') ~= 'started' then return nil end

    local ok, player = pcall(function()
        return exports['node7-core']:GetPlayer(source)
    end)

    if ok and type(player) == 'table' and type(player.PlayerData) == 'table' then
        return player
    end

    return nil
end


local function getGradeName(job)
    if type(job) ~= 'table' then return 'Freelancer' end
    local grade = job.grade
    if type(grade) == 'table' then return tostring(grade.name or grade.label or grade.level or 'Worker') end
    if grade ~= nil then return tostring(grade) end
    return 'Worker'
end

local function setPlayerJob(source, jobName, grade)
    local callOk, success, result = pcall(function()
        return exports['node7-core']:SetJob(source, jobName, grade or 0)
    end)

    if not callOk then return false, tostring(success) end
    return success == true, result
end

local function isRestrictedJob(jobName, jobDefinition)
    jobName = tostring(jobName or ''):lower()
    local jobType = tostring(jobDefinition and jobDefinition.type or ''):lower()

    if RESTRICTED_TYPES[jobType] then return true end
    if jobName == 'medic' then return true end
    if jobName:find('law', 1, true) then return true end
    return false
end

local function configuredDefinition(jobName)
    local configJob = Config.PublicJobs and Config.PublicJobs[jobName]
    if not configJob or type(configJob.core) ~= 'table' then return nil end

    local definition = copyTable(configJob.core)
    definition.name = tostring(definition.name or jobName):lower()
    definition.type = tostring(definition.type or 'public'):lower()
    definition.defaultDuty = definition.defaultDuty ~= false
    definition.offDutyPay = definition.offDutyPay == true
    definition.grades = type(definition.grades) == 'table' and definition.grades or {
        ['0'] = { name = 'Worker', payment = 0 }
    }

    if definition.name ~= jobName or definition.type ~= 'public' then return nil end
    if isRestrictedJob(jobName, definition) then return nil end
    return definition
end

local function registerMissingCoreJobs()
    if Config.RegisterMissingCoreJobs == false then return 0, {} end

    local coreJobs = getCoreJobs()
    if not coreJobs then return 0, { 'node7-core unavailable' } end

    local added = 0
    local failed = {}

    for jobName in pairs(Config.PublicJobs or {}) do
        jobName = tostring(jobName):lower()
        if not coreJobs[jobName] then
            local definition = configuredDefinition(jobName)
            if definition then
                local callOk, success, reason = pcall(function()
                    return exports['node7-core']:AddJob(jobName, definition)
                end)

                if callOk and success == true then
                    coreJobs[jobName] = definition
                    added = added + 1
                    debugPrint(('Registered missing core job: %s'):format(jobName))
                elseif reason ~= 'job_exists' then
                    failed[#failed + 1] = ('%s (%s)'):format(jobName, tostring(reason or success))
                end
            else
                failed[#failed + 1] = ('%s (invalid configured definition)'):format(jobName)
            end
        end
    end

    return added, failed
end

local function getCoreJob(jobName)
    local jobs = getCoreJobs()
    return jobs and jobs[jobName] or nil
end


local function ensureCoreJob(jobName)
    jobName = tostring(jobName or ''):lower()
    local configJob = Config.PublicJobs and Config.PublicJobs[jobName]
    if not configJob or configJob.enabled == false then return nil, 'job_not_configured' end
    if jobName == 'medic' or jobName:find('law', 1, true) then return nil, 'restricted_job' end

    local existing = getCoreJob(jobName)
    if existing then
        if isRestrictedJob(jobName, existing) then return nil, 'restricted_job' end
        return existing, 'exists'
    end

    local definition = configuredDefinition(jobName)
    if not definition then return nil, 'invalid_definition' end

    local callOk, success, reason = pcall(function()
        return exports['node7-core']:AddJob(jobName, definition)
    end)

    if not callOk then return nil, tostring(success) end
    if success ~= true and reason ~= 'job_exists' then return nil, tostring(reason or 'add_failed') end

    return getCoreJob(jobName) or definition, reason or 'success'
end

local function isPublicJob(jobName)
    jobName = tostring(jobName or ''):lower()
    local configJob = Config.PublicJobs and Config.PublicJobs[jobName]
    if not configJob or configJob.enabled == false then return false end
    if jobName == 'medic' or jobName:find('law', 1, true) then return false end

    local coreJob = getCoreJob(jobName)
    if coreJob and isRestrictedJob(jobName, coreJob) then return false end
    return true
end

local function resourceStarted(resourceName)
    return type(resourceName) == 'string'
        and resourceName ~= ''
        and GetResourceState(resourceName) == 'started'
end

local function callIntegrationExport(resourceName, jobName)
    local ok, result = pcall(function()
        return exports[resourceName]:GetJobCenterData(jobName)
    end)
    if ok and type(result) == 'table' then return result end
    return nil
end

local function normalizeIntegration(jobName, job, raw, ownerResource)
    raw = type(raw) == 'table' and copyTable(raw) or {}
    local resourceName = raw.resource or ownerResource

    if resourceName and not resourceStarted(resourceName) then return nil end
    if raw.enabled == false then return nil end

    return {
        resource = resourceName,
        startLabel = raw.startLabel
            or raw.workLabel
            or Node7JobCenterIntegrations.DefaultWorkLabels[jobName]
            or job.location
            or 'Work Site',
        clientEvent = type(raw.clientEvent) == 'string' and raw.clientEvent or nil,
        serverEvent = type(raw.serverEvent) == 'string' and raw.serverEvent or nil,
        args = type(raw.args) == 'table' and raw.args or {},
        route = raw.route ~= false
    }
end

local function findIntegration(jobName, job)
    local registered = registeredIntegrations[jobName]
    if registered then
        local normalized = normalizeIntegration(jobName, job, registered.data, registered.owner)
        if normalized then return normalized end
    end

    local candidates = {}
    if type(job.resource) == 'string' then candidates[#candidates + 1] = job.resource end
    if type(job.resources) == 'table' then
        for _, name in ipairs(job.resources) do candidates[#candidates + 1] = name end
    end
    for _, name in ipairs(Node7JobCenterIntegrations.Candidates[jobName] or {}) do
        candidates[#candidates + 1] = name
    end

    local checked = {}
    for _, resourceName in ipairs(candidates) do
        if not checked[resourceName] then
            checked[resourceName] = true
            if resourceStarted(resourceName) then
                local data = callIntegrationExport(resourceName, jobName) or {}
                data.resource = resourceName
                local normalized = normalizeIntegration(jobName, job, data, resourceName)
                if normalized then return normalized end
            end
        end
    end

    return nil
end

local function buildBoardJobs()
    local jobs = {}
    local coreJobs = getCoreJobs() or {}

    for jobName, configJob in pairs(Config.PublicJobs or {}) do
        jobName = tostring(jobName):lower()
        if configJob.enabled ~= false and jobName ~= 'medic' and not jobName:find('law', 1, true) then
            local coreJob = coreJobs[jobName]
            if coreJob and isRestrictedJob(jobName, coreJob) then coreJob = nil end

            local displayJob = coreJob or configuredDefinition(jobName) or {}
            local grade = displayJob.grades and (displayJob.grades['0'] or displayJob.grades[0]) or {}
            local integration = findIntegration(jobName, configJob)
            local startLabel = integration and integration.startLabel
                or Node7JobCenterIntegrations.DefaultWorkLabels[jobName]
                or configJob.location
                or 'Work Site'

            jobs[#jobs + 1] = {
                name = jobName,
                order = tonumber(configJob.order) or 999,
                label = displayJob.label or configJob.label or jobName,
                badge = configJob.badge or string.upper(string.sub(jobName, 1, 2)),
                category = configJob.category or 'labor',
                location = configJob.location or startLabel,
                description = configJob.description or 'Public employment available to every civilian.',
                startingGrade = grade.name or 'Worker',
                startLabel = startLabel,
                workCoords = plainCoords(configJob.workCoords),
                available = configuredDefinition(jobName) ~= nil,
                coreAvailable = coreJob ~= nil,
                activityAvailable = integration ~= nil
            }
        end
    end

    table.sort(jobs, function(a, b)
        if a.order == b.order then return a.label < b.label end
        return a.order < b.order
    end)

    return jobs
end

local function buildCategories(jobs)
    local used = { all = true }
    for _, job in ipairs(jobs) do used[job.category] = true end

    local categories = {}
    for _, category in ipairs(Config.Categories or {}) do
        if used[category.id] then categories[#categories + 1] = category end
    end

    if #categories == 0 then
        categories[1] = { id = 'all', label = 'All Work' }
    end

    return categories
end

local function hasBoardSession(source, centerId)
    local session = boardSessions[source]
    return session and session.centerId == centerId and session.expiresAt > GetGameTimer()
end

local function isNearCenter(source, centerId)
    local center = Config.Centers and Config.Centers[centerId]
    if not center then return false end
    if not Config.RequireServerDistance then return true end

    local ped = GetPlayerPed(source)
    if ped and ped > 0 then
        local playerCoords = GetEntityCoords(ped)
        if playerCoords then
            local coords = center.coords
            local dx = playerCoords.x - coords.x
            local dy = playerCoords.y - coords.y
            local dz = playerCoords.z - coords.z
            local distance = math.sqrt(dx * dx + dy * dy + dz * dz)
            if distance <= (tonumber(Config.ServerInteractionDistance) or 8.0) then
                return true
            end
        end
    end

    return hasBoardSession(source, centerId)
end

local function cooldownReady(source)
    return GetGameTimer() - (lastChange[source] or 0) >= (tonumber(Config.ChangeCooldownMs) or 3000)
end

local function markCooldown(source)
    lastChange[source] = GetGameTimer()
end

local function canReplaceCurrentJob(player)
    local current = tostring(player and player.PlayerData and player.PlayerData.job and player.PlayerData.job.name or 'unemployed'):lower()
    if not Config.ProtectRestrictedJobs then return true, current end
    if current == 'unemployed' or isPublicJob(current) then return true, current end
    return false, current
end

RegisterNetEvent('node7-jobcenter:server:requestBoard', function(centerId)
    local source = source
    centerId = tostring(centerId or '')

    local ok, errorMessage = xpcall(function()
        if not Config.Centers[centerId] then
            TriggerClientEvent('node7-jobcenter:client:boardError', source, centerId, 'This employment office is unavailable.')
            return
        end

        -- Register missing public jobs when possible, but never block the board from loading.
        if GetResourceState('node7-core') == 'started' then
            registerMissingCoreJobs()
        end

        boardSessions[source] = {
            centerId = centerId,
            expiresAt = GetGameTimer() + 30000
        }

        local player = getPlayer(source)
        local current = player and player.PlayerData and player.PlayerData.job or {}
        local currentName = tostring(current.name or 'unemployed'):lower()
        local jobs = buildBoardJobs()

        TriggerClientEvent('node7-jobcenter:client:openBoard', source, {
            centerId = centerId,
            centerLabel = Config.Centers[centerId].label,
            brand = Config.Branding,
            categories = buildCategories(jobs),
            jobs = jobs,
            currentJob = {
                name = currentName,
                label = current.label or 'Civilian',
                grade = getGradeName(current),
                isPublic = isPublicJob(currentName),
                protected = Config.ProtectRestrictedJobs == true
                    and currentName ~= 'unemployed'
                    and not isPublicJob(currentName)
            }
        })
    end, function(err)
        if debug and type(debug.traceback) == 'function' then return debug.traceback(err, 2) end
        return tostring(err)
    end)

    if not ok then
        print(('^1[node7-jobcenter]^7 Failed to build employment board for source %s: %s'):format(source, tostring(errorMessage)))
        TriggerClientEvent('node7-jobcenter:client:boardError', source, centerId, 'The employment records failed to load. Check the server console.')
    end
end)

RegisterNetEvent('node7-jobcenter:server:selectJob', function(centerId, jobName)
    local source = source
    centerId = tostring(centerId or '')
    jobName = tostring(jobName or ''):lower()

    if not isNearCenter(source, centerId) then
        notify(source, 'You must use an employment board to take a public job.', 'error')
        return
    end

    local configJob = Config.PublicJobs and Config.PublicJobs[jobName]
    if not configJob or not isPublicJob(jobName) then
        notify(source, 'That public job is unavailable.', 'error')
        return
    end

    local coreJob, ensureReason = ensureCoreJob(jobName)
    if not coreJob then
        notify(source, ('NODE7 Core could not register %s: %s'):format(jobName, tostring(ensureReason or 'unknown error')), 'error')
        return
    end

    if not cooldownReady(source) then
        notify(source, 'Wait a moment before changing employment again.', 'error')
        return
    end

    local player = getPlayer(source)
    if not player then
        notify(source, 'Your NODE7 character data is not ready.', 'error')
        return
    end

    local allowed, currentJob = canReplaceCurrentJob(player)
    if not allowed then
        notify(source, 'Law, medic, and other restricted jobs cannot be changed at the public job center.', 'error')
        return
    end

    if currentJob == jobName then
        notify(source, 'You already hold that public job. Choose Go to Work.', 'info')
        return
    end

    local success, result = setPlayerJob(source, jobName, 0)
    if not success then
        notify(source, ('NODE7 Core rejected that employment change: %s'):format(tostring(result or 'unknown error')), 'error')
        return
    end

    markCooldown(source)
    notify(source, ('You are now employed as %s.'):format(coreJob.label or configJob.label or jobName), 'success')
    TriggerClientEvent('node7-jobcenter:client:jobChanged', source, jobName)
    TriggerEvent('node7-jobcenter:server:jobChanged', source, currentJob, jobName)
end)

RegisterNetEvent('node7-jobcenter:server:goToWork', function(centerId, jobName)
    local source = source
    centerId = tostring(centerId or '')
    jobName = tostring(jobName or ''):lower()

    if not isNearCenter(source, centerId) then
        notify(source, 'You must use an employment board to locate work.', 'error')
        return
    end

    local configJob = Config.PublicJobs and Config.PublicJobs[jobName]
    local coreJob = getCoreJob(jobName)
    if not configJob or not isPublicJob(jobName) then
        notify(source, 'That public job is unavailable.', 'error')
        return
    end
    coreJob = coreJob or configuredDefinition(jobName) or { label = configJob.label or jobName }

    local player = getPlayer(source)
    local currentJob = tostring(player and player.PlayerData and player.PlayerData.job and player.PlayerData.job.name or ''):lower()
    if currentJob ~= jobName then
        notify(source, 'Take this job before travelling to its work site.', 'error')
        return
    end

    local integration = findIntegration(jobName, configJob)
    if integration and integration.serverEvent then
        TriggerEvent(integration.serverEvent, source, jobName, copyTable(integration.args))
    end

    TriggerClientEvent('node7-jobcenter:client:goToWork', source, {
        name = jobName,
        label = coreJob.label or configJob.label or jobName,
        startLabel = integration and integration.startLabel
            or Node7JobCenterIntegrations.DefaultWorkLabels[jobName]
            or configJob.location
            or 'Work Site',
        workCoords = plainCoords(configJob.workCoords),
        clientEvent = integration and integration.clientEvent or nil,
        args = integration and integration.args or {},
        route = not integration or integration.route ~= false
    })
end)

RegisterNetEvent('node7-jobcenter:server:leaveJob', function(centerId)
    local source = source
    centerId = tostring(centerId or '')

    if not isNearCenter(source, centerId) then
        notify(source, 'You must use an employment board to leave a public job.', 'error')
        return
    end

    if not cooldownReady(source) then
        notify(source, 'Wait a moment before changing employment again.', 'error')
        return
    end

    local player = getPlayer(source)
    if not player then
        notify(source, 'Your NODE7 character data is not ready.', 'error')
        return
    end

    local current = tostring(player.PlayerData.job and player.PlayerData.job.name or 'unemployed'):lower()
    if not isPublicJob(current) then
        notify(source, 'Only public job-center employment can be left here.', 'error')
        return
    end

    local success, result = setPlayerJob(source, 'unemployed', 0)
    if not success then
        notify(source, ('NODE7 Core could not return you to civilian employment: %s'):format(tostring(result or 'unknown error')), 'error')
        return
    end

    markCooldown(source)
    notify(source, 'You left your public job and are now a civilian.', 'success')
    TriggerClientEvent('node7-jobcenter:client:jobChanged', source, 'unemployed')
    TriggerEvent('node7-jobcenter:server:jobChanged', source, current, 'unemployed')
end)

exports('RegisterPublicJob', function(jobName, data)
    local owner = GetInvokingResource()
    jobName = type(jobName) == 'string' and jobName:lower() or ''

    if not owner or owner == '' or jobName == '' or type(data) ~= 'table' then return false end
    if not Config.PublicJobs[jobName] then return false end

    registeredIntegrations[jobName] = {
        owner = owner,
        data = copyTable(data)
    }
    debugPrint(('Registered optional %s activity hook from %s.'):format(jobName, owner))
    return true
end)

exports('UnregisterPublicJob', function(jobName)
    local owner = GetInvokingResource()
    jobName = type(jobName) == 'string' and jobName:lower() or ''
    local registered = registeredIntegrations[jobName]

    if not registered or registered.owner ~= owner then return false end
    registeredIntegrations[jobName] = nil
    return true
end)

exports('GetAvailableJobs', buildBoardJobs)
exports('IsPublicJob', function(jobName)
    return isPublicJob(tostring(jobName or ''):lower())
end)
exports('RegisterMissingCoreJobs', registerMissingCoreJobs)

AddEventHandler('onResourceStop', function(resourceName)
    for jobName, registered in pairs(registeredIntegrations) do
        if registered.owner == resourceName then
            registeredIntegrations[jobName] = nil
        end
    end
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= 'node7-core' then return end

    CreateThread(function()
        Wait(500)
        local added, failed = registerMissingCoreJobs()
        print(('^2[node7-jobcenter]^7 NODE7 Core restarted | %d missing public jobs registered'):format(added))
        if #failed > 0 then
            print(('^3[node7-jobcenter]^7 Registration warnings: %s'):format(table.concat(failed, ', ')))
        end
    end)
end)

AddEventHandler('playerDropped', function()
    lastChange[source] = nil
    boardSessions[source] = nil
end)

CreateThread(function()
    if not Node7JobCenterServer.WaitForCore(30000) then
        print('^1[node7-jobcenter]^7 node7-core did not become ready within 30 seconds. The resource will retry when node7-core starts.')
        return
    end

    local added, failed = registerMissingCoreJobs()
    local jobs = buildBoardJobs()
    local available = 0
    for _, job in ipairs(jobs) do
        if job.available then available = available + 1 end
    end

    print(('^2[node7-jobcenter]^7 Ready | %d public jobs available | %d registered at runtime | law and medic excluded'):format(available, added))
    if #failed > 0 then
        print(('^3[node7-jobcenter]^7 Registration warnings: %s'):format(table.concat(failed, ', ')))
    end
end)
