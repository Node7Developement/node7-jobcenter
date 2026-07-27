Node7JobCenter = Node7JobCenter or {}

function Node7JobCenter.WaitForResource(resourceName, timeoutMs)
    local timeout = tonumber(timeoutMs) or 30000
    local startedAt = GetGameTimer()

    while GetResourceState(resourceName) ~= 'started' do
        if GetGameTimer() - startedAt >= timeout then return false end
        Wait(100)
    end

    return true
end
