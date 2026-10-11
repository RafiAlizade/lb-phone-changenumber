local Core = nil
local Framework = 'standalone'

local function _L(key, ...)
    local locale = Config.Locales[Config.Locale] or Config.Locales['en']
    local str = locale[key] or key
    if select('#', ...) > 0 then
        return string.format(str, ...)
    end
    return str
end

local function InitFramework()
    local fw = Config.Framework:lower()

    if (fw == 'auto' or fw == 'qbox') and GetResourceState('qbx_core') == 'started' then
        Framework = 'qbox'
        Core = exports['qbx_core']
    elseif (fw == 'auto' or fw == 'qb' or fw == 'qbcore') and GetResourceState('qb-core') == 'started' then
        Framework = 'qb'
        Core = exports['qb-core']:GetCoreObject()
    elseif (fw == 'auto' or fw == 'esx') and GetResourceState('es_extended') == 'started' then
        Framework = 'esx'
        Core = exports['es_extended']:getSharedObject()
    end
end

CreateThread(function()
    InitFramework()
end)

local function GetPlayer(src)
    if not src or src <= 0 then return nil end

    if Framework == 'qbox' then
        return exports.qbx_core:GetPlayer(src)
    elseif Framework == 'qb' and Core then
        return Core.Functions.GetPlayer(src)
    elseif Framework == 'esx' and Core then
        return Core.GetPlayerFromId(src)
    end

    return nil
end

local function GetIdentifier(src, player)
    player = player or GetPlayer(src)
    if not player then
        return GetPlayerIdentifierByType(src, 'license')
    end

    if Framework == 'qbox' or Framework == 'qb' then
        if player.PlayerData and player.PlayerData.citizenid then
            return player.PlayerData.citizenid
        end
    elseif Framework == 'esx' then
        if player.identifier then
            return player.identifier
        end
    end

    return GetPlayerIdentifierByType(src, 'license')
end

local function GetPlayerNameFormatted(src, player)
    player = player or GetPlayer(src)
    if player then
        if player.PlayerData and player.PlayerData.charinfo then
            local c = player.PlayerData.charinfo
            return (c.firstname or '') .. ' ' .. (c.lastname or '')
        elseif player.getName then
            return player.getName()
        end
    end
    return GetPlayerName(src) or 'Unknown'
end

local function HasPermission(src)
    if src == 0 then return true end

    local perm = Config.Permission or 'god'

    if Config.UseAcePermission then
        if IsPlayerAceAllowed(src, 'group.' .. perm) == 1
            or IsPlayerAceAllowed(src, 'command.' .. Config.Command) == 1
            or IsPlayerAceAllowed(src, 'group.god') == 1 then
            return true
        end
    end

    if Framework == 'qbox' and exports.qbx_core and exports.qbx_core.HasPermission then
        if exports.qbx_core:HasPermission(src, perm) then return true end
    elseif Framework == 'qb' and Core and Core.Functions and Core.Functions.HasPermission then
        if Core.Functions.HasPermission(src, perm) then return true end
    elseif Framework == 'esx' then
        local xPlayer = GetPlayer(src)
        if xPlayer and xPlayer.getGroup then
            local grp = xPlayer.getGroup()
            if grp == perm or grp == 'god' or grp == 'superadmin' or grp == 'admin' then
                return true
            end
        end
    end

    return false
end

local function Notify(src, message, msgType)
    if src == 0 then
        local prefix = (msgType == 'error') and '^1' or ((msgType == 'success') and '^2' or '^3')
        print(prefix .. message .. '^7')
        return
    end

    TriggerClientEvent('cfx-crp-changephonenumber:client:notify', src, message, msgType or 'inform')
end

local function ChangePhoneNumber(targetSrc, newNumber, executorSrc)
    local targetPlayer = GetPlayer(targetSrc)
    if not targetPlayer then
        if executorSrc then Notify(executorSrc, _L('player_offline'), 'error') end
        return false, 'player_offline'
    end

    newNumber = tostring(newNumber):gsub('%s+', '')
    if not newNumber:match('^%d+$') then
        if executorSrc then Notify(executorSrc, _L('invalid_number'), 'error') end
        return false, 'invalid_number'
    end

    local identifier = GetIdentifier(targetSrc, targetPlayer)
    local currentPhone = nil

    if GetResourceState('lb-phone') == 'started' then
        pcall(function()
            local equipped = exports['lb-phone']:GetEquippedPhoneNumber(targetSrc)
            if equipped and equipped ~= '' then
                currentPhone = MySQL.single.await('SELECT id, owner_id, phone_number FROM phone_phones WHERE phone_number = ? LIMIT 1', { equipped })
            end
        end)
    end

    if not currentPhone and identifier then
        currentPhone = MySQL.single.await('SELECT id, owner_id, phone_number FROM phone_phones WHERE owner_id = ? ORDER BY last_seen DESC LIMIT 1', { identifier })
    end

    if not currentPhone and identifier then
        currentPhone = MySQL.single.await('SELECT id, owner_id, phone_number FROM phone_phones WHERE id = ? LIMIT 1', { identifier })
    end

    if not currentPhone then
        if executorSrc then Notify(executorSrc, _L('phone_not_found'), 'error') end
        return false, 'phone_not_found'
    end

    local oldNumber = currentPhone.phone_number

    if oldNumber == newNumber then
        if executorSrc then Notify(executorSrc, _L('same_number', oldNumber), 'error') end
        return false, 'same_number'
    end

    local exists = MySQL.scalar.await('SELECT 1 FROM phone_phones WHERE phone_number = ? LIMIT 1', { newNumber })
    if exists and exists > 0 then
        if executorSrc then Notify(executorSrc, _L('number_taken', newNumber), 'error') end
        return false, 'number_taken'
    end

    local updated = MySQL.update.await('UPDATE phone_phones SET phone_number = ? WHERE id = ?', { newNumber, currentPhone.id })
    if not updated or updated <= 0 then
        MySQL.update.await('UPDATE phone_phones SET phone_number = ? WHERE phone_number = ?', { newNumber, oldNumber })
    end

    pcall(function()
        MySQL.update.await('UPDATE phone_last_phone SET phone_number = ? WHERE phone_number = ?', { newNumber, oldNumber })
    end)

    if Config.SyncFrameworkData then
        if (Framework == 'qbox' or Framework == 'qb') and identifier then
            pcall(function()
                MySQL.update.await("UPDATE players SET charinfo = JSON_SET(charinfo, '$.phone', ?) WHERE citizenid = ?", { newNumber, identifier })
            end)

            if targetPlayer.PlayerData and targetPlayer.PlayerData.charinfo then
                targetPlayer.PlayerData.charinfo.phone = newNumber

                if exports.qbx_core then
                    pcall(function()
                        exports.qbx_core:SetPlayerData(targetSrc, 'charinfo', targetPlayer.PlayerData.charinfo)
                    end)
                elseif targetPlayer.Functions and targetPlayer.Functions.SetPlayerData then
                    targetPlayer.Functions.SetPlayerData('charinfo', targetPlayer.PlayerData.charinfo)
                end

                if targetPlayer.Functions and targetPlayer.Functions.Save then
                    targetPlayer.Functions.Save()
                end
            end
        elseif Framework == 'esx' and identifier then
            pcall(function()
                MySQL.update.await('UPDATE users SET phone_number = ? WHERE identifier = ?', { newNumber, identifier })
            end)
        end
    end

    Player(targetSrc).state:set('phoneNumber', newNumber, true)
    TriggerClientEvent('cfx-crp-changephonenumber:client:reloadPhone', targetSrc, newNumber)

    local targetName = GetPlayerNameFormatted(targetSrc, targetPlayer)
    if executorSrc then
        Notify(executorSrc, _L('admin_success', targetName, targetSrc, newNumber), 'success')
    end
    Notify(targetSrc, _L('target_notify', newNumber), 'inform')

    return true, newNumber
end

local function HandleCommand(source, args)
    if not HasPermission(source) then
        Notify(source, _L('no_permission'), 'error')
        return
    end

    if not args[1] or not args[2] then
        Notify(source, _L('usage', Config.Command), 'error')
        return
    end

    local targetSrc = tonumber(args[1])
    if not targetSrc or targetSrc <= 0 then
        Notify(source, _L('player_offline'), 'error')
        return
    end

    local newNumber = args[2]
    ChangePhoneNumber(targetSrc, newNumber, source)
end

RegisterCommand(Config.Command, HandleCommand, false)

if Config.Aliases and #Config.Aliases > 0 then
    for _, alias in ipairs(Config.Aliases) do
        RegisterCommand(alias, HandleCommand, false)
    end
end

exports('ChangePhoneNumber', function(targetId, newNumber)
    return ChangePhoneNumber(targetId, newNumber, nil)
end)
