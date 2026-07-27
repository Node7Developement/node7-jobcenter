# node7-jobcenter

RedM-only public employment board for NODE7 Framework.

## Correct core integration

This resource does **not** replace or edit `node7-core`.

It uses the core's direct exports:

```lua
exports['node7-core']:GetShared('Jobs')
exports['node7-core']:AddJob(jobName, definition)
exports['node7-core']:GetPlayer(source)
exports['node7-core']:SetJob(source, jobName, 0)
exports['node7-core']:Notify(source, payload)
```

Missing public jobs are registered at runtime through `AddJob`. Existing jobs are never overwritten.


## Board loading behavior

The ten configured public jobs are built locally from `Config.PublicJobs` when the board opens, so the UI never waits on a server round trip before showing notices. The server response then refreshes current employment and core status. Job changes remain server-authoritative.

## Public jobs

- Lumberjack
- Miner
- Farmer
- Ranch Hand
- Fisherman
- Hunter
- Freight Wagoner
- Postal Courier
- Stable Hand
- Town Worker

Law-enforcement and medic jobs are never shown or assignable through this resource.

## Included core job files

The `install` folder contains:

- `install/jobs.lua` — complete replacement built from the `jobs.lua` supplied for this build, with all ten public jobs appended.
- `install/public_jobs.lua` — public-job definitions only.
- `install/README.txt` — installation directions.

The runtime registration means the board works without replacing the core file. Use `install/jobs.lua` when you want the public jobs permanently stored in `node7-core/shared/jobs.lua`.

## Installation

```cfg
ensure node7-core
ensure node7-interaction
ensure node7-jobcenter
```

No ACE permission or SQL import is required.

## Job assignment

Players receive grade `0` through the core's direct `SetJob` export. The server validates the center, job, cooldown, current restricted job, and player data before assigning anything.

## Optional job-activity hook

Activity scripts may attach their own start event without controlling visibility:

```lua
exports['node7-jobcenter']:RegisterPublicJob('lumberjack', {
    startLabel = 'Logging Camp',
    clientEvent = 'node7-lumberjack:client:openForeman',
    serverEvent = 'node7-lumberjack:server:prepareWorker',
    args = { office = 'cumberland' },
    route = true
})
```

The NPC coordinates and work coordinates remain controlled by `config.lua`.
