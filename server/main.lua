
local QBCore = exports['qb-core']:GetCoreObject()

local function initSkills(Player)
    local meta = Player.PlayerData.metadata or {}
    meta.skills = meta.skills or {
        stamina = 0.0,
        strength = 0.0,
        driving = 0.0,
        shooting = 0.0
    }
    Player.Functions.SetMetaData('skills', meta.skills)
end

AddEventHandler('QBCore:Server:PlayerLoaded', function(Player)
    initSkills(Player)
end)

RegisterNetEvent('qb-skills:server:initSkills', function()
    local Player = QBCore.Functions.GetPlayer(source)
    if Player then initSkills(Player) end
end)

local function addSkill(src, skill, amount)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local skills = Player.PlayerData.metadata.skills or {}
    skills[skill] = math.min((skills[skill] or 0) + amount, Config.SkillMax)

    Player.Functions.SetMetaData('skills', skills)
    TriggerClientEvent('qb-skills:client:updateSkills', src, skills)
    TriggerClientEvent('qb-skills:client:skillNotification', src, skill, amount)
end

RegisterNetEvent('qb-skills:server:addSkill', function(skill, amount)
    if Config.Gain[skill] then
        addSkill(source, skill, amount)
    end
end)

QBCore.Functions.CreateCallback('qb-skills:server:getSkills', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    cb(Player and Player.PlayerData.metadata.skills or nil)
end)

-- strength melee damage (players only)
RegisterNetEvent('qb-skills:server:applyMeleeDamage', function(targetId, multiplier)
    local Target = QBCore.Functions.GetPlayer(targetId)
    if not Target then return end

    local dmg = math.floor(25 * multiplier)
    TriggerClientEvent('qb-skills:client:takeMeleeDamage', targetId, dmg)
end)

-- gym membership

QBCore.Functions.CreateCallback('qb-skills:server:hasMembership', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then cb(false) return end

    local meta = Player.PlayerData.metadata
    local expires = meta.gymMembership

    if not expires or os.time() > expires then
        Player.Functions.SetMetaData('gymMembership', nil)
        cb(false)
        return
    end

    cb(true)
end)

RegisterNetEvent('qb-skills:server:buyMembership', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    if Player.Functions.RemoveMoney('bank', Config.Gym.price) then
        local expires = os.time() + Config.Gym.duration
        Player.Functions.SetMetaData('gymMembership', expires)

        TriggerClientEvent('qb-skills:client:notify', src, {
            title = 'Gym Membership',
            description = 'Membership purchased! Expires in 7 days.',
            type = 'success'
        })
    else
        TriggerClientEvent('qb-skills:client:notify', src, {
            title = 'Gym Membership',
            description = 'Not enough money in bank.',
            type = 'error'
        })
    end
end)

-- skill decay loop

CreateThread(function()
    while true do
        Wait(Config.Decay.interval)

        for _, Player in pairs(QBCore.Functions.GetQBPlayers()) do
            local skills = Player.PlayerData.metadata.skills or {}

            for skill, decayAmount in pairs(Config.Decay.amount) do
                if skills[skill] and skills[skill] > 0 then
                    skills[skill] = math.max(skills[skill] - decayAmount, 0)
                end
            end

            Player.Functions.SetMetaData('skills', skills)
            TriggerClientEvent('qb-skills:client:updateSkills', Player.PlayerData.source, skills)
        end
    end
end)
