[README.md](https://github.com/user-attachments/files/30435841/README.md)
# node7-jobcenter

## Public Job Definitions

Add the following jobs inside `Node7Shared.Jobs`, directly before the table’s final closing brace.

```lua
lumberjack = {
    name = 'lumberjack',
    label = 'Lumberjack',
    type = 'public',
    defaultDuty = true,
    offDutyPay = false,
    grades = {
        ['0'] = { name = 'Apprentice', payment = 5 },
        ['1'] = { name = 'Worker', payment = 7 },
        ['2'] = { name = 'Skilled Worker', payment = 9 },
        ['3'] = { name = 'Foreman', payment = 12 },
    },
},

miner = {
    name = 'miner',
    label = 'Miner',
    type = 'public',
    defaultDuty = true,
    offDutyPay = false,
    grades = {
        ['0'] = { name = 'Prospect', payment = 6 },
        ['1'] = { name = 'Miner', payment = 8 },
        ['2'] = { name = 'Experienced Miner', payment = 11 },
        ['3'] = { name = 'Pit Foreman', payment = 14 },
    },
},

farmer = {
    name = 'farmer',
    label = 'Farmer',
    type = 'public',
    defaultDuty = true,
    offDutyPay = false,
    grades = {
        ['0'] = { name = 'Farmhand', payment = 5 },
        ['1'] = { name = 'Field Worker', payment = 7 },
        ['2'] = { name = 'Experienced Farmer', payment = 9 },
        ['3'] = { name = 'Field Foreman', payment = 11 },
    },
},

ranchhand = {
    name = 'ranchhand',
    label = 'Ranch Hand',
    type = 'public',
    defaultDuty = true,
    offDutyPay = false,
    grades = {
        ['0'] = { name = 'New Hand', payment = 5 },
        ['1'] = { name = 'Ranch Hand', payment = 7 },
        ['2'] = { name = 'Senior Hand', payment = 9 },
        ['3'] = { name = 'Ranch Foreman', payment = 12 },
    },
},

fisherman = {
    name = 'fisherman',
    label = 'Fisherman',
    type = 'public',
    defaultDuty = true,
    offDutyPay = false,
    grades = {
        ['0'] = { name = 'Deckhand', payment = 5 },
        ['1'] = { name = 'Fisherman', payment = 6 },
        ['2'] = { name = 'Experienced Fisherman', payment = 8 },
        ['3'] = { name = 'Fishing Foreman', payment = 10 },
    },
},

hunter = {
    name = 'hunter',
    label = 'Hunter',
    type = 'public',
    defaultDuty = true,
    offDutyPay = false,
    grades = {
        ['0'] = { name = 'Tracker', payment = 6 },
        ['1'] = { name = 'Hunter', payment = 8 },
        ['2'] = { name = 'Experienced Hunter', payment = 11 },
        ['3'] = { name = 'Master Hunter', payment = 14 },
    },
},

wagoner = {
    name = 'wagoner',
    label = 'Freight Wagoner',
    type = 'public',
    defaultDuty = true,
    offDutyPay = false,
    grades = {
        ['0'] = { name = 'Loader', payment = 7 },
        ['1'] = { name = 'Wagoner', payment = 9 },
        ['2'] = { name = 'Experienced Wagoner', payment = 12 },
        ['3'] = { name = 'Freight Foreman', payment = 15 },
    },
},

postal = {
    name = 'postal',
    label = 'Postal Courier',
    type = 'public',
    defaultDuty = true,
    offDutyPay = false,
    grades = {
        ['0'] = { name = 'Mail Runner', payment = 5 },
        ['1'] = { name = 'Courier', payment = 7 },
        ['2'] = { name = 'Senior Courier', payment = 9 },
        ['3'] = { name = 'Route Foreman', payment = 11 },
    },
},

stablehand = {
    name = 'stablehand',
    label = 'Stable Hand',
    type = 'public',
    defaultDuty = true,
    offDutyPay = false,
    grades = {
        ['0'] = { name = 'Stable Helper', payment = 4 },
        ['1'] = { name = 'Stable Hand', payment = 6 },
        ['2'] = { name = 'Senior Stable Hand', payment = 7 },
        ['3'] = { name = 'Stable Foreman', payment = 9 },
    },
},

townworker = {
    name = 'townworker',
    label = 'Town Worker',
    type = 'public',
    defaultDuty = true,
    offDutyPay = false,
    grades = {
        ['0'] = { name = 'Laborer', payment = 4 },
        ['1'] = { name = 'Town Worker', payment = 6 },
        ['2'] = { name = 'Senior Worker', payment = 8 },
        ['3'] = { name = 'Maintenance Foreman', payment = 10 },
    },
},
```

> Do not remove or replace the existing `unemployed`, law-enforcement, or medic job definitions.





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
