local QBCore = exports['qb-core']:GetCoreObject()

local skills = {
    stamina = 0.0,
    strength = 0.0,
    driving = 0.0,
    shooting = 0.0
}

local staminaDrain = 1.0
local handlingBoost = 1.0
local recoilReduction = 1.0
local spreadReduction = 1.0
local strengthMultiplier = 1.0

-- notifications

RegisterNetEvent('qb-skills:client:notify', function(data)
    lib.notify(data)
end)

RegisterNetEvent('qb-skills:client:skillNotification', function(skill, amount)
    lib.notify({
        title = 'Skill Increased',
        description = ('%s +%.2f'):format(skill:gsub("^%l", string.upper), amount),
        type = 'success',
        position = 'top'
    })
end)

-- load skills

CreateThread(function()
    TriggerServerEvent('qb-skills:server:initSkills')
    Wait(1000)
    QBCore.Functions.TriggerCallback('qb-skills:server:getSkills', function(data)
        if data then
            skills = data
            updateDerivedValues()
        end
    end)
end)

RegisterNetEvent('qb-skills:client:updateSkills', function(data)
    skills = data
    updateDerivedValues()
end)

function updateDerivedValues()
    staminaDrain = 1.0 - (skills.stamina / Config.SkillMax) * 0.4
    handlingBoost = 1.0 + (skills.driving / Config.SkillMax) * 0.2
    recoilReduction = 1.0 - (skills.shooting / Config.SkillMax) * 0.3
    spreadReduction = 1.0 - (skills.shooting / Config.SkillMax) * 0.25
    strengthMultiplier = 1.0 + (skills.strength / Config.SkillMax) * 0.5
end

-- F1 menu

CreateThread(function()
    while true do
        Wait(0)
        if IsControlJustPressed(0, 288) then -- F1
            openSkillMenu()
        end
    end
end)

function openSkillMenu()
    lib.registerContext({
        id = 'skill_menu',
        title = 'Player Skills',
        options = {
            {
                title = 'Stamina',
                progress = (skills.stamina / Config.SkillMax) * 100,
                icon = 'running'
            },
            {
                title = 'Strength',
                progress = (skills.strength / Config.SkillMax) * 100,
                icon = 'dumbbell'
            },
            {
                title = 'Driving',
                progress = (skills.driving / Config.SkillMax) * 100,
                icon = 'car'
            },
            {
                title = 'Shooting',
                progress = (skills.shooting / Config.SkillMax) * 100,
                icon = 'gun'
            }
        }
    })
    lib.showContext('skill_menu')
end

-- XP: running & driving

CreateThread(function()
    while true do
        Wait(Config.TickInterval)

        local ped = PlayerPedId()

        if IsPedOnFoot(ped) and (IsPedRunning(ped) or IsPedSprinting(ped)) then
            TriggerServerEvent('qb-skills:server:addSkill', 'stamina', Config.Gain.stamina)
        end

        if IsPedInAnyVehicle(ped, false) then
            local veh = GetVehiclePedIsIn(ped, false)
            if GetPedInVehicleSeat(veh, -1) == ped then
                TriggerServerEvent('qb-skills:server:addSkill', 'driving', Config.Gain.driving)
            end
        end
    end
end)

-- XP + effects: shooting

CreateThread(function()
    while true do
        Wait(0)
        local ped = PlayerPedId()

        if IsPedShooting(ped) then
            TriggerServerEvent('qb-skills:server:addSkill', 'shooting', Config.Gain.shooting)

            local pitch = GetGameplayCamRelativePitch()
            SetGameplayCamRelativePitch(pitch * recoilReduction, 0.2)

            local acc = math.floor(60 + (40 * (skills.shooting / Config.SkillMax)))
            SetPedAccuracy(ped, acc)

            Wait(300)
        end
    end
end)

-- stamina → sprint duration

CreateThread(function()
    while true do
        Wait(1000)
        local ped = PlayerPedId()
        if IsPedSprinting(ped) then
            local current = GetPlayerSprintStaminaRemaining(PlayerId())
            local new = current * staminaDrain
            RestorePlayerStamina(PlayerId(), new - current)
        end
    end
end)

-- driving → handling

CreateThread(function()
    while true do
        Wait(1000)
        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped, false) then
            local veh = GetVehiclePedIsIn(ped, false)
            SetVehicleEnginePowerMultiplier(veh, (handlingBoost - 1.0) * 50)
            SetVehicleEngineTorqueMultiplier(veh, handlingBoost)
        end
    end
end)

-- strength → melee damage (players only)

CreateThread(function()
    while true do
        Wait(0)
        local ped = PlayerPedId()

        if IsPedInMeleeCombat(ped) then
            local target = GetMeleeTargetForPed(ped)
            if target and DoesEntityExist(target) and IsPedAPlayer(target) then
                local targetId = NetworkGetPlayerIndexFromPed(target)
                if targetId then
                    TriggerServerEvent('qb-skills:server:applyMeleeDamage', GetPlayerServerId(targetId), strengthMultiplier)
                    Wait(500)
                end
            end
        end
    end
end)

RegisterNetEvent('qb-skills:client:takeMeleeDamage', function(amount)
    ApplyDamageToPed(PlayerPedId(), amount, false)
end)

-- gym targets (ox_target)

CreateThread(function()
    for _, v in ipairs(Config.GymTargets) do
        if v.type == 'membership' then
            exports.ox_target:addBoxZone({
                coords = v.coords,
                size = vec3(1, 1, 1),
                rotation = v.heading,
                options = {
                    {
                        name = 'buy_gym_membership',
                        label = 'Buy Gym Membership ($' .. Config.Gym.price .. ')',
                        icon = 'fa-solid fa-id-card',
                        onSelect = function()
                            TriggerServerEvent('qb-skills:server:buyMembership')
                        end
                    }
                }
            })
        else
            exports.ox_target:addBoxZone({
                coords = v.coords,
                size = vec3(1, 1, 1),
                rotation = v.heading,
                options = {
                    {
                        name = 'gym_' .. v.label,
                        label = v.label,
                        icon = 'fa-solid fa-dumbbell',
                        onSelect = function()
                            startExercise(v.type, v.label)
                        end
                    }
                }
            })
        end
    end
end)

function startExercise(skillType, label)
    QBCore.Functions.TriggerCallback('qb-skills:server:hasMembership', function(hasMembership)
        if not hasMembership then
            lib.notify({
                title = 'Gym',
                description = 'You need a valid gym membership.',
                type = 'error'
            })
            return
        end

        lib.progressCircle({
            duration = 15000,
            label = 'Training ' .. label,
            disable = { move = true, car = true, combat = true }
        })

        TriggerServerEvent('qb-skills:server:addSkill', skillType, Config.Gain[skillType] * 5)
    end)
end
