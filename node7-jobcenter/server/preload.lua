Node7JobCenterServer = Node7JobCenterServer or {}

function Node7JobCenterServer.WaitForCore(timeoutMs)
    local timeout = tonumber(timeoutMs) or 30000
    local startedAt = GetGameTimer()

    while GetGameTimer() - startedAt < timeout do
        if GetResourceState('node7-core') == 'started' then
            local ok, jobs = pcall(function()
                return exports['node7-core']:GetShared('Jobs')
            end)

            if ok and type(jobs) == 'table' then
                return true
            end
        end

        Wait(100)
    end

    return false
end
