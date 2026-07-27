Config = Config or {}

Config.Debug = false
Config.ProtectRestrictedJobs = true
Config.RegisterMissingCoreJobs = true
Config.SyncExistingCoreJobs = false -- Existing core job definitions are never overwritten.
Config.RequireServerDistance = true
Config.ServerInteractionDistance = 8.0
Config.ChangeCooldownMs = 3000
Config.NpcSpawnDistance = 40.0
Config.NpcDespawnDistance = 75.0
Config.NpcScanIntervalMs = 1000
Config.NpcSpawnRetryMs = 5000
Config.NpcCollisionWaitMs = 250
Config.NpcZOffset = -1.0
Config.ModelLoadTimeoutMs = 15000
Config.InteractionRenderDistance = 8.0
Config.InteractionUseDistance = 3.0

Config.Branding = {
    title = 'NODE7 EMPLOYMENT BOARD',
    subtitle = 'PUBLIC WORK • HONEST PAY • NO WHITELIST',
    townLabel = 'Public Employment Office'
}

Config.Blip = {
    enabled = true,
    sprite = joaat('blip_shop_store'),
    scale = 0.22,
    label = 'Public Job Center'
}

Config.Categories = {
    { id = 'all', label = 'All Work' },
    { id = 'labor', label = 'Labor' },
    { id = 'gathering', label = 'Gathering' },
    { id = 'transport', label = 'Transport' },
    { id = 'ranching', label = 'Ranching' },
    { id = 'services', label = 'Town Services' }
}

-- These are the only jobs shown by node7-jobcenter. Restricted core jobs such as
-- law enforcement and medic are intentionally never read into this menu.
Config.PublicJobs = {
    lumberjack = {
        order = 10,
        label = 'Lumberjack',
        badge = 'LW',
        category = 'labor',
        location = 'Cumberland Forest',
        difficulty = 'Moderate',
        payRange = '5–12 cash',
        description = 'Cut, sort and haul timber for mills and construction crews.',
        duties = { 'Cut marked trees', 'Process usable logs', 'Deliver timber loads' },
        requirements = { 'No whitelist', 'Work tools supplied by job activity', 'Available to every civilian' },
        workCoords = vector3(-1421.76, -233.43, 99.82),
        core = {
            name = 'lumberjack',
            label = 'Lumberjack',
            type = 'public',
            defaultDuty = true,
            offDutyPay = false,
            grades = {
                ['0'] = { name = 'Apprentice', payment = 5 },
                ['1'] = { name = 'Worker', payment = 7 },
                ['2'] = { name = 'Skilled Worker', payment = 9 },
                ['3'] = { name = 'Foreman', payment = 12 }
            }
        }
    },
    miner = {
        order = 20,
        label = 'Miner',
        badge = 'MN',
        category = 'gathering',
        location = 'Annesburg',
        difficulty = 'Hard',
        payRange = '6–14 cash',
        description = 'Extract ore and stone from working mine sites and quarry deposits.',
        duties = { 'Mine approved deposits', 'Sort raw materials', 'Deliver ore to processing' },
        requirements = { 'No whitelist', 'Physical labor', 'Inventory space recommended' },
        workCoords = vector3(2929.20, 1374.10, 45.20),
        core = {
            name = 'miner',
            label = 'Miner',
            type = 'public',
            defaultDuty = true,
            offDutyPay = false,
            grades = {
                ['0'] = { name = 'Prospect', payment = 6 },
                ['1'] = { name = 'Miner', payment = 8 },
                ['2'] = { name = 'Experienced Miner', payment = 11 },
                ['3'] = { name = 'Pit Foreman', payment = 14 }
            }
        }
    },
    farmer = {
        order = 30,
        label = 'Farmer',
        badge = 'FM',
        category = 'ranching',
        location = 'Heartlands',
        difficulty = 'Easy',
        payRange = '5–11 cash',
        description = 'Plant, maintain and harvest crops for local farms and merchants.',
        duties = { 'Prepare crop rows', 'Harvest produce', 'Deliver farm goods' },
        requirements = { 'No whitelist', 'Suitable for new players', 'Seasonal routes supported' },
        workCoords = vector3(-236.03, 626.79, 113.14),
        core = {
            name = 'farmer',
            label = 'Farmer',
            type = 'public',
            defaultDuty = true,
            offDutyPay = false,
            grades = {
                ['0'] = { name = 'Farmhand', payment = 5 },
                ['1'] = { name = 'Field Worker', payment = 7 },
                ['2'] = { name = 'Experienced Farmer', payment = 9 },
                ['3'] = { name = 'Field Foreman', payment = 11 }
            }
        }
    },
    ranchhand = {
        order = 40,
        label = 'Ranch Hand',
        badge = 'RH',
        category = 'ranching',
        location = 'Emerald Ranch',
        difficulty = 'Moderate',
        payRange = '5–12 cash',
        description = 'Maintain ranch grounds, handle livestock and move ranch supplies.',
        duties = { 'Feed and tend livestock', 'Repair ranch property', 'Move ranch supplies' },
        requirements = { 'No whitelist', 'Comfort around animals', 'Reliable attendance' },
        workCoords = vector3(1417.72, 268.42, 89.62),
        core = {
            name = 'ranchhand',
            label = 'Ranch Hand',
            type = 'public',
            defaultDuty = true,
            offDutyPay = false,
            grades = {
                ['0'] = { name = 'New Hand', payment = 5 },
                ['1'] = { name = 'Ranch Hand', payment = 7 },
                ['2'] = { name = 'Senior Hand', payment = 9 },
                ['3'] = { name = 'Ranch Foreman', payment = 12 }
            }
        }
    },
    fisherman = {
        order = 50,
        label = 'Fisherman',
        badge = 'FS',
        category = 'gathering',
        location = 'Flat Iron Lake',
        difficulty = 'Easy',
        payRange = '5–10 cash',
        description = 'Catch and deliver fresh fish to markets, camps and town merchants.',
        duties = { 'Fish approved waters', 'Sort acceptable catches', 'Deliver fresh fish' },
        requirements = { 'No whitelist', 'Fishing rod required by activity', 'Open to civilians' },
        workCoords = vector3(-724.36, -1250.67, 44.73),
        core = {
            name = 'fisherman',
            label = 'Fisherman',
            type = 'public',
            defaultDuty = true,
            offDutyPay = false,
            grades = {
                ['0'] = { name = 'Deckhand', payment = 5 },
                ['1'] = { name = 'Fisherman', payment = 6 },
                ['2'] = { name = 'Experienced Fisherman', payment = 8 },
                ['3'] = { name = 'Fishing Foreman', payment = 10 }
            }
        }
    },
    hunter = {
        order = 60,
        label = 'Hunter',
        badge = 'HT',
        category = 'gathering',
        location = 'Open Wilderness',
        difficulty = 'Hard',
        payRange = '6–14 cash',
        description = 'Hunt approved wildlife and supply clean materials to local traders.',
        duties = { 'Track approved game', 'Recover usable materials', 'Deliver hunting goods' },
        requirements = { 'No whitelist', 'Weapon and ammunition required', 'Responsible hunting expected' },
        workCoords = vector3(-1324.85, 396.31, 95.60),
        core = {
            name = 'hunter',
            label = 'Hunter',
            type = 'public',
            defaultDuty = true,
            offDutyPay = false,
            grades = {
                ['0'] = { name = 'Tracker', payment = 6 },
                ['1'] = { name = 'Hunter', payment = 8 },
                ['2'] = { name = 'Experienced Hunter', payment = 11 },
                ['3'] = { name = 'Master Hunter', payment = 14 }
            }
        }
    },
    wagoner = {
        order = 70,
        label = 'Freight Wagoner',
        badge = 'FW',
        category = 'transport',
        location = 'Valentine Freight Depot',
        difficulty = 'Moderate',
        payRange = '7–15 cash',
        description = 'Haul commercial freight between towns, depots and rural businesses.',
        duties = { 'Collect assigned freight', 'Protect the shipment', 'Deliver without major damage' },
        requirements = { 'No whitelist', 'Careful wagon handling', 'Long-distance routes' },
        workCoords = vector3(-170.40, 629.64, 113.03),
        core = {
            name = 'wagoner',
            label = 'Freight Wagoner',
            type = 'public',
            defaultDuty = true,
            offDutyPay = false,
            grades = {
                ['0'] = { name = 'Loader', payment = 7 },
                ['1'] = { name = 'Wagoner', payment = 9 },
                ['2'] = { name = 'Experienced Wagoner', payment = 12 },
                ['3'] = { name = 'Freight Foreman', payment = 15 }
            }
        }
    },
    postal = {
        order = 80,
        label = 'Postal Courier',
        badge = 'PC',
        category = 'transport',
        location = 'Regional Post Offices',
        difficulty = 'Easy',
        payRange = '5–11 cash',
        description = 'Carry letters and small parcels between residents and post offices.',
        duties = { 'Collect the mail route', 'Deliver marked parcels', 'Return undelivered mail' },
        requirements = { 'No whitelist', 'Reliable horse recommended', 'Timed routes possible' },
        workCoords = vector3(-178.72, 627.75, 114.10),
        core = {
            name = 'postal',
            label = 'Postal Courier',
            type = 'public',
            defaultDuty = true,
            offDutyPay = false,
            grades = {
                ['0'] = { name = 'Mail Runner', payment = 5 },
                ['1'] = { name = 'Courier', payment = 7 },
                ['2'] = { name = 'Senior Courier', payment = 9 },
                ['3'] = { name = 'Route Foreman', payment = 11 }
            }
        }
    },
    stablehand = {
        order = 90,
        label = 'Stable Hand',
        badge = 'SH',
        category = 'services',
        location = 'Valentine Stable',
        difficulty = 'Easy',
        payRange = '4–9 cash',
        description = 'Clean stalls, feed horses and maintain stable supplies for travelers.',
        duties = { 'Clean assigned stalls', 'Feed and water horses', 'Restock stable supplies' },
        requirements = { 'No whitelist', 'Suitable for new players', 'Animal care work' },
        workCoords = vector3(-367.91, 787.72, 116.17),
        core = {
            name = 'stablehand',
            label = 'Stable Hand',
            type = 'public',
            defaultDuty = true,
            offDutyPay = false,
            grades = {
                ['0'] = { name = 'Stable Helper', payment = 4 },
                ['1'] = { name = 'Stable Hand', payment = 6 },
                ['2'] = { name = 'Senior Stable Hand', payment = 7 },
                ['3'] = { name = 'Stable Foreman', payment = 9 }
            }
        }
    },
    townworker = {
        order = 100,
        label = 'Town Worker',
        badge = 'TW',
        category = 'services',
        location = 'Town Maintenance Office',
        difficulty = 'Easy',
        payRange = '4–10 cash',
        description = 'Complete cleaning, hauling and maintenance assignments around town.',
        duties = { 'Clean marked areas', 'Move town supplies', 'Complete maintenance calls' },
        requirements = { 'No whitelist', 'Open to every civilian', 'Local assignments' },
        workCoords = vector3(-269.37, 767.08, 118.12),
        core = {
            name = 'townworker',
            label = 'Town Worker',
            type = 'public',
            defaultDuty = true,
            offDutyPay = false,
            grades = {
                ['0'] = { name = 'Laborer', payment = 4 },
                ['1'] = { name = 'Town Worker', payment = 6 },
                ['2'] = { name = 'Senior Worker', payment = 8 },
                ['3'] = { name = 'Maintenance Foreman', payment = 10 }
            }
        }
    }
}

Config.Centers = {
    valentine = {
        label = 'Valentine Employment Board',
        coords = vector4(-360.9735, 791.2225, 115.2034, 275.2774),
        pedModel = 'u_m_m_bwmstablehand_01',
        scenario = 'WORLD_HUMAN_STAND_WAITING',
        blip = true
    },
    rhodes = {
        label = 'Rhodes Employment Board',
        coords = vector4(1173.5817, -188.1004, 100.8338, 282.6306),
        pedModel = 'u_m_m_bwmstablehand_01',
        scenario = 'WORLD_HUMAN_STAND_WAITING',
        blip = true
    },
    blackwater = {
        label = 'Blackwater Employment Board',
        coords = vector4(-908.6452, -1344.7482, 45.5606, 179.5796),
        pedModel = 'u_m_m_bwmstablehand_01',
        scenario = 'WORLD_HUMAN_STAND_WAITING',
        blip = true
    },
    strawberry = {
        label = 'Strawberry Employment Board',
        coords = vector4(-1832.5391, -594.5669, 154.5630, 294.6011),
        pedModel = 'u_m_m_bwmstablehand_01',
        scenario = 'WORLD_HUMAN_STAND_WAITING',
        blip = true
    },
    saintdenis = {
        label = 'Saint Denis Employment Board',
        coords = vector4(2444.2629, -1504.1483, 45.9690, 9.0402),
        pedModel = 'u_m_m_bwmstablehand_01',
        scenario = 'WORLD_HUMAN_STAND_WAITING',
        blip = true
    }
}
