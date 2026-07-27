Node7JobCenterIntegrations = Node7JobCenterIntegrations or {}

-- RedM activity resources that are automatically recognized without changing config.lua.
-- A running activity can also register itself through the server export documented in README.md.
Node7JobCenterIntegrations.Candidates = {
    lumberjack = { 'node7-lumberjack', 'node7-logging', 'node7-woodcutting' },
    miner = { 'node7-mining', 'node7-miner' },
    farmer = { 'node7-farming', 'node7-farmer' },
    ranchhand = { 'node7-ranching', 'node7-ranch', 'node7-ranchhand' },
    fisherman = { 'node7-fishing', 'node7-fisherman' },
    hunter = { 'node7-hunting', 'node7-hunter' },
    wagoner = { 'node7-deliveries', 'node7-freight', 'node7-wagoner' },
    postal = { 'node7-postal', 'node7-mail', 'node7-courier' },
    stablehand = { 'node7-stables', 'node7-stablehand' },
    townworker = { 'node7-townwork', 'node7-townworker', 'node7-maintenance' }
}

Node7JobCenterIntegrations.DefaultWorkLabels = {
    lumberjack = 'Logging Camp',
    miner = 'Mine Office',
    farmer = 'Farm Foreman',
    ranchhand = 'Ranch Office',
    fisherman = 'Fishing Dock',
    hunter = 'Hunting Camp',
    wagoner = 'Freight Depot',
    postal = 'Post Office',
    stablehand = 'Stable Yard',
    townworker = 'Town Works Office'
}
