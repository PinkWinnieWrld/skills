Config = {}

Config.SkillMax = 100

Config.Gain = {
    stamina = 0.05,   -- running / treadmill
    strength = 0.5,   -- lifting / pullups
    driving = 0.03,   -- driving
    shooting = 0.2    -- shooting
}

Config.TickInterval = 30000 -- ms

Config.Decay = {
    interval = 60 * 60 * 1000, -- every 1 hour
    amount = {
        stamina = 0.2,
        strength = 0.1,
        driving = 0.15,
        shooting = 0.1
    }
}
--Here is where you will config your gym
Config.Gym = {
    price = 500,
    duration = 7 * 24 * 60 * 60 -- 7 days (seconds)
}

Config.GymTargets = {
    {
        label = 'Treadmill',
        type = 'stamina',
        coords = vec3(-1202.9, -1565.2, 4.61),
        heading = 215.0
    },
    {
        label = 'Bench Press',
        type = 'strength',
        coords = vec3(-1200.5, -1570.0, 4.61),
        heading = 215.0
    },
    {
        label = 'Pull Ups',
        type = 'strength',
        coords = vec3(-1205.0, -1568.0, 4.61),
        heading = 215.0
    },
    -- membership purchase spot
    {
        label = 'Gym Reception',
        type = 'membership',
        coords = vec3(-1203.5, -1570.0, 4.61),
        heading = 0.0
    }
}
